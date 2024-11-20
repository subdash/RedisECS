terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "terraform-remote-state-dash-admin"
    key    = "tf-remote-state-ec2"
    region = "us-east-1"
  }
}

resource "aws_security_group" "ec2_sg" {
  name = "ec2-sg"
  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "ec2_sg_ingress_ssh" {
  // Allow SSH from configured ip
  ip_protocol       = "tcp"
  from_port = 22
  to_port = 22
  cidr_ipv4 = "${var.home_ip}/32"
#   cidr_ipv4 = "0.0.0.0/0"
  security_group_id = aws_security_group.ec2_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "ec2_sg_ingress_http" {
  // Allow http from anywhere -- should tweak
  ip_protocol       = "tcp"
  from_port = 80
  to_port = 80
  cidr_ipv4 = "0.0.0.0/0"
  security_group_id = aws_security_group.ec2_sg.id
}

resource "aws_vpc_security_group_egress_rule" "ec2_sg_egress" {
  // Allow all egress
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  security_group_id = aws_security_group.ec2_sg.id
}

resource "aws_launch_template" "ecs_launch_template" {
  name_prefix = "ecs-template"
  image_id = "ami-0453ec754f44f9a4a"
  instance_type = "t3.micro"
  key_name = "ecs_ec2_keypair"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile {
    // A predefined role that gives EC2 instance access to ECS
    name = "AutoScalingServiceRolePolicy"
  }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp2"
    }
  }
  user_data = filebase64("${path.module}/ecs.sh")
}

resource "aws_autoscaling_group" "ecs_asg" {
  // Zone identifier limits ASG to provision instances in the same availability zones where the subnets are created
  vpc_zone_identifier = var.public_subnets
  min_size = 1
  max_size = 3
  desired_capacity = 2
  launch_template {
    id = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }
}