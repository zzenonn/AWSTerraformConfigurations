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

resource "aws_iam_role" "asg_role" {
  count       = length(var.iam_policies) > 0 ? 1 : 0
  name        = "${var.project_name}-${var.environment}-AsgRole"
  path        = "/${var.project_name}/${var.environment}/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
}
EOF

  tags = {
    Env     = var.environment
    Project = var.project_name
  }
}

resource "aws_iam_role_policy" "asg_policy" {
  for_each    = var.iam_policies
  name        = "${var.project_name}-${var.environment}-${each.key}-Policy"
  role        = aws_iam_role.asg_role[0].id
  policy      = each.value
}

resource "aws_iam_instance_profile" "asg_profile" {
  count       = length(var.iam_policies)
  path        = "/${var.project_name}/${var.environment}/"
  role        = aws_iam_role.asg_role[0].name
}

resource "aws_security_group" "asg_instances" {
  name        = "${local.name_tag_prefix}-App-Sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc

  ingress {
    from_port        = 0
    to_port          = 65535
    protocol         = 6
    security_groups  = [aws_security_group.elb.id]
    description      = "Allow from ELB to this instance"
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "Allow to everywhere"
  }

  tags = {
    Name    = "${local.name_tag_prefix}-Asg-Sg"
    Env     = var.environment
    Project = var.project_name
  }
}

resource "aws_launch_template" "instances" {
  name = "${local.name_tag_prefix}-InstanceTemplate"


  iam_instance_profile {
    name = length(var.iam_policies) == 0 ? null : aws_iam_instance_profile.asg_profile[0].name
  }

  image_id = data.aws_ssm_parameter.base_ami.value


  instance_type = var.environment == "Prod" ? "t3.medium" : "t3.micro"

  monitoring {
    enabled = true #var.environment == "Prod" ? true : false
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups = [aws_security_group.asg_instances.id]
    delete_on_termination = true
  }

  user_data = base64encode(var.userdata)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${local.name_tag_prefix}-Instance"
      Env     = var.environment
      Project = var.project_name
    }
  }
}

resource "aws_autoscaling_group" "instances" {
  name                      = "${local.name_tag_prefix}-Asg"
  min_size                  = 2
  max_size                  = 5
  health_check_grace_period = 300
  health_check_type         = var.alb_healthcheck
  force_delete              = true
  vpc_zone_identifier       = var.private_subnets
  target_group_arns         = length(var.target_group_arns) == 0 ? null : var.target_group_arns 
  
  launch_template {
    name    = aws_launch_template.instances.name
    version = "$Latest"
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
