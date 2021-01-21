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
    cidr_block          = string
    public_subnets      = number
    private_subnets     = number
    db_subnets          = number
    public_cidr_bits    = number
    private_cidr_bits   = number
    db_cidr_bits        = number
    nat_gateways        = number
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
#  validation {
#    condition     = can(regex("((\\d\\d\\d)\\.){4}/\\d\\d", var.networks.cidr_block))
#    error_message = "The cidr block must be a valid cidr."
#  }
}


locals {
  name_tag_prefix   = "${var.project_name}-${var.environment}"
  services          = {
    "Home"  = ["/", "/img*"]
    "Cat"   = ["/cats*"]
    "Dog"   = ["/dogs*"]
    
  }
  task_policies = {
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
  "ECSPolicy"    = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
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
  
  execution_policies = {
    "ExecutionPolicy"    = <<-EOF
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

# Looks for existing repositories
data "aws_ecr_repository" "services" {
  for_each   = local.services
  name       = lower("${var.project_name}/${each.key}")
}

data "aws_iam_policy" "codedeploy_ecs" {
  arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}
