resource "aws_ssm_parameter" "prefect_api_key" {
  name        = "/${var.name}/prefect/api/key"
  description = "prefect-api-key-${var.name}"
  type        = "SecureString"
  value       = var.prefect_api_key_pnu
}
resource "aws_iam_role" "prefect_agent_execution_role" {
  name = "prefect-agent-execution-role-${var.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "ssm-allow-read-prefect-api-key-${var.name}"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
        "ssm:GetParameter*",
        "ssm:GetParameters",
        "ssm:GetParameter",
        "ssm:GetParametersByPath",
        "secretsmanager:GetSecretValue"
      ],
          Effect = "Allow"
          Resource = ["arn:aws:ssm:eu-west-2:197578819129:parameter/*"]
        },
        {
            Effect: "Allow",
            Action: [
                "kms:Decrypt"
            ],
            Resource: "arn:aws:kms:eu-west-2:197578819129:key/0a7e7860-111f-4226-9f37-7fc0de7faab2"
        }
      ]
    })
  }
  // AmazonECSTaskExecutionRolePolicy is an AWS managed role for creating ECS tasks and services
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
}

resource "aws_iam_role" "prefect_agent_task_role" {
  name  = "prefect-agent-task-role-${var.name}"
  count = var.agent_task_role_arn == null ? 1 : 0

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "prefect-agent-allow-ecs-task-${var.name}"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ec2:DescribeSubnets",
            "ec2:DescribeVpcs",
            "ecr:BatchCheckLayerAvailability",
            "ecr:BatchGetImage",
            "ecr:GetAuthorizationToken",
            "ecr:GetDownloadUrlForLayer",
            "ecs:DeregisterTaskDefinition",
            "ecs:DescribeTasks",
            "ecs:RegisterTaskDefinition",
            "ecs:RunTask",
            "iam:PassRole",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:GetLogEvents",
            "logs:PutLogEvents"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_cloudwatch_log_group" "prefect_agent_log_group" {
  name              = "prefect-agent-log-group-${var.name}"
  retention_in_days = var.agent_log_retention_in_days
}

resource "aws_security_group" "prefect_agent" {
  name        = "prefect-agent-sg-${var.name}"
  description = "ECS Prefect Agent"
  vpc_id      = aws_vpc.perfect-staging-vpc.id
}

resource "aws_security_group_rule" "https_outbound" {
  // S3 Gateway interfaces are implemented at the routing level which means we
  // can avoid the metered billing of a VPC endpoint interface by allowing
  // outbound traffic to the public IP ranges, which will be routed through
  // the Gateway interface:
  // https://docs.aws.amazon.com/AmazonS3/latest/userguide/privatelink-interface-endpoints.html
  description       = "HTTPS outbound"
  type              = "egress"
  security_group_id = aws_security_group.prefect_agent.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]

}


resource "aws_ecs_cluster" "prefect_agent_cluster" {
  name = "prefect-agent-${var.name}"
}

resource "aws_ecs_cluster_capacity_providers" "prefect_agent_cluster_capacity_providers" {
  cluster_name       = aws_ecs_cluster.prefect_agent_cluster.name
  capacity_providers = ["FARGATE"]
}

resource "aws_ecs_task_definition" "prefect_agent_task_definition" {
  family = "prefect-agent-${var.name}"
  cpu    = var.agent_cpu
  memory = var.agent_memory

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  container_definitions = jsonencode([
    {
      name    = "prefect-agent-${var.name}"
      image   = var.agent_image
      command = ["prefect", "agent", "start", "-q", var.agent_queue_name]
      cpu     = var.agent_cpu
      memory  = var.agent_memory
      environment = [
        {
          name  = "PREFECT_API_URL"
          value = "https://api.prefect.cloud/api/accounts/${var.prefect_account_id}/workspaces/${var.prefect_workspace_id}"
        },
        {
          name  = "EXTRA_PIP_PACKAGES"
          value = var.agent_extra_pip_packages
        }
      ]
      secrets = [
        {
          name      = "PREFECT_API_KEY"
          valueFrom = aws_ssm_parameter.prefect_api_key.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.prefect_agent_log_group.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "prefect-agent-${var.name}"
        }
      }
    }
  ])
  // Execution role allows ECS to create tasks and services
  execution_role_arn = aws_iam_role.prefect_agent_execution_role.arn
  // Task role allows tasks and services to access other AWS resources
  // Use agent_task_role_arn if provided, otherwise populate with default
  task_role_arn = var.agent_task_role_arn == null ? aws_iam_role.prefect_agent_task_role[0].arn : var.agent_task_role_arn
}

resource "aws_ecs_service" "prefect_agent_service" {
  name          = "prefect-agent-${var.name}"
  cluster       = aws_ecs_cluster.prefect_agent_cluster.id
  desired_count = var.agent_desired_count
  launch_type   = "FARGATE"

  // Public IP required for pulling secrets and images
  // https://aws.amazon.com/premiumsupport/knowledge-center/ecs-unable-to-pull-secrets/
  network_configuration {
    security_groups  = [aws_security_group.prefect_agent.id]
    assign_public_ip = true
    subnets          = [aws_subnet.public-subnet-1.id,aws_subnet.public-subnet-2.id]
  }
  task_definition = aws_ecs_task_definition.prefect_agent_task_definition.arn
}
