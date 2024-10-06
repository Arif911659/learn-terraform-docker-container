provider "random" {}

resource "random_pet" "example" {
  length    = var.pet_name_length
  separator = "-"
}

resource "local_file" "example" {
  filename = "//home/arif/Desktop/learn-terraform-docker-container/lab52-Input-Variables-and-Variable-Blocks/${var.file_name}"
  content  = var.file_content_map["statement2"]
}