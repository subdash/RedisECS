resource "aws_ecs_cluster" "redis_cluster" {
  name = "redis-cluster"
}

resource "aws_cloudwatch_log_group" "event_search_log_group" {
  name              = "/aws/ecs/redis-cluster"
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
      name      = "redis"
      image     = "${var.ecr_repository}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 6379
          hostPort      = 6379
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.event_search_log_group.name,
          awslogs-region        = "us-east-1",
          awslogs-stream-prefix = "redis-cluster"
        }
      }
    }
  ])
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
}

/*
aws-vault exec heb-eng-sandbox-alpha-staff -- aws ecs execute-command --cluster redis-cluster --task arn:aws:ecs:us-east-1:867441174595:task/redis-cluster/eab91c65f1734eff884aa27d2528dfae --container redis --command "bin/bash" --interactive

 */

resource "aws_ecs_service" "redis" {
  name                   = "redis-service"
  cluster                = aws_ecs_cluster.redis_cluster.id
  task_definition        = aws_ecs_task_definition.redis_task_def.arn
  desired_count          = 3
  depends_on             = [aws_iam_policy.execution_iam_policy, aws_iam_policy.task_iam_policy]
  launch_type            = "FARGATE"
  enable_execute_command = true
  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.ecs_sg.id]
  }
}
