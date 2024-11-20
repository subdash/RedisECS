resource "aws_alb" "ecs_loadbalancer" {
  name                             = "redis-service-alb"
  load_balancer_type               = "application"
  ip_address_type                  = "ipv4"
  security_groups                  = [aws_security_group.lb_sg.id]
  subnets                          = var.public_subnet_ids
  idle_timeout                     = 60
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
  enable_http2                     = true
}

resource "aws_alb_target_group" "ecs_alb_redis_target_group" {
  name                          = "ecs-redis-alb-target-group"
  vpc_id                        = var.vpc_id
  target_type                   = "ip"
  port                          = 80
  protocol                      = "HTTP"
  deregistration_delay          = 20
  slow_start                    = 0
  load_balancing_algorithm_type = "least_outstanding_requests"
  health_check {
    interval            = 30
    path                = "/health"
    port                = null
    protocol            = "HTTP"
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}

resource "aws_alb_listener" "allow_http" {
  load_balancer_arn = aws_alb.ecs_loadbalancer.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs_alb_redis_target_group.arn
  }
}
