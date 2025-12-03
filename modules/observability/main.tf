terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = ">=5.0.0" 
    }
  }
}

resource "aws_sns_topic" "cpu_alarm" {
  name = "cpu-sns-topic"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.cpu_alarm.arn
  protocol = "email"
  endpoint = var.email

}
module "metric_alarm" {
    source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
    version = "~> 3.0"

    alarm_name = format("%s-%s-Alarm-CPU-Utilization", var.environment, var.app_name)
    alarm_description = ""
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods = 3
    threshold = 90
    period = 60
    unit = "Percent"

    namespace   = "AWS/ECS"
    metric_name = "CPUUtilization"
    dimensions = {
      ClusterName = var.cluster_name
      ServiceName = var.service_name
    }
    statistic   = "Average"

    alarm_actions = [aws_sns_topic.cpu_alarm.arn]





}