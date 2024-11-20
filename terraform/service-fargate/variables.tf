variable "public_subnet_ids" {
  type    = list(string)
  default = []
}

variable "private_subnet_ids" {
  type    = list(string)
  default = []
}

variable "vpc_id" {
  type = string
}

variable "ecr_app" {
  type = string
}

variable "ecr_redis" {
  type = string
}

variable "vpc_main_cidr" {
  type = string
}
