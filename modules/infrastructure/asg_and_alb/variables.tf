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
  type        = list
  description = "Comes from networking template"
}

variable "public_subnets" {
  type        = list
  description = "Comes from networking template"
}

variable "userdata" {
  type        = string
  description = "Userdata for the EC2 instances in the ASG"
}

variable "base_ami" {
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
  description = "Must be in the form of an SSM parameter key. See https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-public-parameters.html"
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

variable "alb_healthcheck" {
  type        = string
  default     = "EC2"
  description = "Determines an EC2 or ELB healthcheck"
}

variable "target_group_arns" {
  type        = set(string)
  default     = []
  description = "Target group the ASG will automatically add to"
}

variable "iam_policies" {
  type        = map
  default     = {
    "SSMPolicy"    = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:UpdateInstanceInformation",
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetEncryptionConfiguration"
            ],
            "Resource": "*"
        }
    ]
}
  EOF
  }
  description = "IAM Policy to associate with ASG instances. Defaults to required SSM policy. Use {} for no policy."
}

data "aws_ssm_parameter" "base_ami" {
  name = var.base_ami
}

data "aws_availability_zones" "azs" {}

locals {
  name_tag_prefix   = "${var.project_name}-${var.environment}"
  num_pub_subnet    = length(var.public_subnets)
  num_azs           = length(data.aws_availability_zones.azs.zone_ids)
  elb_subnets       = local.num_pub_subnet > local.num_azs ? slice(var.public_subnets, 0, local.num_azs) : var.public_subnets

}
