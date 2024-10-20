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