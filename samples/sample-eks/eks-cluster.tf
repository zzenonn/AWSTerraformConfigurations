resource "aws_kms_key" "ekscrypt" {
  description             = "KMS key for EKS Cluster"
  deletion_window_in_days = var.kms_deletion_window
}

resource "aws_eks_cluster" "cluster" {
  name     = "${local.name_tag_prefix}-Cluster"
  role_arn = aws_iam_role.cluster_role.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids = concat(module.network.private_subnets, module.network.public_subnets)
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.ekscrypt.arn
    }
    resources = ["secrets"]
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController
  ]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "eks-pod-identity-agent"
}