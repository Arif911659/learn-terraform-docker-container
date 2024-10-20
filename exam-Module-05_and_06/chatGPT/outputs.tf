# Generate a random token for k3s
resource "random_password" "k3s_token" {
  length  = 32
  special = false
}

# Outputs
output "nginx_lb_public_ip" {
  value = aws_instance.nginx_lb.public_ip
  description = "Public IP address of the NGINX load balancer"
}

output "k3s_master_private_ip" {
  value = aws_instance.k3s_master.private_ip
}

output "k3s_worker_private_ips" {
  value = aws_instance.k3s_workers[*].private_ip
}

output "k3s_token" {
  value     = random_password.k3s_token.result
  sensitive = true
}

output "ssh_command" {
  value = "ssh -i ${path.module}/k3s-key-pair.pem -J ubuntu@${aws_instance.nginx_lb.public_ip} ubuntu@<PRIVATE_IP>"
  description = "Command to SSH into private instances. Replace <PRIVATE_IP> with the desired instance's private IP."
}

output "key_pair_file" {
  value = local_file.private_key.filename
  description = "Path to the generated private key file"
}

output "internet_test_command" {
  value = "ssh -i ${path.module}/k3s-key-pair.pem -J ubuntu@${aws_instance.nginx_lb.public_ip} ubuntu@${aws_instance.k3s_master.private_ip} 'cat /tmp/internet_test_result.txt'"
  description = "Command to check the result of the internet connectivity test on the master node"
}
#Output for accessing the load-balanced web page
output "load_balanced_url" {
  value = "http://${aws_instance.nginx_lb.public_ip}"
  description = "URL to access the load-balanced web pages"
}