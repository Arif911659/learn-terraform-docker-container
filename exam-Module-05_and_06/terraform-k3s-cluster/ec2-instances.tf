
# EC2 instance for k3s Master Node in Private Subnet
resource "aws_instance" "master" {
  ami           = var.ubuntu_ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private.id
  key_name      = aws_key_pair.k3s_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.k3s_cluster.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y curl
              curl -sfL https://get.k3s.io | sh -s - server --token=${random_password.k3s_token.result}
              
              while ! systemctl is-active --quiet k3s; do
                sleep 60
                echo "Waiting for k3s to start..."
              done
              EOF

  tags = {
    Name = "k3s-master"
  }
}

# EC2 instance for k3s Worker Node in Private Subnet
resource "aws_instance" "k3s_workers" {
  count         = 2
  ami           = var.ubuntu_ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private.id
  key_name      = aws_key_pair.k3s_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.k3s_cluster.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y curl
              curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.master.private_ip}:6443 K3S_TOKEN=${random_password.k3s_token.result} sh -
              EOF

  tags = {
    Name = "k3s-worker-${count.index + 1}"
  }

  depends_on = [aws_instance.master]
}
# Nginx Load Balancer in Public Subnet
resource "aws_instance" "nginx" {
  ami           = var.ubuntu_ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  key_name      = aws_key_pair.k3s_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.nginx.id]

  user_data = <<-EOF
              #!/bin/bash
              apt update
              apt install -y nginx

              # Create NGINX configuration for load balancing
              cat > /etc/nginx/nginx.conf <<EOL
              events {}

              http {
                  upstream react_app {
                      server ${aws_instance.master.private_ip}:30002;
                      ${join("\n    ", formatlist("server %s:30002;", aws_instance.k3s_workers[*].private_ip))}
                  }

                  upstream flask_api {
                      server ${aws_instance.master.private_ip}:30001;
                      ${join("\n    ", formatlist("server %s:30001;", aws_instance.k3s_workers[*].private_ip))}
                  }

                  server {
                      listen 80;

                      location /app/ {
                          proxy_pass http://react_app;
                          proxy_set_header Host \$host;
                          proxy_set_header X-Real-IP \$remote_addr;
                          proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                          proxy_set_header X-Forwarded-Proto \$scheme;
                      }

                      location /api/ {
                          proxy_pass http://flask_api;
                          proxy_set_header Host \$host;
                          proxy_set_header X-Real-IP \$remote_addr;
                          proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                          proxy_set_header X-Forwarded-Proto \$scheme;
                      }
                  }
              }
              EOL

              systemctl restart nginx
              EOF

  tags = {
    name = "nginx-lb"
  }

  depends_on = [aws_instance.master, aws_instance.k3s_workers]
}
