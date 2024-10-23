# Output for the master node private IP
output "master_node_private_ip" {
  description = "Private IP address of the k3s master node"
  value       = aws_instance.master.private_ip
}

# Output for the worker node private IP
output "worker_node_private_ip" {
  description = "Private IP address of the k3s worker node"
  value       = aws_instance.worker.private_ip
}

# Output for the Nginx load balancer public IP
output "nginx_public_ip" {
  description = "Public IP address of the Nginx load balancer"
  value       = aws_instance.nginx.public_ip
}

# Output the key pair location
output "keypair_location" {
  description = "Location of the key pair in the local machine"
  value       = "${path.module}/my-keypair.pem"
}