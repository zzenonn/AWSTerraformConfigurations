output "instance_ip_addr" {
  value = cidrsubnet("172.16.0.0/16", 8, 0)
}

output "total_subnets" {
  value = local.total_subnets
}

output "tag" {
  value = local.name_tag_prefix
}
