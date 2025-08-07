variable "project_name" {
  type        = string
  default     = "Demo"
  description = "Project name for tagging purposes"
}

variable "environment" {
  type        = string
  default     = "Dev"
  description = "Environment name for tagging purposes"
}

variable "db_port" {
  type        = number
  description = "Comes from networking template"
}

variable "vpc" {
  type        = string
  description = "Comes from networking template"
}

variable "private_subnets" {
  type        = list(any)
  description = "Comes from networking template"
}

variable "public_subnets" {
  type        = list(any)
  description = "Comes from networking template"
}

variable "db_subnets" {
  type        = list(any)
  description = "Comes from networking template"
}

variable "db_subnet_group" {
  type        = string
  description = "Comes from networking template"
}

variable "db_engine" {
  type        = string
  default     = "postgres"
  description = "DB engine being used"
}

variable "db_user" {
  type        = string
  default     = "dbsuper"
  description = "Superuser username"
}

variable "bastion_user_data" {
  type        = string
  default     = <<-EOF
    #!/bin/bash
    amazon-linux-extras install postgresql11 vim epel -y
    yum install -y postgresql-server postgresql-devel
    EOF
  description = "User data script for bastion host"
}

data "aws_ssm_parameter" "amazon_linux_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

locals {
  name_tag_prefix = "${var.project_name}-${var.environment}"
}
