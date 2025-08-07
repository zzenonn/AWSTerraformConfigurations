resource "aws_elasticache_subnet_group" "main" {
  name       = "${module.network.project_name}-${module.network.environment}-cache-subnet"
  subnet_ids = module.network.db_subnets
}

# Single node Redis cluster
resource "aws_elasticache_cluster" "single_node" {
  cluster_id           = lower("${module.network.project_name}-${module.network.environment}-single")
  engine               = "redis"
  node_type            = var.cache_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = var.db_port
  subnet_group_name    = aws_elasticache_subnet_group.main.name
}

# Cluster mode Redis
resource "aws_elasticache_replication_group" "cluster_mode" {
  replication_group_id         = lower("${module.network.project_name}-${module.network.environment}-cluster")
  description                  = "Redis cluster mode"
  node_type                    = var.cache_node_type
  port                         = var.db_port
  parameter_group_name         = "default.redis7.cluster.on"
  subnet_group_name            = aws_elasticache_subnet_group.main.name
  num_node_groups              = 2
  replicas_per_node_group      = 1
  automatic_failover_enabled   = true
}