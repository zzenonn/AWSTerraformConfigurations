output "vpc" {
  value = aws_vpc.vpc.id
}

output "total_subnets" {
  value = local.total_subnets
}

output "tag" {
  value = local.name_tag_prefix
}
