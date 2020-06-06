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
    base_ami            = "/aws/service/ami-amazon-linux-latest/amzn-ami-hvm-x86_64-gp2"
    target_group_arns   = [aws_lb_target_group.app.arn]
    userdata        = <<-EOF
        #!/bin/bash
        # Install Apache Web Server and PHP
        yum install -y httpd mysql php
        # Download Lab files
        wget https://us-west-2-tcprod.s3.amazonaws.com/courses/ILT-TF-100-TECESS/v4.6.8/lab-1-build-a-web-server/scripts/lab-app.zip
        unzip lab-app.zip -d /var/www/html/
        # Turn on web server
        chkconfig httpd on
        service httpd start
    EOF
}
