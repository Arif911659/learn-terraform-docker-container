variable "filename" {
    description = "The name of the file that will be created"
    type = string
    default = "/home/k8s-master/learn-terraform-docker-container/lab56-Understanding-Terraform-States/pet.txt"
      
}

variable "content" {
    description = "The content of the file that will be created"
    type = string
    default = "I love Pets!"  
}