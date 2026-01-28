output "bastion_instance_id" {
  value = module.instances.bastion_id
}

output "opensearch_endpoint" {
  value = aws_opensearch_domain.main.endpoint
}

output "opensearch_dashboard_endpoint" {
  value = aws_opensearch_domain.main.dashboard_endpoint
}