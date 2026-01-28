provider "aws" {
  region  = var.region
  profile = var.profile
  default_tags {
    tags = {
      auto-delete = "no",
      auto-stop = "no"
    }
  }
}

module "network" {
  source       = "../../modules/infrastructure/network"
  project_name = var.project_name
  environment  = var.environment
  db_port      = var.db_port
  networks     = var.networks
}

module "instances" {
  source                = "../../modules/infrastructure/instances"
  project_name          = module.network.project_name
  environment           = module.network.environment
  db_port               = module.network.db_port
  vpc                   = module.network.vpc
  private_subnets       = module.network.private_subnets
  public_subnets        = module.network.public_subnets
  db_subnets            = module.network.db_subnets
  db_subnet_group       = module.network.db_subnet_group
  bastion_instance_type = "c5.4xlarge"
  bastion_user_data     = <<-EOF
    #cloud-config
    packages:
      - curl
      - jq
      - git
      - wget
      - tar
    
    runcmd:
      - rm -rf /usr/local/go
      - wget https://go.dev/dl/go1.25.0.linux-amd64.tar.gz -O /tmp/go.tar.gz
      - tar -C /usr/local -xzf /tmp/go.tar.gz
      - echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    EOF
}