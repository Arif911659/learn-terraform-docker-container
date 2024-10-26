#The main.tf file ties together all modules and specifies values for the variables.

module "network" {
  source             = "./modules/network"
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
}

module "compute" {
  source             = "./modules/compute"
  ami                = "ami-0c55b159cbfafe1f0" # Example Ubuntu AMI
  instance_type      = "t2.micro"
  private_subnet_id  = module.network.private_subnet_id
  key_name           = var.key_name
  worker_count       = 2
}

module "load_balancer" {
  source             = "./modules/load_balancer"
  ami                = "ami-0c55b159cbfafe1f0" # Example Ubuntu AMI for Nginx
  instance_type      = "t2.micro"
  public_subnet_id   = module.network.public_subnet_id
  key_name           = var.key_name
}


