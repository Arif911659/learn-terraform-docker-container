variable "ami" {
  type        = string
  description = "AMI for EC2 instances"
}

variable "instance_type" {
  type        = string
  description = "Instance type for k3s nodes"
}

variable "private_subnet_id" {
  type        = string
  description = "Private subnet ID"
}

variable "key_name" {
  type        = string
  description = "Key pair name for EC2 instances"
}

variable "worker_count" {
  type        = number
  default     = 2
  description = "Number of worker nodes"
}
