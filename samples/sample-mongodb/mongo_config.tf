resource "aws_security_group" "config_servers" {
  name        = "${local.name_tag_prefix}-config-sg"
  description = "Security group for MongoDB config servers"
  vpc_id      = module.network.vpc

  ingress {
    from_port = 27019
    to_port   = 27019
    protocol  = "tcp"
    self      = true
    description = "MongoDB config port from other config members"
  }

  ingress {
    from_port       = 27019
    to_port         = 27019
    protocol        = "tcp"
    security_groups = [aws_security_group.mongos.id]
    description     = "MongoDB config port from mongos"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${local.name_tag_prefix}-config-sg"
  }
}

resource "aws_launch_template" "config" {
  name          = "${local.name_tag_prefix}-config"
  image_id      = data.aws_ssm_parameter.amazon_linux_ami.value
  instance_type = var.config_instance_type

  vpc_security_group_ids = [aws_security_group.config_servers.id]
  iam_instance_profile {
    name = "AmazonSSMRoleForInstancesQuickSetup"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = var.data_volume_type
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(file("${path.module}/userdata/config-userdata.yaml"))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.name_tag_prefix}-config"
      Type = "config"
    }
  }
}

resource "aws_autoscaling_group" "config" {
  name                = "${local.name_tag_prefix}-config"
  vpc_zone_identifier = module.network.private_subnets
  desired_capacity    = 2
  max_size            = 2
  min_size            = 2

  launch_template {
    id      = aws_launch_template.config.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_tag_prefix}-config"
    propagate_at_launch = false
  }

  tag {
    key                 = "Type"
    value               = "config"
    propagate_at_launch = false
  }
}