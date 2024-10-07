# Edit dynamic_file.tf to include a resource and output variable for a file with the current date and time:

provider "local" {}

resource "local_file" "dynamic" {
  filename = "/home/arif/Desktop/learn-terraform-docker-container/lab55-Output-Variables-in-Terraform/dynamic_file.txt"
  content  = "File created at: ${timestamp()}"
}

output "file_creation_time" {
  value       = local_file.dynamic.content
  description = "The creation time of the dynamic file"
}