resource "aws_eks_node_group" "nodes" {
  count           = var.fargate_deployment ? 0 : 1
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${local.name_tag_prefix}-Node-Group"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = module.network.private_subnets
  instance_types  = ["c5.xlarge"]

  # launch_template {
  #   id = aws_launch_template.eks_nodes.id
  #   version = aws_launch_template.eks_nodes.latest_version
  # }

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 2
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_launch_template" "eks_nodes" {
  count = var.fargate_deployment ? 0 : 1
  name  = "${local.name_tag_prefix}-InstanceTemplate"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.node_group[0].id]
    delete_on_termination       = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${local.name_tag_prefix}-Instance"
      Env     = var.environment
      Project = var.project_name
    }
  }
}

resource "aws_security_group" "node_group" {
  count       = var.fargate_deployment ? 0 : 1
  name        = "${local.name_tag_prefix}-K8s-Nodes-Sg"
  description = "Security group for K8s Nodes"
  vpc_id      = module.network.vpc

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
    description = "Allow from itself"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow to everywhere"
  }

  tags = {
    Name    = "${local.name_tag_prefix}-Asg-Sg"
    Env     = var.environment
    Project = var.project_name
  }
}


resource "aws_security_group_rule" "from_vpc_lattice" {
  count       = var.fargate_deployment ? 0 : 1
  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = -1
  description = "Allow traffic from the VPC Lattice fleet"

  security_group_id = aws_security_group.node_group[0].id

  prefix_list_ids = [data.aws_ec2_managed_prefix_list.vpc_lattice.id]
}
