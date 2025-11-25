terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = ">= 5.0.0"
    }
  }
}

resource "aws_security_group" "db_sg" {
  name        = format("db-sg-%s", var.environment)
  description = "DB service SG"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_sg_id]
    description     = "ECS - SG"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common_tags
}

module "db" {
  source = "terraform-aws-modules/rds/aws"


  identifier = format("test-%s-db", var.environment)

  engine = "postgres"
  engine_version = "17.6"
  instance_class = "db.t4g.micro"
  allocated_storage = 20
  db_name = "quizapp"
  username = "postgres"
  port = "5432"
  family = "postgres17"


  iam_database_authentication_enabled = false

  db_subnet_group_name = var.db_subnet_name
  subnet_ids = var.private_subnets
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}