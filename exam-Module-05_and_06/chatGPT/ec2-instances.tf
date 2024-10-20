resource "aws_instance" "nginx_lb" {
  ami           = var.ubuntu_ami
  instance_type = "t3.small"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.nginx.id]
  associate_public_ip_address = true
  key_name      = aws_key_pair.k3s_key_pair.key_name

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
  EOF

  tags = {
    Name = "nginx-load-balancer"
  }
    depends_on = [aws_instance.k3s_master, aws_instance.k3s_workers]
}

# EC2 Instance for k3s master (in private subnet)
resource "aws_instance" "k3s_master" {
  ami           = var.ubuntu_ami
  instance_type = "t3.small"
  subnet_id     = aws_subnet.private.id  # Keep in private subnet
  vpc_security_group_ids = [aws_security_group.k3s.id]
  key_name      = aws_key_pair.k3s_key_pair.key_name

  user_data = <<-EOF
              #!/bin/bash
              
              # Install k3s
              curl -sfL https://get.k3s.io | sh -s - server --token=${random_password.k3s_token.result}
              
              # Wait for k3s to start
              while ! systemctl is-active --quiet k3s; do
                sleep 60
                echo "Waiting for k3s to start..."
              done
                EOF
  tags = {
    Name = "k3s-master"
  }
}

# EC2 Instances for k3s workers
resource "aws_instance" "k3s_workers" {
  count         = 2
  ami           = var.ubuntu_ami
  instance_type = "t3.small"
  subnet_id     = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.k3s.id]
  key_name      = aws_key_pair.k3s_key_pair.key_name

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y curl
              curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.k3s_master.private_ip}:6443 K3S_TOKEN=${random_password.k3s_token.result} sh -
              EOF

  tags = {
    Name = "k3s-worker-${count.index + 1}"
  }

  depends_on = [aws_instance.k3s_master]
}
