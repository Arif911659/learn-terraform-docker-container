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

resource "local_file" "example" {
  filename = "/home/k8s-master/learn-terraform-docker-container/lab57-Managing-Terraform-State/example.txt"
  content  = "My favorite pet is ${random_pet.my_pet.id}."
}

