provider "aws" {
  region  = var.region
  profile = var.profile
  default_tags {
    tags = {
      auto-delete = "yes",
      auto-stop = "yes"
    }
  }
}

module "network" {
  source       = "../../modules/infrastructure/network"
  project_name = var.project_name
  environment  = var.environment
  db_port      = 27017
  networks     = var.networks
}