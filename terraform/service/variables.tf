variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "assume_role_principals" {
  type = list(string)
  // e.g. "lambda.amazonaws.com"
  default = []
}

variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "remote_state_bucket" {
  type = string
}

variable "remote_state_key" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ecr_repository" {
  type = string
}

variable "hosted_zone" {
  type = string
}

variable "vpc_main_cidr" {
  type = string
}
