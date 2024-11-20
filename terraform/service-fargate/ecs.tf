locals {
  redis_namespace = "redis-local.local"
}

resource "aws_ecs_cluster" "redis_cluster" {
  name = "redis-cluster"
}

resource "aws_cloudwatch_log_group" "redis_ecs_log_group" {
  name              = "/aws/ecs/rate-limit-redis"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "app_ecs_log_group" {
  name              = "/aws/ecs/rate-limit-app"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "redis_task_def" {
  family                   = "service"
  cpu                      = 1024
  memory                   = 2048
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.redis_cluster_task_role.arn
  execution_role_arn       = aws_iam_role.redis_cluster_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "redis-local"
      image     = "${var.ecr_redis}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 6379
          hostPort      = 6379
          protocol      = "tcp"
          name          = "redis-pm"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.redis_ecs_log_group.name,
          awslogs-region        = "us-east-1",
          awslogs-stream-prefix = "redis-cluster"
        }
      }
    },
    {
      name      = "app"
      image     = "${var.ecr_app}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
          appProtocol   = "http"
          name          = "app-pm"
        }
      ]
      environment = [
        {
          name  = "REDIS_DNS"
          value = local.redis_namespace
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app_ecs_log_group.name,
          awslogs-region        = "us-east-1",
          awslogs-stream-prefix = "redis-cluster"
        }
      }
    }
  ])
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "redis" {
  name                   = "redis-service"
  cluster                = aws_ecs_cluster.redis_cluster.id
  task_definition        = aws_ecs_task_definition.redis_task_def.arn
  desired_count          = 2
  depends_on             = [aws_iam_policy.execution_iam_policy, aws_iam_policy.task_iam_policy]
  launch_type            = "FARGATE"
  enable_execute_command = true
  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_sg.id]
  }
  load_balancer {
    container_name   = "app"
    container_port   = 3000
    target_group_arn = aws_alb_target_group.ecs_alb_redis_target_group.arn
  }
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.discovery_service_namespace.arn
    service {
      port_name = "redis-pm"
      client_alias {
        dns_name = local.redis_namespace
        port     = 6379
      }
    }
  }
}

resource "aws_service_discovery_private_dns_namespace" "discovery_service_namespace" {
  name = local.redis_namespace
  vpc  = var.vpc_id
}
