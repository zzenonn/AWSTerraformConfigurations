variable "project_name" {
  type    = string
  default = "Demo"
}

variable "environment" {
  type    = string
  default = "Dev"
}

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
#  validation {
#    condition     = can(regex("((\\d\\d\\d)\\.){4}/\\d\\d", var.networks.cidr_block))
#    error_message = "The cidr block must be a valid cidr."
#  }
}


locals {
  total_subnets     = var.networks.public_subnets + var.networks.private_subnets + var.networks.db_subnets 
  name_tag_prefix   = "${var.project_name}-${var.environment}"
}

