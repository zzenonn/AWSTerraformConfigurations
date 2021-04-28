resource "aws_kms_key" "ekscrypt" {
  description             = "KMS key for EKS Cluster"
  deletion_window_in_days = 10
}

resource "aws_eks_cluster" "cluster" {
  name     = "${local.name_tag_prefix}-Cluster"
  role_arn = aws_iam_role.cluster_role.arn

  vpc_config {
    subnet_ids = module.network.private_subnets
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
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
    aws_ec2_tag.public_subnet, 
    aws_ec2_tag.private_subnet
  ]
}

output "endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.cluster.certificate_authority[0].data
}