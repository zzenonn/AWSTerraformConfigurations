/*
This template is for provisioning of an
  Autoscaling Group and Application Load Balancer
*/

resource "aws_security_group" "elb" {
  name        = "${local.name_tag_prefix}-Elb-Sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc

  ingress {
    from_port   = var.elb_port
    to_port     = var.elb_port
    protocol    = 6
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow from anywhere to the app port ${var.elb_port} on this ELB"
  }
  # Test app port
  ingress {
    from_port   = var.test_port
    to_port     = var.test_port
    protocol    = 6
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow from anywhere to the app port ${var.elb_port} on this ELB"
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "Allow to everywhere from ELB"
  }

  tags = {
    Name    = "${local.name_tag_prefix}-Asg-Sg"
    Env     = var.environment
    Project = var.project_name
  }
}

resource "aws_lb" "app" {
  name               = "${local.name_tag_prefix}-Alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb.id]
  subnets            = local.elb_subnets

  tags = {
    Name    = "${local.name_tag_prefix}-Instance"
    Env     = var.environment
    Project = var.project_name
  }
}
