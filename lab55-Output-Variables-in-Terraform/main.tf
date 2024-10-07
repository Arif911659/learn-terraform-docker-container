provider "random" {}

resource "random_pet" "example" {
  length    = 2
  separator = "-"
}

resource "local_file" "example" {
  filename = "/home/arif/Desktop/learn-terraform-docker-container/lab55-Output-Variables-in-Terraform/${random_pet.example.id}.txt"
  content  = "This file is named after a random pet."
}

output "pet_name" {
  value       = random_pet.example.id
  description = "The name of the randomly generated pet"
}

output "file_path" {
  value       = local_file.example.filename
  description = "The path of the created file"
}

# Create an Output Variable for File Content
# Modify the main.tf file to include an output variable for the file content:

output "file_content" {
  value       = local_file.example.content
  description = "The content of the created file"
}