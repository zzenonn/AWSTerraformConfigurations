output "bastion_instance_id" {
  value = module.instances.bastion_id
}

output "redis_single_node_endpoint" {
  value = aws_elasticache_cluster.single_node.cache_nodes[0].address
}

output "redis_cluster_mode_configuration_endpoint" {
  value = aws_elasticache_replication_group.cluster_mode.configuration_endpoint_address
}