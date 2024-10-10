# main.tf

provider "local" {
  # No additional configuration needed
}

resource "local_file" "example_file" {
  filename = "example.txt"
#   content  = "This is an example file for Terraform lifecycle management."
    content  = "This is the updated content for the example file."
#   content = file("${path.module}/example.txt")

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
    ignore_changes        = [
      content
    ]
  }
}
