resource "aws_eks_fargate_profile" "fargate_profile" {
  count                  = var.fargate_deployment ? 1 : 0
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "${local.name_tag_prefix}-FargateProfile"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role[0].arn

  subnet_ids = module.network.private_subnets

  selector {
    namespace = "aws-*"
  }

  selector {
    namespace = "kube-*"
  }

  selector {
    namespace = "default"
  }
}

resource "aws_iam_role" "fargate_pod_execution_role" {
  count = var.fargate_deployment ? 1 : 0
  name  = "${local.name_tag_prefix}-FargatePodExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fargate_pod_execution_role_policy" {
  count      = var.fargate_deployment ? 1 : 0
  role       = aws_iam_role.fargate_pod_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}
