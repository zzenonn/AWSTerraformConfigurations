variable "project_name" {
  type        = string
  default     = "Demo-Elasticache"
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
  default     = 6379 # Elasticache
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

variable "cache_node_type" {
  type        = string
  default     = "cache.t3.micro"
  description = "ElastiCache node type"
}

variable "num_node_groups" {
  type        = number
  default     = 2
  description = "Number of node groups (shards) for cluster mode Redis"
}

variable "replicas_per_node_group" {
  type        = number
  default     = 1
  description = "Number of replica nodes per node group for cluster mode Redis"
}

locals {
  name_tag_prefix = "${var.project_name}-${var.environment}"
}