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
  default     = 5432
  description = "Port of the database being used"
}

variable "codestar_connection_arn" {
  type        = string
  default     = ""
  description = "ARN of Codestar connection"
}

# NOTE: THERE IS AN ASSUMPTION THAT PUBLIC SUBNETS ARE SMALLER THAN ALL OTHERS
variable "networks" {
  type = object({
    cidr_block        = string
    public_subnets    = number
    private_subnets   = number
    db_subnets        = number
    public_cidr_bits  = number
    private_cidr_bits = number
    db_cidr_bits      = number
    nat_gateways      = number
  })
  default = {
    cidr_block        = "10.0.0.0/16"
    public_subnets    = 3
    private_subnets   = 3
    db_subnets        = 3
    private_cidr_bits = 8
    public_cidr_bits  = 8
    db_cidr_bits      = 8
    nat_gateways      = 3
  }
  description = "All information regarding network configuration is stored in this object. NOTE: THERE IS AN ASSUMPTION THAT PUBLIC SUBNETS ARE SMALLER THAN ALL OTHERS"
}

locals {
  name_tag_prefix = "${var.project_name}-${var.environment}"
  services = {
    "Home" = ["/", "/img*"]
    "Cat"  = ["/cats*"]
    "Dog"  = ["/dogs*"]
  }
  instance_policies = {
    "SSMPolicy" = <<-EOF
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
    "ECSPolicy" = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeTags",
                "ecs:CreateCluster",
                "ecs:DeregisterContainerInstance",
                "ecs:DiscoverPollEndpoint",
                "ecs:Poll",
                "ecs:RegisterContainerInstance",
                "ecs:StartTelemetrySession",
                "ecs:UpdateContainerInstancesState",
                "ecs:Submit*",
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
  EOF
  }

}

data "aws_region" "current" {}

data "aws_ec2_managed_prefix_list" "vpc_lattice" {
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.${data.aws_region.current.name}.vpc-lattice"]
  }
}