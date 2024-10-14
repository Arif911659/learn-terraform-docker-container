# main.tf

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_s3_bucket" "my_bucket" {
    bucket = "my-bucket-poridhi123"  # Replace underscores with hyphens

    tags = {
        Name = "MyBucket"
        Environment = "Dev"
        Owner = "Poridhi"
        Project = "Terraform"
        CostCenter = "123456"
        Department = "IT"
        CreatedBy = "Terraform"
        CreatedOn = "2023-07-01"
        LastModifiedBy = "Terraform"
        LastModifiedOn = "2023-07-02"
        Description = "This is my Terraform bucket"
    }  
}
resource "aws_s3_bucket_acl" "my_bucket_acl" {
  bucket = aws_s3_bucket.my_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "my_bucket_versioning" {
    bucket = aws_s3_bucket.my_bucket.id
    versioning_configuration {
        status = "Enabled"
    }  
}
