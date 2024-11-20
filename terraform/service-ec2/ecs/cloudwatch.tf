resource "aws_cloudwatch_log_group" "redis_ecs_log_group" {
  name              = "/aws/ecs/rate-limit-redis"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "app_ecs_log_group" {
  name              = "/aws/ecs/rate-limit-app"
  retention_in_days = 7
}
