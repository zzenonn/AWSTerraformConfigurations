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

variable "git_repo" {
  type        = string
  default     = "Dev"
  description = "Repo in GitHub for the code"
}

variable "git_owner" {
  type        = string
  default     = "Dev"
  description = "Owner of the GitHub Repo"
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

variable "pipeline_cfn_role" {
  type        = string
  default     = ""
  description = "Role used to create Lambda functions and APIGWs"
}

variable "codestar_connection_arn" {
  type        = string
  default     = ""
  description = "ARN of Codestar connection"
}

variable "codebuild_environment_vars" {
  type        = map(any)
  default     = {}
  description = "Environment variables for codebuild"
}



locals {
  name_tag_prefix = "${var.project_name}-${var.environment}-${var.service}"
}
