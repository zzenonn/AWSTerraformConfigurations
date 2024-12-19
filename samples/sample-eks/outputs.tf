output "vpc_id" {
  description = "The ID of the VPC"
  value = module.network.vpc
}

output "eks_cluster_id" {
  description = "The ID of the EKS cluster"
  value = aws_eks_cluster.cluster.cluster_id
}

output "kube_alb_controller_role_arn" {
  description = "The ARN of the IAM role for the ALB controller"
  value = aws_iam_role.kube_alb_controller.arn
}

output "kube_gateway_controller_role_arn" {
  description = "The ARN of the IAM role for the Gateway controller"
  value = aws_iam_role.kube_gateway_controller.arn
}

output "kube_ebs_csi_controller_role_arn" {
  description = "The ARN of the IAM role for the EBS CSI controller"
  value = aws_iam_role.kube_ebs_csi_controller.arn
}

output "kube_apigw_controller_role_arn" {
  description = "The ARN of the IAM role for the API Gateway controller"
  value = aws_iam_role.kube_apigw_controller.arn
}

output "kube_node_role_arn" {
  description = "The ARN of the IAM role for the EKS node group"
  value       = aws_iam_role.node_role.arn
}

output "kube_node_role_name" {
  description = "The ARN of the IAM role for the EKS node group"
  value       = aws_iam_role.node_role.name
}

output "kube_adot_collector_role_arn" {
  description = "The ARN of the IAM role for the ADOT Collector"
  value       = aws_iam_role.kube_adot_collector_role.arn
}

output "kube_karpenter_controller_role_arn" {
  description = "The ARN of the IAM role for the Karpenter controller"
  value       = aws_iam_role.karpenter_controller_role.arn
}

output "karpenter_interruption_sqs_queue_name" {
  description = "The name of the SQS queue"
  value       = aws_sqs_queue.karpenter_interruption_queue.name
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
