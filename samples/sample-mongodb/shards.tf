resource "aws_security_group" "shard_servers" {
  name        = "${local.name_tag_prefix}-shard-sg"
  description = "Security group for MongoDB shard servers"
  vpc_id      = module.network.vpc

  ingress {
    from_port = 27018
    to_port   = 27018
    protocol  = "tcp"
    self      = true
    description = "MongoDB shard port from other shard members"
  }

  ingress {
    from_port       = 27018
    to_port         = 27018
    protocol        = "tcp"
    security_groups = [aws_security_group.mongos.id]
    description     = "MongoDB shard port from mongos"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${local.name_tag_prefix}-shard-sg"
  }
}

resource "aws_launch_template" "shard" {
  count         = var.shard_count
  name          = "${local.name_tag_prefix}-shard-${count.index}"
  image_id      = data.aws_ssm_parameter.amazon_linux_ami.value
  instance_type = var.shard_instance_type

  vpc_security_group_ids = [aws_security_group.shard_servers.id]
  iam_instance_profile {
    name = "AmazonSSMRoleForInstancesQuickSetup"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.data_volume_size
      volume_type           = var.data_volume_type
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/userdata/shard-userdata.yaml", {
    shard_id         = count.index
    replica_set_name = "shard${count.index}"
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.name_tag_prefix}-shard-${count.index}"
      Type = "shard"
      ShardId = count.index
    }
  }
}

resource "aws_autoscaling_group" "shard" {
  count               = var.shard_count
  name                = "${local.name_tag_prefix}-shard-${count.index}"
  vpc_zone_identifier = module.network.private_subnets
  desired_capacity    = var.replica_factor
  max_size            = var.replica_factor
  min_size            = var.replica_factor

  depends_on = [aws_autoscaling_group.config]

  launch_template {
    id      = aws_launch_template.shard[count.index].id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_tag_prefix}-shard-${count.index}"
    propagate_at_launch = false
  }

  tag {
    key                 = "Type"
    value               = "shard"
    propagate_at_launch = false
  }

  tag {
    key                 = "ShardId"
    value               = count.index
    propagate_at_launch = false
  }
}