1. Create or Update the .gitignore File

Make sure your .gitignore file is correctly placed in the root directory of your Git repository. The contents should be:

Ignore all dotfiles
  
   .*

Ignore Terraform state files
  
  
   *.tfstate
   *.tfstate.*
   .terraform/

Ignore backup files
  
    *~
