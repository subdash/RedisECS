# data "aws_route53_zone" "hosted_zone" {
#   name         = var.hosted_zone
#   private_zone = true
#   vpc_id       = var.vpc_id
# }
#
resource "aws_security_group" "lb_sg" {
  name   = "load-balancer-sg"
  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "lb_sg_egress" {
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.lb_sg.id
}

# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-update-security-groups.html#security-group-recommended-rules
resource "aws_vpc_security_group_ingress_rule" "path_mtu_discovery" {
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.lb_sg.id
  ip_protocol       = "icmp"
}

// Allow all http ingress
resource "aws_vpc_security_group_ingress_rule" "listener_http_ingress" {
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.lb_sg.id
  ip_protocol       = "tcp"
}

// Allow all https ingress
resource "aws_vpc_security_group_ingress_rule" "listener_https_ingress" {
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.lb_sg.id
  ip_protocol       = "tcp"
}

resource "aws_alb" "ecs_loadbalancer" {
  name                             = "redis-service-alb"
  load_balancer_type               = "application"
  internal                         = true
  ip_address_type                  = "ipv4"
  security_groups                  = [aws_security_group.lb_sg.id]
  subnets                          = var.subnet_ids
  idle_timeout                     = 60
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
  enable_http2                     = true
}

resource "aws_lb_target_group" "ecs_alb_redis_target_group" {
  name                          = "ecs-redis-alb-target-group"
  vpc_id                        = var.vpc_id
  target_type                   = "ip"
  port                          = 80
  protocol                      = "HTTP"
  deregistration_delay          = 20
  slow_start                    = 0
  load_balancing_algorithm_type = "least_outstanding_requests"
}
