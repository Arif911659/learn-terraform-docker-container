#Add a variables.tf file for common variables, including key_name for the EC2 key pair.

variable "aws_region" {
  type        = string
  description = "AWS region"
}
variable "access_key" {
  type        = string
  description = "AWS access key"  
}
variable "key_name" {
  type        = string
  description = "Key pair for SSH access to EC2 instances"
}
