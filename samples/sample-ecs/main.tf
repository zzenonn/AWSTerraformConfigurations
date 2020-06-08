provider "aws" {
  profile = "terraform"
  region  = "ap-southeast-1"
}

module "network" {
    source          = "../../modules/infrastructure/network"
    project_name    = var.project_name
    environment     = var.environment
    db_port         = var.db_port
    networks        = var.networks
}

module "webapp" {
    source  = "../../modules/infrastructure/asg_and_alb"
    project_name        = module.network.project_name
    environment         = module.network.environment
    vpc                 = module.network.vpc
    private_subnets     = module.network.private_subnets
    public_subnets      = module.network.public_subnets
    base_ami            = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
    iam_policies        = local.instance_policies
    userdata            = <<-EOF
        #!/bin/bash
        echo "ECS_CLUSTER=${local.name_tag_prefix}-EcsCluster" >> /etc/ecs/ecs.config
        yum install -y iptables-services; sudo iptables --insert FORWARD 1 --in-interface docker+ --destination 169.254.169.254/32 --jump DROP
        iptables-save | sudo tee /etc/sysconfig/iptables && sudo systemctl enable --now iptables
    EOF
}
