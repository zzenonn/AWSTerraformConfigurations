variable "project_name" {
  type        = string
  default     = "Demo-OpenSearch"
  description = "Project name for tagging purposes"
}

variable "region" {
  type        = string
  default     = "ap-southeast-1"
  description = "AWS region to deploy resources"
}

variable "environment" {
  type        = string
  default     = "Dev"
  description = "Environment name for tagging purposes"
}

variable "db_port" {
  type        = number
  default     = 443 # OpenSearch HTTPS
  description = "Port of the database being used"
}

variable "profile" {
  type        = string
  default     = "default"
  description = "AWS profile to use"
}

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
    public_cidr_bits  = 9
    db_cidr_bits      = 8
    nat_gateways      = 3
  }
  description = "All information regarding network configuration is stored in this object"
}

variable "opensearch_instance_type" {
  type        = string
  default     = "t3.small.search"
  description = "OpenSearch instance type"
}

variable "opensearch_instance_count" {
  type        = number
  default     = 3
  description = "Number of OpenSearch instances"
}

variable "opensearch_version" {
  type        = string
  default     = "OpenSearch_2.3"
  description = "OpenSearch engine version"
}

locals {
  name_tag_prefix = "${var.project_name}-${var.environment}"
}