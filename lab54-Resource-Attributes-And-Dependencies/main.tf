# main.tf
provider "local" {
  # Optional configuration for the local provider
}

provider "random" {
  # Optional configuration for the random provider
}

resource "random_pet" "my_pet" {
  length    = 2
  separator = "-"
}

# resource "local_file" "example" {
#   filename = "/home/arif/Desktop/learn-terraform-docker-container/lab54-Resource-Attributes-And-Dependencies/example.txt"
#   content  = "My favorite pet is ${random_pet.my_pet.id}."
# }

resource "local_file" "example" {
  filename = "/home/arif/Desktop/learn-terraform-docker-container/lab54-Resource-Attributes-And-Dependencies/pet_name.txt"
  content  = "My favorite pet is ${random_pet.my_pet.id}."
  depends_on = [random_pet.my_pet]
}