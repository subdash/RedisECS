resource "aws_security_group" "ecs_sg" {
  vpc_id = var.vpc_id
  name   = "redis-ecs-sg"
}

resource "aws_vpc_security_group_ingress_rule" "sg_ingress" {
  cidr_ipv4 = "0.0.0.0/0"
  // Port exposed by app container
  from_port         = 3000
  to_port           = 3000
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.ecs_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "sg_ingress_port_80" {
  cidr_ipv4 = "0.0.0.0/0"
  // Allow all???
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.ecs_sg.id
}

resource "aws_vpc_security_group_egress_rule" "sg_egress" {
  // Allow all egress
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  security_group_id = aws_security_group.ecs_sg.id
}

resource "aws_security_group" "lb_sg" {
  name   = "load-balancer-sg"
  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "lb_sg_egress" {
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
