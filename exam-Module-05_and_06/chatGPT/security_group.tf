# Security Groups
resource "aws_security_group" "nginx" {
  name        = "nginx-sg"
  description = "Security group for NGINX load balancer and SSH bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # This opens all traffic from any source
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # This allows all outgoing traffic
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # This opens all traffic from any source
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # This allows all outgoing traffic
  }

  tags = {
    Name = "k3s-sg"
  }
}