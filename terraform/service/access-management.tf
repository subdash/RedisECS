resource "aws_security_group" "ecs_sg" {
  vpc_id = var.vpc_id
  name   = "redis-ecs-sg"
}

resource "aws_vpc_security_group_ingress_rule" "sg_ingress" {
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 0
  to_port           = 6379
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.ecs_sg.id
}

resource "aws_vpc_security_group_egress_rule" "sg_egress" {
  // Allow all egress
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  security_group_id = aws_security_group.ecs_sg.id
}

// NOTE: Just an example
data "aws_iam_policy_document" "execution_policy" {
  statement {
    actions = [
      "ecs:*",
      "ecr:*",
      "ssm:*",
      "logs:*"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "task_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "ssm:*",
      "logs:*",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "redis_cluster_task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "redis_cluster_execution_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "redis_cluster_task_role" {
  assume_role_policy = data.aws_iam_policy_document.redis_cluster_task_assume_role_policy.json
}

resource "aws_iam_role" "redis_cluster_execution_role" {
  assume_role_policy = data.aws_iam_policy_document.redis_cluster_execution_assume_role_policy.json
}

resource "aws_iam_policy" "execution_iam_policy" {
  policy = data.aws_iam_policy_document.execution_policy.json
}

resource "aws_iam_policy" "task_iam_policy" {
  policy = data.aws_iam_policy_document.task_policy.json
}

resource "aws_iam_role_policy_attachment" "redis_execution_policy_attachment" {
  policy_arn = aws_iam_policy.execution_iam_policy.arn
  role       = aws_iam_role.redis_cluster_execution_role.name
}

resource "aws_iam_role_policy_attachment" "redis_task_policy_attachment" {
  policy_arn = aws_iam_policy.task_iam_policy.arn
  role       = aws_iam_role.redis_cluster_task_role.name
}
