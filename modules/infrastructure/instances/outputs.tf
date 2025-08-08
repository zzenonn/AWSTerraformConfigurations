output "bastion_id" {
  value = aws_instance.bastion.id
}

# output "db_endpoint" {
#   value = aws_db_instance.db.endpoint
# }

output "ssm_role" {
  value = aws_iam_role.ssm_role.arn
}

output "bastion_security_group_id" {
  value = aws_security_group.bastion.id
}