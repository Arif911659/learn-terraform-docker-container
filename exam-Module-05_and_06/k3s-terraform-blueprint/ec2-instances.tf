# EC2 instance for k3s Master Node in Private Subnet
resource "aws_instance" "k3s_master" {
  ami           = var.ubuntu_ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private.id
  key_name      = aws_key_pair.my-keypair.key_name
  vpc_security_group_ids = [aws_security_group.k3s_cluster.id]

  user_data = <<-EOF
              #!/bin/bash
              # Set timeout for installation (30 minutes)
              TIMEOUT=1800
              START_TIME=$(date +%s)

              apt-get update
              sudo hostnamectl hostname master
              apt-get install -y curl

              # Install k3s with timeout
              curl -sfL https://get.k3s.io | sh -s - server --token=${random_password.k3s_token.result}
              
              # Wait for k3s to start with timeout
              while ! systemctl is-active --quiet k3s; do
                CURRENT_TIME=$(date +%s)
                if [ $((CURRENT_TIME - START_TIME)) -gt $TIMEOUT ]; then
                  echo "Timeout waiting for k3s to start"
                  exit 1
                fi
                sleep 60
                echo "Waiting for k3s to start..."
              done

              sudo chmod 644 /etc/rancher/k3s/k3s.yaml
              echo "k3s master node is ready"
              EOF

  tags = {
    Name = "k3s-master"
  }
}

# EC2 instance for k3s Worker Nodes in Private Subnet
resource "aws_instance" "k3s_worker" {
  count         = 2
  ami           = var.ubuntu_ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private.id
  key_name      = aws_key_pair.my-keypair.key_name
  vpc_security_group_ids = [aws_security_group.k3s_cluster.id]

  user_data = <<-EOF
              #!/bin/bash
              # Set timeout for installation (30 minutes)
              TIMEOUT=1800
              START_TIME=$(date +%s)

              hostnamectl set-hostname worker-${count.index + 1}
              echo "127.0.0.1 worker-${count.index + 1}" >> /etc/hosts

              apt-get update
              apt-get install -y curl

              # Install k3s agent with error handling
              if ! curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.k3s_master.private_ip}:6443 K3S_TOKEN=${random_password.k3s_token.result} sh -; then
                echo "Failed to install k3s agent"
                exit 1
              fi

              # Wait for k3s agent to start
              while ! systemctl is-active --quiet k3s-agent; do
                CURRENT_TIME=$(date +%s)
                if [ $((CURRENT_TIME - START_TIME)) -gt $TIMEOUT ]; then
                  echo "Timeout waiting for k3s-agent to start"
                  exit 1
                fi
                sleep 30
                echo "Waiting for k3s-agent to start..."
              done

              echo "k3s worker node ${count.index + 1} is ready"
              EOF

  tags = {
    Name = "k3s-worker-${count.index + 1}"
  }

  depends_on = [aws_instance.k3s_master]
}

# Nginx Load Balancer in Public Subnet
resource "aws_instance" "nginx" {
  ami           = var.ubuntu_ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  key_name      = aws_key_pair.my-keypair.key_name
  vpc_security_group_ids = [aws_security_group.nginx.id]

  user_data = <<-EOF
              #!/bin/bash
              # Set timeout for installation (30 minutes)
              TIMEOUT=1800
              START_TIME=$(date +%s)

              hostnamectl set-hostname nginx-lb
              apt update -y
              apt install -y nginx

              cat > /etc/nginx/nginx.conf <<'CONFIG'
              events {
                worker_connections 1024;
              }

              http {
                  upstream react_app {
                      least_conn;  # Load balancing method
                      server ${aws_instance.k3s_master.private_ip}:30002 max_fails=3 fail_timeout=30s;
                      server ${aws_instance.k3s_worker[0].private_ip}:30002 max_fails=3 fail_timeout=30s;
                      server ${aws_instance.k3s_worker[1].private_ip}:30002 max_fails=3 fail_timeout=30s;
                  }

                  upstream flask_api {
                      least_conn;  # Load balancing method
                      server ${aws_instance.k3s_master.private_ip}:30001 max_fails=3 fail_timeout=30s;
                      server ${aws_instance.k3s_worker[0].private_ip}:30001 max_fails=3 fail_timeout=30s;
                      server ${aws_instance.k3s_worker[1].private_ip}:30001 max_fails=3 fail_timeout=30s;
                  }

                  server {
                      listen 80;
                      server_name _;

                      # Health check endpoint
                      location /health {
                          return 200 'healthy\n';
                      }

                      location / {
                          proxy_pass http://react_app;
                          proxy_http_version 1.1;
                          proxy_set_header Host $host;
                          proxy_set_header X-Real-IP $remote_addr;
                          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                          proxy_set_header X-Forwarded-Proto $scheme;
                          
                          # Timeouts
                          proxy_connect_timeout 60s;
                          proxy_send_timeout 60s;
                          proxy_read_timeout 60s;

                          # Error handling
                          proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
                      }

                      location /api/ {
                          proxy_pass http://flask_api;
                          proxy_http_version 1.1;
                          proxy_set_header Host $host;
                          proxy_set_header X-Real-IP $remote_addr;
                          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                          proxy_set_header X-Forwarded-Proto $scheme;
                          
                          # Timeouts
                          proxy_connect_timeout 60s;
                          proxy_send_timeout 60s;
                          proxy_read_timeout 60s;

                          # Error handling
                          proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
                      }
                  }
              }
              #CONFIG
              sudo chown -R www-data:www-data /run/nginx.pid
              sudo chown -R www-data:www-data /etc/nginx
              sudo systemctl restart nginx
              sudo pkill nginx
              sudo systemctl start nginx
              sudo systemctl restart nginx
              
              sudo nginx -t
              echo "k3s master node deployments applied successfully"
              EOF

  tags = {
    Name = "nginx-lb"
  }

  depends_on = [aws_instance.k3s_master, aws_instance.k3s_worker]
}

# # Nginx Load Balancer in Public Subnet
# resource "aws_instance" "nginx" {
#   ami           = var.ubuntu_ami
#   instance_type = var.instance_type
#   subnet_id     = aws_subnet.public.id
#   key_name      = aws_key_pair.my-keypair.key_name
#   vpc_security_group_ids = [aws_security_group.nginx.id]

#   user_data = <<-EOF
#               #!/bin/bash
#               # Set timeout for installation (30 minutes)
#               TIMEOUT=1800
#               START_TIME=$(date +%s)

#               hostnamectl set-hostname nginx-lb
#               apt update -y
#               apt install -y nginx

#               cat > /etc/nginx/nginx.conf <<'CONFIG'
#               events {
#                 worker_connections 1024;
#               }

#               http {
#                   upstream react_app {
#                       least_conn;  # Load balancing method
#                       server ${aws_instance.k3s_master.private_ip}:30002 max_fails=3 fail_timeout=30s;
#                       server ${aws_instance.k3s_worker[0].private_ip}:30002 max_fails=3 fail_timeout=30s;
#                       server ${aws_instance.k3s_worker[1].private_ip}:30002 max_fails=3 fail_timeout=30s;
#                   }

#                   upstream flask_api {
#                       least_conn;  # Load balancing method
#                       server ${aws_instance.k3s_master.private_ip}:30001 max_fails=3 fail_timeout=30s;
#                       server ${aws_instance.k3s_worker[0].private_ip}:30001 max_fails=3 fail_timeout=30s;
#                       server ${aws_instance.k3s_worker[1].private_ip}:30001 max_fails=3 fail_timeout=30s;
#                   }

#                   server {
#                       listen 80;
#                       server_name _;

#                       # Health check endpoint
#                       location /health {
#                           return 200 'healthy\n';
#                       }

#                       location / {
#                           proxy_pass http://react_app;
#                           proxy_http_version 1.1;
#                           proxy_set_header Host $host;
#                           proxy_set_header X-Real-IP $remote_addr;
#                           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#                           proxy_set_header X-Forwarded-Proto $scheme;
                          
#                           # Timeouts
#                           proxy_connect_timeout 60s;
#                           proxy_send_timeout 60s;
#                           proxy_read_timeout 60s;

#                           # Error handling
#                           proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
#                       }

#                       location /api/ {
#                           proxy_pass http://flask_api;
#                           proxy_http_version 1.1;
#                           proxy_set_header Host $host;
#                           proxy_set_header X-Real-IP $remote_addr;
#                           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#                           proxy_set_header X-Forwarded-Proto $scheme;
                          
#                           # Timeouts
#                           proxy_connect_timeout 60s;
#                           proxy_send_timeout 60s;
#                           proxy_read_timeout 60s;

#                           # Error handling
#                           proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
#                       }
#                   }
#               }
#               #CONFIG
#               sudo chown -R www-data:www-data /run/nginx.pid
#               sudo chown -R www-data:www-data /etc/nginx
#               sudo systemctl restart nginx
#               sudo pkill nginx
#               sudo systemctl start nginx
#               sudo systemctl restart nginx
              
#               sudo nginx -t
              

#               # Install additional required packages
#               apt install -y openssh-client netcat-openbsd

#               # Wait for k3s master with timeout
#               while ! nc -z ${aws_instance.k3s_master.private_ip} 6443; do
#                 CURRENT_TIME=$(date +%s)
#                 if [ $((CURRENT_TIME - START_TIME)) -gt $TIMEOUT ]; then
#                   echo "Timeout waiting for k3s master"
#                   exit 1
#                 fi
#                 echo "Waiting for k3s master to be ready..."
#                 sleep 5
#               done

#               # Create deployment directory with error handling
#               mkdir -p /tmp/deployments || {
#                 echo "Failed to create deployments directory"
#                 exit 1
#               }

#               # Write deployment files
#               cat > /tmp/deployments/deployment-1-Flask.yaml <<EOT
#               ${file("${path.module}/deployment-1-Flask.yaml")}
#               EOT

#               cat > /tmp/deployments/deployment-2-React.yaml <<EOT
#               ${file("${path.module}/deployment-2-React.yaml")}
#               EOT

#               # Copy and apply deployments with error handling
#               if ! scp -o StrictHostKeyChecking=no -i ${path.module}/my-keypair.pem /tmp/deployments/*.yaml ubuntu@${aws_instance.k3s_master.private_ip}:/home/ubuntu/; then
#                 echo "Failed to copy deployment files"
#                 exit 1
#               fi

#               if ! ssh -o StrictHostKeyChecking=no -i ${path.module}/my-keypair.pem ubuntu@${aws_instance.k3s_master.private_ip} \
#                 "sudo kubectl apply -f /home/ubuntu/deployment-1-Flask.yaml && \
#                  sudo kubectl apply -f /home/ubuntu/deployment-2-React.yaml"; then
#                 echo "Failed to apply deployments"
#                 exit 1
#               fi

#               echo "k3s master node deployments applied successfully"
#               EOF

#   tags = {
#     Name = "nginx-lb"
#   }

#   depends_on = [aws_instance.k3s_master, aws_instance.k3s_worker]
# }