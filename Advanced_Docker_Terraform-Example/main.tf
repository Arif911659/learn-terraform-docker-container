# Required providers
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Initialize Docker provider
provider "docker" {}

# Create a custom Docker network for services
resource "docker_network" "swarm_network" {
  name     = "swarm_network"
  driver   = "overlay"
  attachable = true

  # Ensure that the network is created only after Swarm is initialized
  # depends_on = [null_resource.cleanup_nginx_service, null_resource.cleanup_haproxy]
}
# Null resource for Docker Swarm initialization using local-exec
resource "null_resource" "init_swarm" {
  provisioner "local-exec" {
    command = <<-EOT
      if ! docker info --format '{{.Swarm.ControlAvailable}}' | grep -q "true"; then
        docker swarm init --advertise-addr 172.16.200.87 || true
      else
        echo "Swarm is already initialized on this node."
      fi
    EOT
  }
  # Prevent re-execution unless changed
  triggers = {
    swarm_initialized = "${timestamp()}"
  }
}

# Define the Docker image for Nginx service
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
  #depends_on = [null_resource.cleanup_nginx_service]
}

# Create a scalable Nginx service in Docker Swarm
resource "null_resource" "nginx_service" {
  depends_on = [null_resource.init_swarm, docker_network.swarm_network]
  
  provisioner "local-exec" {
    command = <<EOT
      if ! docker service ls | grep -q nginx-service; then
        docker service create \
          --name nginx-service \
          --network ${docker_network.swarm_network.name} \
          --replicas 3 \
          --publish 8080:80 \
          nginx:latest
      else
        echo "Nginx service already exists. Updating..."
        docker service update \
          --replicas 3 \
          --publish-add 8080:80 \
          nginx-service

        # Ensure the service is connected to the correct network
        if ! docker service inspect nginx-service --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' | grep -q ${docker_network.swarm_network.name}; then
          docker service update --network-add ${docker_network.swarm_network.name} nginx-service
        fi
      fi
    EOT
  }

  triggers = {
    nginx_service_updated = "${timestamp()}"
  }
}


# Load balancer using HAProxy
resource "docker_image" "haproxy" {
  name         = "haproxy:latest"
  keep_locally = false
}

# Create HAProxy configuration file
resource "local_file" "haproxy_config" {
  filename = "${path.module}/haproxy.cfg"
  content  = <<-EOT
    global
      log /dev/log local0
      log /dev/log local1 notice
      maxconn 4096
      user haproxy
      group haproxy
      daemon

    defaults
      log     global
      mode    http
      option  httplog
      option  dontlognull
      retries 3
      timeout connect 5s
      timeout client  30s
      timeout server  30s

    frontend http_front
      bind *:80
      default_backend http_back

    backend http_back
      balance roundrobin
      server nginx1 nginx-service:80 check
  EOT
}

# HAProxy container for load balancing
resource "docker_container" "haproxy_lb" {
  depends_on = [null_resource.nginx_service, local_file.haproxy_config]
  name  = "haproxy-lb"
  image = docker_image.haproxy.name
  restart = "always"
  

  # Add this to ensure the container is removed when the resource is destroyed
  rm = true
  
  ports {
    internal = 80
    external = 80
  }
  
  networks_advanced {
    name = docker_network.swarm_network.name
  }

  volumes {
    host_path = abspath("${path.module}/haproxy.cfg")
    container_path = "/usr/local/etc/haproxy/haproxy.cfg"
  }

  command = ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
}


