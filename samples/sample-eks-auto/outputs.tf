output "vpc_id" {
  description = "The ID of the VPC"
  value = module.network.vpc
}

output "eks_cluster_id" {
  description = "The ID of the EKS cluster"
  value = aws_eks_cluster.cluster.cluster_id
}

output "kube_node_role_arn" {
  description = "The ARN of the IAM role for the EKS node group"
  value       = aws_iam_role.node_role.arn
}

output "kube_node_role_name" {
  description = "The ARN of the IAM role for the EKS node group"
  value       = aws_iam_role.node_role.name
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value = aws_eks_cluster.cluster.name
}

output "endpoint" {
  description = "The endpoint for the EKS cluster"
  value = aws_eks_cluster.cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  description = "The certificate authority data for the EKS cluster kubeconfig"
  value = aws_eks_cluster.cluster.certificate_authority[0].data
}

output "region" {
  description = "The AWS region where resources are deployed"
  value = var.region
}
