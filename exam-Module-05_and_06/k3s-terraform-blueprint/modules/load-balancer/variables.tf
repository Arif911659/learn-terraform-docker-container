variable "ami" {
  type        = string
  description = "AMI for Nginx load balancer"
}

variable "instance_type" {
  type        = string
  description = "Instance type for Nginx load balancer"
}

variable "public_subnet_id" {
  type        = string
  description = "Public subnet ID"
}

variable "key_name" {
  type        = string
  description = "Key pair name for EC2 instances"
}
