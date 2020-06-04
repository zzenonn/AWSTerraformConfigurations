module "network" {
    source          = "../modules/network"
    project_name    = var.project_name
    environment     = var.environment
    db_port         = var.db_port
    networks        = var.networks
}

module "instances" {
    source  = "../modules/instances"
    name_tag_prefix = module.network.name_tag_prefix
    db_port         = module.network.db_port
    vpc             = module.network.vpc
    db_subnet_group = module.network.db_subnet_group
}