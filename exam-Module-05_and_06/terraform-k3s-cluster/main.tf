provider "aws" {
  region = var.region
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

# Public Subnet for Nginx Load Balancer
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = "ap-southeast-1a"
  map_public_ip_on_launch = true
}

# Private Subnet for k3s cluster (Master and Worker)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "ap-southeast-1a"
}

# Internet Gateway for Public Subnet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Elastic IP for NAT Gateway (to enable internet access in private subnet)
resource "aws_eip" "nat" {
    domain = "vpc"
}

# NAT Gateway in Public Subnet for Private Subnet Internet Access
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
}

# Route Table for Private Subnet to use NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

# Associate Private Subnet with the Private Route Table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Security Group for k3s cluster (Master and Worker)
resource "aws_security_group" "k3s_cluster" {
  vpc_id = aws_vpc.main.id

  # Ingress: Allow all traffic from within the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # -1 means all protocols
    cidr_blocks = [aws_vpc.main.cidr_block]
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
}

# Security Group for Nginx Load Balancer
resource "aws_security_group" "nginx" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
}

# Generate key pair and save it locally as my-keypair.pem
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "my_key" {
  content  = tls_private_key.my_key.private_key_pem
  filename = "${path.module}/my-keypair.pem"  # Key pair will be saved in the current directory
}

resource "aws_key_pair" "my_keypair" {
  key_name   = var.key_name
  public_key = tls_private_key.my_key.public_key_openssh
}

# EC2 instance for k3s Master Node in Private Subnet
resource "aws_instance" "master" {
  ami           = "ami-047126e50991d067b"  # Ubuntu 22.04 LTS
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private.id
  key_name      = aws_key_pair.my_keypair.key_name
  #security_groups = [aws_security_group.k3s_cluster.name]
  vpc_security_group_ids      = [aws_security_group.k3s_cluster.id]   # Replace group_name with vpc_security_group_ids

  user_data = <<-EOF
              #!/bin/bash
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

# EC2 instance for k3s Worker Node in Private Subnet
resource "aws_instance" "worker" {
  ami           = "ami-047126e50991d067b"  # Ubuntu 22.04 LTS
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private.id
  key_name      = aws_key_pair.my_keypair.key_name
  #security_groups = [aws_security_group.k3s_cluster.name]
  vpc_security_group_ids      = [aws_security_group.k3s_cluster.id]   # Replace group_name with vpc_security_group_ids

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
  ami           = "ami-047126e50991d067b"  # Ubuntu 22.04 LTS
  instance_type = var.instance_type
#   subnet_id     = aws_subnet.public.id
#   key_name      = aws_key_pair.my_keypair.key_name
#   security_groups = [aws_security_group.nginx.name]
  subnet_id                   = aws_subnet.public.id      # Nginx in public subnet
  key_name                    = aws_key_pair.my_keypair.key_name
  vpc_security_group_ids      = [aws_security_group.nginx.id]  # Use vpc_security_group_ids


  user_data = <<-EOF
              #!/bin/bash
              apt update
              apt install -y nginx
              cat <<EOL > /etc/nginx/conf.d/default.conf
              upstream k3s_cluster {
                  server ${aws_instance.master.private_ip}:80;
                  server ${aws_instance.worker.private_ip}:80;
              }

              server {
                  listen 80;
                  location / {
                      proxy_pass http://k3s_cluster;
                  }
              }
              EOL
              systemctl restart nginx
              EOF

        tags = {
          name = "nginx-lb"
        }
    depends_on = [ aws_instance.master, aws_instance.worker ]
}
