resource "aws_security_group" "opensearch" {
  name        = "${local.name_tag_prefix}-opensearch-sg"
  description = "Security group for OpenSearch cluster"
  vpc_id      = module.network.vpc

  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [module.instances.bastion_security_group_id]
    description     = "Allow OpenSearch access from bastion"
  }

  tags = {
    Name = "${local.name_tag_prefix}-opensearch-sg"
  }
}

resource "aws_opensearch_domain" "main" {
  domain_name    = lower("${local.name_tag_prefix}-domain")
  engine_version = var.opensearch_version

  cluster_config {
    instance_type  = var.opensearch_instance_type
    instance_count = var.opensearch_instance_count
  }

  vpc_options {
    subnet_ids         = module.network.db_subnets
    security_group_ids = [aws_security_group.opensearch.id]
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 50
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  tags = {
    Name = "${local.name_tag_prefix}-opensearch"
  }
}