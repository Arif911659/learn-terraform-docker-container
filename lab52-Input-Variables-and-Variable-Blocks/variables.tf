# # The name of the file to create.
# variable "file_name" {
#   type        = string
#   default     = "example.txt"
# }

# # The content of the file to create.
# variable "file_content" {
#   type        = string
#   default     = "Hello, Terraform!"
# }

# # The prefix for the random pet name.
# variable "pet_name_prefix" {
#   type        = string
#   default     = "pet"
# }

# # The length of the random pet name.
# variable "pet_name_length" {
#   type        = number
#   default     = 2
# }

# Task 1: Update Variable Values
#     Update the variables.tf file to include new default values:

variable "file_name" {
  description = "The name of the file to create"
  type        = string
  default     = "updated_example.txt"
}

variable "file_content" {
  description = "The content of the file to create"
  type        = string
  default     = "My favorite pet is Mrs. Whiskers"
}

variable "pet_name_prefix" {
  description = "The prefix for the random pet name"
  type        = string
  default     = "pet"
}

variable "pet_name_length" {
  description = "The length of the random pet name"
  type        = number
  default     = 2
}
########################

# Task 2: Use Complex Variable Types
#     Update the variables.tf file to include a list and map variable:

variable "prefix_list" {
  description = "A list of prefixes for the random pet names"
  type        = list(string)
  default     = ["Mr", "Mrs", "Sir"]
}

variable "file_content_map" {
  description = "A map of file contents"
  type        = map(string)
  default     = {
    statement1 = "Hello, Terraform!"
    statement2 = "Goodbye, Terraform!"
  }
}
# variable "statement_key" {
#   description = "The key to look up in the file_content_map"
#   type        = string
#   default     = "statement2"  # Change this if needed
# }