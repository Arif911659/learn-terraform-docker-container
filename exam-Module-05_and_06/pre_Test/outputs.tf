output "nginx_lb_public_ip" {
  value = aws_instance.nginx_lb.public_ip
}

output "k3s_master_private_ip" {
  value = aws_instance.k3s_master.private_ip
}

output "k3s_worker_private_ips" {
  value = aws_instance.k3s_worker.*.private_ip
}

# output "k3s_token" {
#   description = "The token for the k3s master node"
#   value       = aws_instance.k3s_master.provisioner.remote-exec.result
# }
# output "k3s_master_token" {
#   description = "The K3S token from the master node"
#   value       = file("${path.module}/k3s_token.txt")
# }
