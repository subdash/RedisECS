// Credit to https://spacelift.io/blog/terraform-ecs

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "terraform-remote-state-dash-admin"
    key    = "tf-remote-state-ecs"
    region = "us-east-1"
  }
}
