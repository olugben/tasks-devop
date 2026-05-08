variable "app_name" {
  type = string
}

variable "image_url" {
  type = string
}

variable "container_port" {
  type = number
}

variable "execution_role_arn" {
  type = string
}

variable "log_group_name" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "aws_region" {
  type = string
}