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

