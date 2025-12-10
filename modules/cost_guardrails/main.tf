terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.0.0"
    }
  }
}

resource "aws_budgets_budget" "ecs" {
  name         = "ecs-fargate-monthly-budget"
  budget_type  = "COST"
  limit_amount = "1"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  time_period_start = "2024-01-01_00:00"

  cost_filter {
    name   = "Service"
    values = ["Amazon Elastic Container Service"]
  }

  notification {
    comparison_operator         = "GREATER_THAN"
    threshold                   = 100
    threshold_type              = "PERCENTAGE"
    notification_type           = "FORECASTED"
    subscriber_email_addresses = [var.email]
  }
}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "assume_budget" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["budgets.${data.aws_partition.current.dns_suffix}"]
    }

    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role" "budget_enforcer" {
  name               = "budget-enforcer-role"
  assume_role_policy = data.aws_iam_policy_document.assume_budget.json
}


data "aws_iam_policy_document" "budget_enforcer" {
  statement {
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "budget_enforcer" {
  name   = "budget-enforcer"
  policy = data.aws_iam_policy_document.budget_enforcer.json
}

resource "aws_iam_role_policy_attachment" "budget_permissions" {
  role       = aws_iam_role.budget_enforcer.name
  policy_arn = aws_iam_policy.budget_enforcer.arn
}


data "aws_iam_policy_document" "block_ecs" {
  statement {
    effect = "Deny"
    actions = [
      "ecs:RunTask",
      "ecs:StartTask",
      "ecs:CreateService",
      "ecs:UpdateService"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "block_ecs" {
  name   = "block-ecs"
  policy = data.aws_iam_policy_document.block_ecs.json
}


resource "aws_budgets_budget_action" "ecs_shutdown" {
  budget_name        = aws_budgets_budget.ecs.name
  action_type        = "APPLY_IAM_POLICY"
  approval_model     = "AUTOMATIC"
  notification_type = "FORECASTED"
  execution_role_arn = aws_iam_role.budget_enforcer.arn

  action_threshold {
    action_threshold_type  = "ABSOLUTE_VALUE"
    action_threshold_value = 1
  }

  definition {
    iam_action_definition {
      policy_arn = aws_iam_policy.block_ecs.arn
      roles      = [aws_iam_role.budget_enforcer.name]
    }
  }

  subscriber {
    address           = var.email
    subscription_type = "EMAIL"
  }
}

resource "aws_appautoscaling_target" "ecs" {
    max_capacity       = 2
    min_capacity       = 0
    resource_id        = var.ecs_id
    scalable_dimension = "ecs:service:DesiredCount"
    service_namespace  = "ecs"
}

resource "aws_appautoscaling_scheduled_action" "night_off" {
  name = "ecs-night-off"
  service_namespace = aws_appautoscaling_target.ecs.service_namespace
  resource_id = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension

  schedule           = "cron(0 22 * * ? *)"

  scalable_target_action {
    min_capacity = 0
    max_capacity = 0
  }
}

resource "aws_appautoscaling_scheduled_action" "ecs_morning_on" {
  name               = "ecs-morning-on"
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  schedule           = "cron(0 8 * * ? *)"

  scalable_target_action {
    min_capacity = 1
    max_capacity = 1
  }
}
