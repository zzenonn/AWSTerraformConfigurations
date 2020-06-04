output "vpc" {
  value = aws_vpc.vpc.id
}

output "total_subnets" {
  value = local.total_subnets
}

output "db_subnet_group" {
  value = aws_db_subnet_group.db_subnets.id
}

output "db_port" {
  value = var.db_port
}

output "name_tag_prefix" {
  value = local.name_tag_prefix
}
