variable "project_name" {
  type        = string
  default     = "Demo-MongoDB"
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

variable "profile" {
  type        = string
  default     = "default"
  description = "AWS profile to use"
}

# Network Configuration
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
    nat_gateways      = 1
  }
  description = "All information regarding network configuration"
}

# MongoDB Cluster Configuration
variable "shard_count" {
  type        = number
  default     = 3
  description = "Number of shards in the cluster"
}

variable "replica_factor" {
  type        = number
  default     = 2
  description = "Number of replicas per shard"
}

variable "mongos_count" {
  type        = number
  default     = 1
  description = "Number of mongos router instances"
}

# Instance Configuration
variable "shard_instance_type" {
  type        = string
  default     = "t2.micro"
  description = "Instance type for shard servers"
}

variable "config_instance_type" {
  type        = string
  default     = "t2.micro"
  description = "Instance type for config servers"
}

variable "mongos_instance_type" {
  type        = string
  default     = "t2.micro"
  description = "Instance type for mongos routers"
}

# Storage Configuration
variable "data_volume_size" {
  type        = number
  default     = 20
  description = "Size of data volumes in GB"
}

variable "data_volume_type" {
  type        = string
  default     = "gp3"
  description = "EBS volume type"
}

locals {
  name_tag_prefix = "${var.project_name}-${var.environment}"
}

data "aws_ssm_parameter" "amazon_linux_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}
