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

variable "service" {
  type        = string
  default     = "Dev"
  description = "Environment name for tagging purposes"
}

variable "codebuild_compute" {
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
  description = "Sompute to use with codebuild"
}

variable "codebuild_image" {
  type        = string
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
  description = "Image to use with codebuild"
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
  name_tag_prefix   = "${var.project_name}-${var.environment}-${var.service}"

  
}
