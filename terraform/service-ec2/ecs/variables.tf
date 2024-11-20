variable "ecr_app" {
  type = string
}

variable "ecs_asg_arn" {
  type = string
}

variable "ecr_redis" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}
