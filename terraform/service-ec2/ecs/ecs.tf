resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"
}

// Associates the ASG with the cluster's capacity provider
resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  name = "redis-ecs-capacity-provider"
  auto_scaling_group_provider {
    auto_scaling_group_arn = var.ecs_asg_arn
    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status = "ENABLED"
      target_capacity = 3
    }
  }
}

// Binds the ASG capacity provider with the cluster
resource "aws_ecs_cluster_capacity_providers" "ecs_capacity_providers" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]
  default_capacity_provider_strategy {
    base = 1
    weight = 100
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
  }
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                = "ecs-task"
  network_mode = "awsvpc"
  execution_role_arn = aws_iam_role.redis_cluster_execution_role.arn
  cpu = 512
  runtime_platform {
    // NOTE: We will need to rebuild the docker images from within the EC2 instance in order for them to be
    // compatible with the free-tier AMI we've selected for the EC2 instance that will run the containers.
    // Or, use buildx to build for x86_64: docker buildx build --push --platform linux/amd64 --tag rate-limit-app:latest
    // - https://github.com/docker/buildx
    // - https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/
    operating_system_family = "LINUX"
    cpu_architecture = "X86_64"
  }
  container_definitions = jsonencode([
    {
      name      = "redis"
      image     = "${var.ecr_redis}:latest"
      cpu = 256
      memory = 512
      essential = true
      portMappings = [
        {
          containerPort = 6379
          hostPort      = 6379
          protocol = "tcp"
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
      cpu = 256
      memory = 512
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol = "tcp"
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
}

resource "aws_ecs_service" "ecs_service" {
  name = "ecs-service"
  cluster = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count = 2
  network_configuration {
    subnets = var.public_subnets
    security_groups = [aws_security_group.ecs_sg.id]
  }
  force_new_deployment = true
  // Specify that container instances should run on distinct instances
  placement_constraints {
    type = "distinctInstance"
  }
  triggers = {
    redeployment = timestamp()
  }
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
    weight = 100
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name = "app"
    container_port = 3000
  }
}
