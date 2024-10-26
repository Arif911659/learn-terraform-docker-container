output "k3s_master_private_ip" {
  value = aws_instance.k3s_master.private_ip
}

output "k3s_worker_private_ips" {
  value = [for instance in aws_instance.k3s_worker : instance.private_ip]
}