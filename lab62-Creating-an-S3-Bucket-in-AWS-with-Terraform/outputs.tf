# Write bucket information to a text file after bucket creation or update
resource "local_file" "bucket_info" {
  filename = "${path.module}/bucket_info.txt"  # Text file path
  content  = <<EOT
Bucket Name: ${aws_s3_bucket.my_bucket.bucket}
Bucket ARN: ${aws_s3_bucket.my_bucket.arn}
Bucket ID: ${aws_s3_bucket.my_bucket.id}
EOT
}

output "bucket_id" {
    value = aws_s3_bucket.my_bucket.id  
}

output "aws_s3_bucket_arn" {
    value = aws_s3_bucket.my_bucket.arn  
}