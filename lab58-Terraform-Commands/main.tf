# provider "local" {
  
# }

# provider "random" {
      
# }

# resource "random_password" "my_password" {
#     length = 16

#     special = true
#     override_special = "!#$%&*()-_=+[]{}<>:?"

# }
# resource "local_file" "my_file" {
#     content = "Random Password is: ${random_password.my_password.result}"
#     filename = "/home/k8s-master/learn-terraform-docker-container/lab58-Terraform-Commands/my_file.txt"
# }
########################################
#To generate a new password every time and append it to the existing .txt file, you can modify the configuration by using a local-exec provisioner within the random_password resource. This approach will allow you to append the newly generated password to the file without overwriting the existing content.
# Here's the updated configuration:

provider "local" {
}

provider "random" {
}

resource "random_password" "my_password" {
  length           = 25
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "null_resource" "append_password" {
  triggers = {
    password = random_password.my_password.result
  }

  provisioner "local-exec" {
    command = "echo 'Random Password is: ${random_password.my_password.result}' >> /home/k8s-master/learn-terraform-docker-container/lab58-Terraform-Commands/my_file.txt"
  }
}


/* Key Changes:
Use of null_resource with local-exec:
A null_resource is used to trigger the local-exec provisioner.
The triggers argument ensures that the command is executed every time the password changes.
Appending the Password:
The local-exec provisioner appends the new password to the existing file using the >> operator instead of overwriting the file.

Explanation:
random_password.my_password.result generates a new password.
The null_resource.append_password will run a local command to append the generated password to the specified file. */