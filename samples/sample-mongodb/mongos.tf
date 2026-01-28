resource "aws_security_group" "mongos" {
  name        = "${local.name_tag_prefix}-mongos-sg"
  description = "Security group for MongoDB mongos routers"
  vpc_id      = module.network.vpc

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "MongoDB mongos port from applications"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${local.name_tag_prefix}-mongos-sg"
  }
}

resource "aws_launch_template" "mongos" {
  name          = "${local.name_tag_prefix}-mongos"
  image_id      = data.aws_ssm_parameter.amazon_linux_ami.value
  instance_type = var.mongos_instance_type

  vpc_security_group_ids = [aws_security_group.mongos.id]
  iam_instance_profile {
    name = "AmazonSSMRoleForInstancesQuickSetup"
  }

  user_data = base64encode(file("${path.module}/userdata/mongos-userdata.yaml"))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.name_tag_prefix}-mongos"
      Type = "mongos"
    }
  }
}

resource "aws_autoscaling_group" "mongos" {
  name                = "${local.name_tag_prefix}-mongos"
  vpc_zone_identifier = module.network.public_subnets
  desired_capacity    = var.mongos_count
  max_size            = var.mongos_count
  min_size            = var.mongos_count

  depends_on = [aws_autoscaling_group.config, aws_autoscaling_group.shard]

  launch_template {
    id      = aws_launch_template.mongos.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_tag_prefix}-mongos"
    propagate_at_launch = false
  }

  tag {
    key                 = "Type"
    value               = "mongos"
    propagate_at_launch = false
  }
}