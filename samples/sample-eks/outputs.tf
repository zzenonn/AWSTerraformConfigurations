output "vpc_id" {
  value = module.network.vpc
}

output "eks_cluster_id" {
  value = aws_eks_cluster.cluster.cluster_id
}

output "kube_alb_controller_role_arn" {
  value = aws_iam_role.kube_alb_controller.arn
}

output "kube_gateway_controller_role_arn" {
  value = aws_iam_role.kube_gateway_controller.arn
}

output "kube_ebs_csi_controller_role_arn" {
  value = aws_iam_role.kube_ebs_csi_controller.arn
}

output "kube_apigw_controller_role_arn" {
  value = aws_iam_role.kube_apigw_controller.arn
}

output "kube_karpenter_node_role_arn" {
  description = "The ARN of the IAM role for the Karpenter node"
  value       = aws_iam_role.kube_karpenter_node_role.arn
}

output "kube_adot_collector_role_arn" {
  description = "The ARN of the IAM role for the ADOT Collector"
  value       = aws_iam_role.kube_adot_collector_role.arn
}

output "eks_cluster_name" {
  value = aws_eks_cluster.cluster.name
}

output "endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.cluster.certificate_authority[0].data
}

output "region" {
  value = var.region
}