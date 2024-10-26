#This module will set up an Nginx server as a load balancer in the public subnet, routing requests to the private subnet.

resource "aws_instance" "nginx_lb" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_id
  key_name      = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install nginx -y
              echo "upstream k3s_nodes {" >> /etc/nginx/nginx.conf
              EOF

  tags = {
    Name = "nginx-lb"
  }
}


