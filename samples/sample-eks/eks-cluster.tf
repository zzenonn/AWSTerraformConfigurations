resource "aws_kms_key" "ekscrypt" {
  description             = "KMS key for EKS Cluster"
  deletion_window_in_days = 10
}

resource "aws_eks_cluster" "cluster" {
  name     = "${local.name_tag_prefix}-Cluster"
  role_arn = aws_iam_role.cluster_role.arn
  version  = "1.30"

  vpc_config {
    subnet_ids = concat(module.network.private_subnets, module.network.public_subnets)
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.ekscrypt.arn
    }
    resources = ["secrets"]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController
  ]
}

output "endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.cluster.certificate_authority[0].data
}

