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

variable "code_build_iam_policies" {
  type        = map
  default     = {}
  description = "IAM Policy to associate with code build instances. Defaults to allow access to ECR"
}

variable "pipeline_iam_policies" {
  type        = map
  default     = {}
  description = "IAM Policy to associate with code pipeline instances. Defaults to codepipeline service role"
}

variable "codedeploy_app" {
  type        = string
  default     = ""
  description = "Codedeploy app for this deployment"
}

variable "codedeploy_deployment_group" {
  type        = string
  default     = ""
  description = "Codedeploy deployment group for this deployment"
}


locals {
  name_tag_prefix   = "${var.project_name}-${var.environment}"
  code_build_iam_policy = {
  "CodeBuildDefault" = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "ssm:GetParametersByPath",
                "ssm:GetParameters",
                "ssm:GetParameter",
                "serverlessrepo:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
        {
          "Effect":"Allow",
          "Action": [
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketVersioning",
            "s3:PutObject"
          ],
          "Resource": [
            "${aws_s3_bucket.artifact_store.arn}",
            "${aws_s3_bucket.artifact_store.arn}/*"
          ]
        }        
        {
            "Action": [
              "ecr:BatchCheckLayerAvailability",
              "ecr:CompleteLayerUpload",
              "ecr:GetAuthorizationToken",
              "ecr:InitiateLayerUpload",
              "ecr:PutImage",
              "ecr:UploadLayerPart"
            ],
            "Resource": "*",
            "Effect": "Allow"
      }
    ]
}
EOF
    
  }
  code_pipeline_iam_policy = {
  
  "CodePipelineDefault" = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "ssm:GetParametersByPath",
                "ssm:GetParameters",
                "ssm:GetParameter",
                "serverlessrepo:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
        {
          "Effect":"Allow",
          "Action": [
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketVersioning",
            "s3:PutObject"
          ],
          "Resource": [
            "${aws_s3_bucket.artifact_store.arn}",
            "${aws_s3_bucket.artifact_store.arn}/*"
          ]
        }
        {
            "Action": [
              "ecr:BatchCheckLayerAvailability",
              "ecr:CompleteLayerUpload",
              "ecr:GetAuthorizationToken",
              "ecr:InitiateLayerUpload",
              "ecr:PutImage",
              "ecr:UploadLayerPart"
            ],
            "Resource": "*",
            "Effect": "Allow"
      }
    ]
}
EOF
}

  
}
