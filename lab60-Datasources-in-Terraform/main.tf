# resource "local_file" "pet" {
#   filename = "petstore.txt"
#   content  = data.local_file.dog.content
# }

# data "local_file" "dog" {
#   filename = "dogs.txt"
# }

provider "local" {}

data "local_file" "json_file" {
  filename = "${path.module}/data.json"
}

locals {
  json_content = jsondecode(data.local_file.json_file.content)
}

resource "local_file" "output_file" {
  content  = local.json_content["message"]
  filename = "${path.module}/output.txt"
}
