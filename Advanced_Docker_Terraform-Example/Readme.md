    Create a custom Docker network.
    Create a Docker volume.
    Deploy two services: nginx and mysql, with each container running in the same custom network.
    Use environment variables to configure the mysql container.

Advanced Docker Terraform Example
1. Terraform Configuration (main.tf)

/*#######################################*/

# Specify the required provider version
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Initialize the Docker provider
provider "docker" {}

# Create a custom Docker network
resource "docker_network" "my_network" {
  name = "my_custom_network"
}

# Create a Docker volume for persistent storage
resource "docker_volume" "mysql_data" {
  name = "mysql_data_volume"
}

# Define a Docker image for Nginx (from Docker Hub)
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

# Define a Docker image for MySQL (from Docker Hub)
resource "docker_image" "mysql" {
  name         = "mysql:5.7"
  keep_locally = false
}

# Create a MySQL container
resource "docker_container" "mysql" {
  name  = "mysql-server"
  image = docker_image.mysql.latest

  # Attach container to custom network
  networks_advanced {
    name = docker_network.my_network.name
  }

  # Mount the Docker volume for persistent data storage
  volumes {
    volume_name    = docker_volume.mysql_data.name
    container_path = "/var/lib/mysql"
  }

  # Set environment variables for MySQL configuration
  env = [
    "MYSQL_ROOT_PASSWORD=rootpassword",
    "MYSQL_DATABASE=mydatabase",
    "MYSQL_USER=myuser",
    "MYSQL_PASSWORD=mypassword"
  ]
}

# Create an Nginx container
resource "docker_container" "nginx" {
  name  = "nginx-server"
  image = docker_image.nginx.latest

  # Attach container to custom network
  networks_advanced {
    name = docker_network.my_network.name
  }

  # Map port 80 in the container to port 8080 on the host machine
  ports {
    internal = 80
    external = 8080
  }

  # Link the Nginx container to the MySQL container (for inter-container communication)
  links = [docker_container.mysql.name]
}


/*#######################################*/

2. Explanation:

    docker_network: Creates a custom Docker network called my_custom_network where both containers will communicate.
    docker_volume: Creates a persistent volume called mysql_data_volume to store MySQL data, so data remains even if the container is recreated.

    docker_container (MySQL):

        Pulls the MySQL image (mysql:5.7) from Docker Hub.
        Attaches the MySQL container to the custom network.
        Configures the MySQL instance using environment variables, including database name, user, and password.
        Mounts a volume for persistent storage of the database.

    docker_container (Nginx):

        Pulls the Nginx image from Docker Hub.
        Attaches the Nginx container to the custom network.
        Exposes port 8080 on the host machine and maps it to port 80 in the Nginx container.
        Links the Nginx container to the MySQL container, allowing Nginx to communicate with MySQL.


3. Running the Configuration:

# Initialize the Terraform configuration
terraform init

# Plan the resources to be created
terraform plan

# Apply the configuration
terraform apply


# After applying, you'll have:

    An Nginx web server running on http://localhost:8080.
    A MySQL database running inside the Docker network.
    Persistent storage for MySQL via a Docker volume.
    Both containers will be able to communicate within the custom Docker network.

4. Verification:

    # To verify the containers are running:
        $ docker ps

    # To check the network configuration:
        $ docker network inspect my_custom_network

    # To verify that the MySQL container has persistent storage:
        $ docker volume inspect mysql_data_volume
5. Potential Enhancements:

    # Add more containers: 
        You could extend this example by adding other services like Redis or a custom application.
    # Scaling: 
        You could define multiple replicas of a container using Terraform for load balancing.
    # Monitoring: 
        Add tools like Prometheus or Grafana to monitor the containers.

===>>>
To add scaling and advanced features such as load balancing and container orchestration, we can expand the Terraform configuration by introducing concepts like multiple container replicas (scaling), reverse proxy load balancing (e.g., using HAProxy or Nginx), and even integrating a container orchestration platform like Docker Swarm or Kubernetes.

Let’s first focus on scaling and load balancing using Docker Swarm with Terraform. Docker Swarm is Docker’s native clustering and orchestration tool that can help you manage and scale containers across multiple nodes.
1. Scaling and Load Balancing with Docker Swarm

# Step-by-Step Setup:

    Initialize Docker Swarm.
    Create a service that can be scaled horizontally across multiple replicas.
    Add a load balancer to distribute traffic among the replicas.

Docker Swarm with Terraform Example

Terraform Configuration (main.tf):

/*#######################################*/

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

# Docker Swarm init (optional if already set up)
resource "docker_swarm" "swarm" {
  advertise_addr = "eth0"
}

# Create an overlay network for swarm services
resource "docker_network" "swarm_network" {
  name     = "swarm_network"
  driver   = "overlay"
  attachable = true
}

# Define the Docker image for the Nginx service
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

# Create a scalable Nginx service in Docker Swarm
resource "docker_service" "nginx_service" {
  name = "nginx-service"

  # Reference the Nginx Docker image
  task_spec {
    container_spec {
      image = docker_image.nginx.name
    }

    # Define resource limits (optional, but good for production environments)
    resources {
      limits {
        memory = "256m"
      }
      reservations {
        memory = "128m"
      }
    }
  }

  # Set the number of replicas for scaling
  mode {
    replicated {
      replicas = 3
    }
  }

  # Attach the service to the custom overlay network
  endpoint_spec {
    ports {
      target_port    = 80   # Inside the container
      published_port = 8080 # Exposed port on the host
      protocol       = "tcp"
    }
  }

  networks = [docker_network.swarm_network.name]
}

# Load balancer using HAProxy (can also use Nginx)
resource "docker_image" "haproxy" {
  name         = "haproxy:latest"
  keep_locally = false
}

# HAProxy container to distribute load across Nginx replicas
resource "docker_container" "haproxy_lb" {
  name  = "haproxy-lb"
  image = docker_image.haproxy.latest

  ports {
    internal = 80
    external = 80
  }

  networks_advanced {
    name = docker_network.swarm_network.name
  }

/*Simple HAProxy config (can be enhanced)*/
  provisioner "local-exec" {
    command = <<EOT
      echo "
        global
          log /dev/log    local0
          log /dev/log    local1 notice
          chroot /var/lib/haproxy
          stats socket /run/haproxy/admin.sock mode 660 level admin
          stats timeout 30s
          user haproxy
          group haproxy
          daemon
          ca-base /etc/ssl/certs
          crt-base /etc/ssl/private
          ssl-default-bind-ciphers PROFILE=SYSTEM
          ssl-default-bind-options no-sslv3

        defaults
          log     global
          option  redispatch
          option  forwardfor
          option  http-server-close
          option  dontlognull
          timeout connect 5000ms
          timeout client  50000ms
          timeout server  50000ms
          retries 3

        frontend http-in
          bind *:80
          default_backend servers

        backend servers
          server nginx1 nginx-service:80 maxconn 32
      " > /usr/local/etc/haproxy/haproxy.cfg
    EOT
                }
        }


/*#######################################*/

Explanation of the Advanced Setup:

    Docker Swarm Initialization:
        The docker_swarm resource initializes a Docker Swarm. This step is optional if the Docker Swarm is already set up on the system.

    Swarm Overlay Network:
        The docker_network resource creates a Swarm overlay network. This network type is necessary for Swarm services to communicate across multiple nodes.

    Nginx Service:
        The docker_service resource defines an Nginx service that runs 3 replicas. It runs on the swarm_network overlay network and exposes port 8080 to the host machine.
        Each replica is automatically load-balanced by Docker Swarm, and traffic is evenly distributed across the replicas.

    HAProxy as Load Balancer:
        The docker_container resource runs an HAProxy container that acts as a reverse proxy load balancer for the Nginx service.
        The HAProxy configuration distributes incoming traffic on port 80 to the Nginx service running inside the Swarm on port 80.

# Scaling and Managing Replicas:

The number of replicas can be easily adjusted by changing the replicas value in the docker_service resource:


        mode {
            replicated {
            replicas = 5 # Adjust the number of replicas here
                        }
                }

After updating the Terraform configuration, simply run:

        terraform apply

Docker Swarm will automatically scale the service up or down and distribute traffic across all the replicas.
Advanced Features:

    # Auto-Scaling: 
    This example shows manual scaling. For auto-scaling based on metrics, you'd need additional tooling like Docker Swarm Prometheus for monitoring and Alertmanager to trigger scale actions. For Kubernetes, it has built-in auto-scaling features.

    # Kubernetes: 
    If you’re looking for more advanced orchestration, you could use Kubernetes instead of Docker Swarm. Kubernetes allows for more sophisticated scaling policies, rolling updates, and self-healing.

    # Blue/Green or Canary Deployments: 
    You can add support for rolling out updates gradually to a subset of replicas (canary deployments) or switch traffic between old and new versions of your services (blue/green deployments).



# To remove the Nginx service:

docker service rm nginx-service

# To stop and remove the HAProxy container:

docker stop haproxy-lb && docker rm haproxy-lb

# To remove the Docker network:

docker network rm swarm_network

# To remove the Nginx image:

docker rmi nginx:latest

