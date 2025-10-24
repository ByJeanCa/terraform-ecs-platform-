terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = ">=5.0.0"   }
  }
}



resource "aws_cloudwatch_log_group" "ecs_fargate_logs" {
  name = format("/ecs/%s-%s", var.app_name, var.environment)
  retention_in_days = 14
  tags = var.common_tags
  
}

resource "aws_iam_role" "ecs_execution" {
  name = format("ecs-task-execution-role-%s", var.environment)
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_attachment" {
  role = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
  
resource "aws_ecs_task_definition" "app" {
  family                   = format("%s-%s-cont", var.app_name, var.environment)
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu                      = 256
  memory                   = 512

  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = format("%s-svc-%s", var.app_name, var.environment),
      image     = "${var.ecr_repository_url}:v1"
      essential = true,

      portMappings = [
        {
          containerPort = 8080,
          protocol      = "tcp"
        }
      ],

      environment = [
        { name = "ENV", value = var.environment }
      ],

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_fargate_logs.name,
          awslogs-region        = var.region, 
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
  tags = var.common_tags
}

resource "aws_ecs_cluster" "app_clust" {
  name = format("%s-svc-%s", var.app_name, var.environment)

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.common_tags
}

resource "aws_security_group" "svc" {
  name        = format("ecs-svc-%s", var.environment)
  description = "ECS service SG"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
    description     = "ALB - ECS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common_tags
}

resource "aws_ecs_service" "app_service" {
  name = format("%s-svc-%s", var.app_name, var.environment)
  cluster = aws_ecs_cluster.app_clust.id
  launch_type = "FARGATE"
  task_definition = aws_ecs_task_definition.app.arn
  desired_count = 0

  network_configuration {
    subnets          = var.private_subnets 
    assign_public_ip = false
    security_groups = [aws_security_group.svc.id] 
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = format("%s-svc-%s", var.app_name, var.environment)
    container_port   = 8080
  }

}
