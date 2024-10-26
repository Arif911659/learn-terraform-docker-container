# Generate a new key pair
resource "tls_private_key" "k3s_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create a key pair in AWS
resource "aws_key_pair" "my-keypair" {
  key_name   = "my-keypair"
  public_key = tls_private_key.k3s_key.public_key_openssh
}

# Store the private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.k3s_key.private_key_pem
  filename        = "${path.module}/my-keypair.pem"
  file_permission = "0400"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "k3s-vpc"
  }
}

# Public Subnet for Nginx Load Balancer
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "k3s-public-subnet"
  }
}

# Private Subnet for k3s cluster (Master and Worker)
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr

  tags = {
    Name = "k3s-private-subnet"
  }
}

# Internet Gateway for Public Subnet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "k3s-igw"
  }
}

# Route Table for Public Subnet
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

# Route Table for Private Subnet to use NAT Gateway
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

# Associate Private Subnet with the Private Route Table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Elastic IP for NAT Gateway (to enable internet access in private subnet)
resource "aws_eip" "nat" {
  domain = "vpc"
}

# NAT Gateway in Public Subnet for Private Subnet Internet Access
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "k3s-nat-gw"
  }
}

# Security Group for k3s cluster (Master and Worker)
resource "aws_security_group" "k3s_cluster" {
  name        = "k3s-cluster-sg"
  description = "Security group for k3s cluster"
  vpc_id      = aws_vpc.main.id

  # Allow NodePort services from NGINX
  ingress {
    from_port       = 30001
    to_port         = 30002
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx.id]
    description     = "Allow NodePort access from NGINX"
  }

  # Ingress: Allow all traffic from within the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # -1 means all protocols
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Allow all internal VPC traffic"
  }

  # Allow k3s API server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Allow k3s API server"
  }

  # Egress: Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "k3s-cluster-sg"
  }
}

# Security Group for Nginx Load Balancer
resource "aws_security_group" "nginx" {
  name        = "nginx-sg"
  description = "Security group for NGINX load balancer and SSH"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP"
  }

  # Allow HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS"
  }

  # Allow k3s API server access
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Allow k3s API server access"
  }  

  # Allow SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH"
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "nginx-sg"
  }
}
# Generate random token for k3s nodes to join the cluster
resource "random_password" "k3s_token" {
  length  = 16
  special = false
}