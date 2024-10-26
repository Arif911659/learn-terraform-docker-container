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
    #cidr_blocks = [ aws_instance.nginx.private_ip ]
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