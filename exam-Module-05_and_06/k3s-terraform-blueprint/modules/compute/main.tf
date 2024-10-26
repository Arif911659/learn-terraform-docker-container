#The compute module will create EC2 instances for the k3s master and worker nodes in the private subnet.

resource "aws_instance" "k3s_master" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.private_subnet_id
  key_name      = var.key_name

  tags = {
    Name = "k3s-master"
  }
}

resource "aws_instance" "k3s_worker" {
  count         = var.worker_count
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.private_subnet_id
  key_name      = var.key_name

  tags = {
    Name = "k3s-worker-${count.index + 1}"
  }
}

# Generate key pair and save it locally as my-keypair.pem
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "my_keypair" {
  key_name   = var.key_name
  public_key = tls_private_key.my_key.public_key_openssh
}

resource "local_file" "my_key" {
  content  = tls_private_key.my_key.private_key_pem
  filename = "${path.module}/my-keypair.pem"  # Key pair will be saved in the current directory
}

