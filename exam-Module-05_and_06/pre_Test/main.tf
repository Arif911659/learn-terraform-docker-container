provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "nginx_lb_sg" {
  name        = "nginx_lb_sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "k3s_cluster_sg" {
  name        = "k3s_cluster_sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
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

resource "aws_instance" "k3s_master" {
  ami           = "ami-047126e50991d067b" # Replace with Ubuntu AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private.id
  security_groups = [aws_security_group.k3s_cluster_sg.id]

  tags = {
    Name = "k3s-master"
  }

  user_data = <<-EOF
    #!/bin/bash
    curl -sfL https://get.k3s.io | sh -s - server --node-ip=10.0.2.10
  EOF
}

resource "aws_instance" "k3s_worker" {
  count         = 2
  ami           = "ami-047126e50991d067b" # Replace with Ubuntu AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private.id
  security_groups = [aws_security_group.k3s_cluster_sg.id]

  tags = {
    Name = "k3s-worker-${count.index + 1}"
  }

  user_data = <<-EOF
    #!/bin/bash
    curl -sfL https://get.k3s.io | K3S_URL=https://10.0.2.10:6443 K3S_TOKEN=<your_token> sh -
  EOF
}

resource "aws_instance" "nginx_lb" {
  ami           = "ami-047126e50991d067b" # Replace with Ubuntu AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  security_groups = [aws_security_group.nginx_lb_sg.id]

  tags = {
    Name = "nginx-lb"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y nginx
    sudo tee /etc/nginx/conf.d/default.conf <<EOL
    upstream k3s_cluster {
      server 10.0.2.10:80;
      server 10.0.2.11:80;
      server 10.0.2.12:80;
    }
    server {
      listen 80;
      location / {
        proxy_pass http://k3s_cluster;
      }
    }
    EOL
    sudo systemctl restart nginx
  EOF
}

