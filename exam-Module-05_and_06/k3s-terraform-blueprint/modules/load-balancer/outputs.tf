# Output for the Nginx load balancer public IP
output "lb_public_ip" {
  value = aws_instance.nginx_lb.public_ip
  description = "Public IP address of the load balancer"
}
# Output for the Nginx load balancer private IP
output "lb_private_ip" {
  value = aws_instance.nginx_lb.private_ip  
  description = "Private IP address of the load balancer"
}