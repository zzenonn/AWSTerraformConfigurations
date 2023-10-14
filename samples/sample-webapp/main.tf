provider "aws" {
  region  = "ap-southeast-1"
  profile = "terraform"
}

module "network" {
  source       = "github.com/zzenonn/AWSTerraformConfigurations/modules/infrastructure/network"
  project_name = var.project_name
  environment  = var.environment
  db_port      = var.db_port
  networks     = var.networks
}

module "webapp" {
  source            = "github.com/zzenonn/AWSTerraformConfigurations/modules/infrastructure/asg_and_alb"
  project_name      = module.network.project_name
  environment       = module.network.environment
  vpc               = module.network.vpc
  private_subnets   = module.network.private_subnets
  public_subnets    = module.network.public_subnets
  # alb_healthcheck   = "ELB"
  base_ami          = "/aws/service/ami-amazon-linux-latest/amzn-ami-hvm-x86_64-gp2"
  target_group_arns = [aws_lb_target_group.app.arn]
  iam_policies      = local.ssm_policy
  userdata          = <<-EOF
      #!/bin/bash -ex

      # Update yum
      yum -y update

      # Add node's source repo
      curl -sL https://rpm.nodesource.com/setup_15.x | bash -

      #Install nodejs
      yum -y install nodejs

      #Install Amazon Linux extras
      amazon-linux-extras install epel

      #Install stress tool (for load balancing testing)
      yum -y install stress

      # Create a dedicated directory for the application
      mkdir -p /var/app

      # Get the app from Amazon S3
      wget https://aws-tc-largeobjects.s3-us-west-2.amazonaws.com/ILT-TF-100-TECESS-5/app/app.zip

      # Extract it into a desired folder
      unzip app.zip -d /var/app/
      cd /var/app/

      # Configure S3 bucket details
      export PHOTOS_BUCKET=YOUR-S3-BUCKET-NAME

      # Configure default AWS Region
      export DEFAULT_AWS_REGION=YOUR-DEFAULT-AWS-REGION

      # Enable admin tools for stress testing
      export SHOW_ADMIN_TOOLS=1

      # Install dependencies
      npm install

      # Start your app
      npm start



    EOF
}
