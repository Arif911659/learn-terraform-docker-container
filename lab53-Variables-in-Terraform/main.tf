# main.tf
resource "local_file" "example" {
  filename = var.filename
  content  = "This is an example file."
}
