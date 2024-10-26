provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Name = "k3s-terraform-blueprint"
    }
  }
}