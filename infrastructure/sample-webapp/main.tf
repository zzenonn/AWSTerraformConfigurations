provider "aws" {}

module "network" {
    source          = "../modules/network"
    project_name    = var.project_name
    environment     = var.environment
    db_port         = var.db_port
    networks        = var.networks
}

module "webapp" {
    source  = "../modules/asg_and_alb"
    project_name    = module.network.project_name
    environment     = module.network.environment
    vpc             = module.network.vpc
    private_subnets = module.network.private_subnets
    public_subnets  = module.network.public_subnets
    base_ami        = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
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
