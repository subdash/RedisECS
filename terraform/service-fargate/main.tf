terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "terraform-remote-state-dash-admin"
    key    = "tf-remote-state-ecs-fargate"
    region = "us-east-1"
  }
}
