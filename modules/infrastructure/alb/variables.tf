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

variable "elb_port" {
  type        = number
  default     = 80
  description = "Inbound port for the ELB"
}

variable "test_port" {
  type        = number
  default     = 8080
  description = "Inbound port for the ELB for testing"
}

data "aws_availability_zones" "azs" {}

locals {
  name_tag_prefix = "${var.project_name}-${var.environment}"
  num_pub_subnet  = length(var.public_subnets)
  num_azs         = length(data.aws_availability_zones.azs.zone_ids)
  elb_subnets     = local.num_pub_subnet > local.num_azs ? slice(var.public_subnets, 0, local.num_azs) : var.public_subnets

}
