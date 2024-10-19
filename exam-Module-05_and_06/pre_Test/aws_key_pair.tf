# Generate a key pair
resource "tls_private_key" "deployer_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair using the public key generated above
resource "aws_key_pair" "deployer_key" {
  key_name   = "aws_key_pair"
  public_key = tls_private_key.deployer_key.public_key_openssh
}

# Save the private key locally as deployer-key.pem
resource "local_file" "private_key" {
  content  = tls_private_key.deployer_key.private_key_pem
  filename = "${path.module}/aws_key_pair.pem"
}
