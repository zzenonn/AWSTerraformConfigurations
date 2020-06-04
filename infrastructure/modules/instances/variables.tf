variable "name_tag_prefix" {
  type        = string
  description = "Comes from networking template"
}

variable "db_port" {
  type        = number
  description = "Comes from networking template"
}

variable "vpc" {
  type        = string
  description = "Comes from networking template"
}

variable "db_subnet_group" {
  type        = string
  description = "Comes from networking template"
}