# variable "filenames" {
#   type    = list(string)
#   default = ["pets.txt", "dogs.txt", "cats.txt"]
# }

# resource "local_file" "example" {
#   count    = length(var.filenames)
#   filename = "./${var.filenames[count.index]}"
#   content  = "This is file number ${count.index + 1}"
# }

variable "files" {
  type = map(string)
  default = {
    "pets.txt" = "This is the pets file"
    "dogs.txt" = "This is the dogs file"
    "cats.txt" = "This is the cats file"
  }
}

resource "local_file" "example" {
  for_each = var.files
  filename = "./${each.key}"
  content  = each.value
}
