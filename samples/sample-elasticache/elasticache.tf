resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.name_tag_prefix}-cache-subnet"
  subnet_ids = module.network.db_subnets
}

resource "aws_security_group" "redis" {
  name        = "${local.name_tag_prefix}-redis-sg"
  description = "Security group for Redis clusters"
  vpc_id      = module.network.vpc

  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [module.instances.bastion_security_group_id]
    description     = "Allow Redis access from bastion"
  }

  tags = {
    Name = "${local.name_tag_prefix}-redis-sg"
  }
}

# Single node Redis cluster
resource "aws_elasticache_cluster" "single_node" {
  cluster_id           = lower("${local.name_tag_prefix}-single")
  engine               = "redis"
  node_type            = var.cache_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = var.db_port
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis.id]
}

# Cluster mode Redis
resource "aws_elasticache_replication_group" "cluster_mode" {
  replication_group_id         = lower("${local.name_tag_prefix}-cluster")
  description                  = "Redis cluster mode"
  node_type                    = var.cache_node_type
  port                         = var.db_port
  parameter_group_name         = "default.redis7.cluster.on"
  subnet_group_name            = aws_elasticache_subnet_group.main.name
  security_group_ids           = [aws_security_group.redis.id]
  num_node_groups              = var.num_node_groups
  replicas_per_node_group      = var.replicas_per_node_group
  automatic_failover_enabled   = true
  apply_immediately            = true
}