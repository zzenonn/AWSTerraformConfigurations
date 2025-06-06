provider "aws" {
  region  = var.region
  profile = var.profile
}

module "network" {
  source       = "github.com/zzenonn/AWSTerraformConfigurations/modules/infrastructure/network"
  project_name = var.project_name
  environment  = var.environment
  db_port      = var.db_port
  networks     = var.networks
  eks_cluster  = "${local.name_tag_prefix}-Cluster"
}