# ====================================================
# allow SSH access to all nodes through the NGINX instance.
# ====================================================

# Provider configuration
provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  default = "ap-southeast-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}

# Ubuntu 22.04 LTS AMI (adjust the AMI ID for your region)
variable "ubuntu_ami" {
  default = "ami-047126e50991d067b"  # Ubuntu 22.04 LTS
}

# Generate a new key pair
resource "tls_private_key" "k3s_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create a key pair in AWS
resource "aws_key_pair" "k3s_key_pair" {
  key_name   = "k3s-key-pair"
  public_key = tls_private_key.k3s_key.public_key_openssh
}

# Store the private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.k3s_key.private_key_pem
  filename        = "${path.module}/k3s-key-pair.pem"
  file_permission = "0600"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "k3s-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "k3s-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "k3s-public-subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr

  tags = {
    Name = "k3s-private-subnet"
  }
}

# NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "k3s-nat-gw"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "k3s-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "k3s-private-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
####
# Security Groups
resource "aws_security_group" "nginx" {
  name        = "nginx-sg"
  description = "Security group for NGINX load balancer and SSH bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nginx-sg"
  }
}

resource "aws_security_group" "k3s" {
  name        = "k3s-sg"
  description = "Security group for k3s cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx.id]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k3s-sg"
  }
}
####
# # EC2 Instance for k3s master
# resource "aws_instance" "k3s_master" {
#   ami           = var.ubuntu_ami
#   instance_type = "t3.small"
#   subnet_id     = aws_subnet.private.id
#   vpc_security_group_ids = [aws_security_group.k3s.id]
#   key_name      = aws_key_pair.k3s_key_pair.key_name

#   user_data = <<-EOF
#               #!/bin/bash
#               apt-get update
#               apt-get install -y curl
#               curl -sfL https://get.k3s.io | sh -s - server --token=${random_password.k3s_token.result}
#               while ! systemctl is-active --quiet k3s; do
#                 sleep 60
#                 echo "Waiting for k3s to start..."
#               done
#               echo "k3s master node is ready"
#               EOF

#   tags = {
#     Name = "k3s-master"
#   }
# }
# EC2 Instance for k3s master (in private subnet)
resource "aws_instance" "k3s_master" {
  ami           = var.ubuntu_ami
  instance_type = "t3.small"
  subnet_id     = aws_subnet.private.id  # Keep in private subnet
  vpc_security_group_ids = [aws_security_group.k3s.id]
  key_name      = aws_key_pair.k3s_key_pair.key_name

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y curl
              curl -sfL https://get.k3s.io | sh -s - server --token=${random_password.k3s_token.result}
              while ! systemctl is-active --quiet k3s; do
                sleep 60
                echo "Waiting for k3s to start..."
              done
              echo "k3s master node is ready"
              EOF

  tags = {
    Name = "k3s-master"
  }
}
####
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
####

# EC2 Instance for NGINX Load Balancer
resource "aws_instance" "nginx_lb" {
  ami           = var.ubuntu_ami
  instance_type = "t3.small"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.nginx.id]
  associate_public_ip_address = true
  key_name      = aws_key_pair.k3s_key_pair.key_name

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              
              # Create NGINX configuration for load balancing
              cat > /etc/nginx/sites-available/k3s-lb <<EOL
              upstream k3s-cluster {
                server ${aws_instance.k3s_master.private_ip}:80;
                ${join("\n    ", formatlist("server %s:80;", aws_instance.k3s_workers[*].private_ip))}
              }

              server {
                listen 80;
                server_name _;

                location / {
                  proxy_pass http://k3s-cluster;
                  proxy_set_header Host \$host;
                  proxy_set_header X-Real-IP \$remote_addr;
                  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                }
              }
              EOL

              ln -s /etc/nginx/sites-available/k3s-lb /etc/nginx/sites-enabled/
              rm /etc/nginx/sites-enabled/default
              systemctl reload nginx
              EOF

  tags = {
    Name = "nginx-lb"
  }

  depends_on = [aws_instance.k3s_master, aws_instance.k3s_workers]
}

# Generate a random token for k3s
resource "random_password" "k3s_token" {
  length  = 32
  special = false
}

# Outputs
output "nginx_public_ip" {
  value = aws_instance.nginx.public_ip
}

output "k3s_master_private_ip" {
  value = aws_instance.k3s_master.private_ip
}

output "k3s_worker_private_ips" {
  value = aws_instance.k3s_workers[*].private_ip
}

output "k3s_token" {
  value     = random_password.k3s_token.result
  sensitive = true
}

output "ssh_command" {
  value = "ssh -i ${path.module}/k3s-key-pair.pem -J ubuntu@${aws_instance.nginx.public_ip} ubuntu@<PRIVATE_IP>"
  description = "Command to SSH into private instances. Replace <PRIVATE_IP> with the desired instance's private IP."
}

output "key_pair_file" {
  value = local_file.private_key.filename
  description = "Path to the generated private key file"
}