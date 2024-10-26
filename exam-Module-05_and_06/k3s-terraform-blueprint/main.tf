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

# Generate random token for k3s nodes to join the cluster
resource "random_password" "k3s_token" {
  length  = 16
  special = false
}