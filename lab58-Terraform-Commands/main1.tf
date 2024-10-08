# provider "local" {
# }

# provider "random" {
# }

resource "random_string" "my_string" {
  length           = 25
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "null_resource" "append_string" {
  triggers = {
    string = random_string.my_string.result
  }

  provisioner "local-exec" {
    command = "echo 'Random String is: ${random_string.my_string.result}' >> /home/k8s-master/learn-terraform-docker-container/lab58-Terraform-Commands/my_random_string.txt"
  }
}
