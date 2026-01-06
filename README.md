### Terraform ECS Platform
This repository contains Terraform code to provision a complete AWS ECS Fargate platform for a containerized application. It includes everything from the network layer (VPC, subnets, route tables and NAT Gateway) up through an application load balancer, ECS cluster, Amazon ECR for container images and an Amazon RDS database. The sample application under image/ is a small FastAPI
 service backed by PostgreSQL, but you can swap in any containerized workload.

## Key features:
  * Modular design – reusable Terraform modules for networking, ECS, load balancer, database, DNS, SSL certificate, ECR, observability and cost guardrails. Each module is self‑contained with clearly defined inputs and outputs.
  * Production‑ready network – a VPC spanning two Availability Zones, with public subnets for the ALB and private subnets for ECS tasks and the database.
  * Application load balancing – an AWS Application Load Balancer with HTTP→HTTPS redirection, listeners on 443 and a target group on port 8080.
  * ECS Fargate service – the ECS module provisions a Fargate cluster, task definition and service. It creates an execution role with least‑privilege policies and configures CloudWatch Logs. The service is registered with the ALB and runs the container with environment variables and Secrets Manager integration.
  * Amazon RDS database – a module for creating a PostgreSQL instance with its own security group and database subnet group. Outputs include the Secrets Manager ARN and connection details which feed into the ECS task.
  * Secure container registry – an ECR repository with immutable tags and scan‑on‑push enabled to store your application images.
  * DNS and ACM – Route 53 zone creation, SSL certificate issuance and validation, and DNS records for the load balancer.
  * Observability – optional CloudWatch alarm module that triggers an SNS email when ECS CPU utilization exceeds a threshold.
  * Cost guardrails – optional budget and scheduled actions to cap monthly ECS spend and automatically scale the service down at night.
  * Remote state – a separate bootstrapping module for creating an S3 bucket and DynamoDB table to store Terraform state and manage locking.

## Project structure

```text
. 
├── .github/workflows/      # GitHub Actions workflows  
├── DNS-Boostrap/           # Route 53 zone creation (one-time)  
├── bootstrap/              # Remote state backend (S3 + DynamoDB)  
├── image/                  # Sample FastAPI application  
│   ├── Dockerfile  
│   ├── requirements.txt  
│   └── api/
├── modules/                # Terraform reusable modules  
│   ├── acm/  
│   ├── alb/  
│   ├── db/  
│   ├── dns/  
│   ├── ecr/  
│   ├── ecs/  
│   ├── network/  
│   └── observability/  
└── live/                   # Environment configurations  
    └── dev/
```


Prerequisites

Terraform ≥ 1.3 and the AWS CLI installed.

An AWS account with permissions to provision the resources listed above.

A registered domain for DNS and SSL (default is veliacr.com). You can change this via the domain variable.

For remote state, you should bootstrap the S3 bucket and DynamoDB table once before running the rest of the modules.

Bootstrapping the backend and DNS zone

Configure your AWS CLI credentials (e.g. via aws configure).

Create the remote state backend:

cd bootstrap
terraform init
terraform apply -var="region=us-east-1" -var="environment=dev"


This creates an encrypted S3 bucket and DynamoDB table. Update your backend configuration in other modules to point to this bucket.

(Optional) Create the initial Route 53 hosted zone:

cd DNS-Boostrap
terraform init
terraform apply -var="domain=example.com" -var="region=us-east-1"


Note down the nameservers output and update your domain’s registrar to use these name servers. After the zone is delegated, you no longer need to run this directory.

Deploying an environment

The live/dev folder demonstrates how to assemble the modules into a working environment. It expects values such as the AWS region, environment name, application name and contact email.

Change into the environment directory:

cd live/dev


Edit variables.tf if you need to override defaults. For example:

environment – dev/stage/prod.

region – AWS region (e.g. us-east-1).

domain – your domain name.

app_name – used to name resources, the ECS task family and ECR repository.

email – used for notifications (CloudWatch alarms and budgets).

Initialize and apply:

terraform init
terraform plan
terraform apply -var="app_name=quiz-app" -var="email=you@example.com"


Terraform will output values such as the ECR repository URL, ECS cluster name and ECS service name.

Building and pushing the application image

The sample service under image/ is a small FastAPI app that exposes a /health endpoint and CRUD operations for quiz questions and choices. To build and push it:

# Build the image locally
cd image
docker build -t <account-id>.dkr.ecr.<region>.amazonaws.com/<repo-name>:v1 .

# Authenticate and push
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com

docker push <account-id>.dkr.ecr.<region>.amazonaws.com/<repo-name>:v1


Where <repo-name> is the ECR repository created by the jean_ecr_module (see terraform output). After pushing, update the tag or repository URL in your Terraform variables if needed.

Module details
Module	Purpose	Key inputs (variables)	Key outputs
network	Creates a VPC across two Availability Zones with public/private/database subnets, NAT Gateway and tags.	region, environment, vpc_cidr, az_count, newbits	vpc_id, public_subnets, private_subnets, database_subnet_group
acm	Requests an AWS ACM certificate for a given domain. Validation is performed via DNS.	domain, common_tags	certificate_arn, domain_validation_options
alb	Creates an Application Load Balancer with HTTP→HTTPS redirect and a default target group on port 8080. Public security group rules allow inbound HTTP/HTTPS.	environment, region, vpc_id, subnets, vpc_cidr, certificate	alb_arn, alb_dns_name, alb_zone_id, alb_sg_id, target_group_arn
ecr	Sets up an ECR repository with immutable tags and scan on push.	app_name, environment, region, common_tags	repository_url, arn
ecs	Provisions an ECS Fargate cluster, task definition and service. Defines an execution role, CloudWatch log group, security group and attaches the service to the load balancer. Passes Secrets Manager secret and environment variables to the container.	app_name, environment, region, common_tags, target_group_arn, private_subnets, vpc_id, alb_sg_id, ecr_repository_url, db_master_secret_arn, db_host, db_name	ecs_sg_id, ecs_cluster_name, ecs_service_name, ecs_autoscaling_resource_id
db	Creates a PostgreSQL database instance using the terraform-aws-modules/rds module, along with a dedicated security group.	environment, region, vpc_id, ecs_sg_id, private_subnets, db_subnet_name	db_master_secret_arn, db_host, db_name
dns	Uses Route 53 to create alias records for the ALB and validation records for the ACM certificate.	domain, alb_dns_name, alb_zone_id, dvo	name_servers, zone_id, validation_record_fqdns
observability	Sets up a CloudWatch alarm on ECS CPU utilization and an SNS topic/subscription to send email notifications.	environment, app_name, cluster_name, service_name, email	(no explicit outputs)
cost_guardrails	Implements a monthly AWS Budget on ECS service usage. It also creates IAM policies and scheduled actions to automatically scale the service to zero at night (22:00) and back to one at 08:00.	email, ecs_id	(no explicit outputs)
Observability & cost control

CloudWatch alarms – CPU utilization alarms are configured at 90 % by default. Alerts are sent via SNS to the email specified in variables.tf.

AWS Budgets – A budget of 1 USD per month is set for ECS. When the forecasted cost exceeds 100 % of the threshold, Terraform attaches an IAM policy to deny scaling actions. Scheduled autoscaling actions shut the service off overnight to save costs.

Cleaning up

To avoid ongoing charges, destroy resources when you are finished:

cd live/dev
terraform destroy -var="app_name=quiz-app" -var="email=you@example.com"


Remember to also empty and delete the S3 bucket and DynamoDB table from the bootstrap module when you no longer need the state backend.

Notes

The FastAPI sample includes migration logic and uses an Alembic directory under image/api/. On container startup it waits for PostgreSQL, runs migrations, and then serves traffic on port 8080.

Adjust CPU/memory and desired task counts in the ecs module if your workload requires more resources.

You can create additional environments (e.g., stage or prod) by copying live/dev to live/stage and adjusting variables.

This repository does not include CI/CD pipelines. Use GitHub Actions or your preferred tool to build, push and deploy images using the outputs provided.

me gusta TODO ESTA EXCELENTE, solo te falto leer los workflows

He revisado los workflows en .github/workflows y he actualizado el README para incluir una sección específica sobre la integración continua y los entornos de previsualización. Ahora se explica cómo el workflow Deploy crea un entorno temporal con Terraform, compila y sube la imagen a ECR y escala el servicio, y cómo el workflow Destroy PR Infra elimina los recursos cuando se cierra el pull request. También he actualizado la descripción de la carpeta de workflows y la nota sobre CI/CD en el documento.

Aquí tienes la versión actualizada del README:

Terraform ECS Platform
Overview

This repository contains Terraform code to provision a complete AWS ECS Fargate platform for a containerized application. It includes everything from the network layer (VPC, subnets, route tables and NAT Gateway) up through an application load balancer, ECS cluster, Amazon ECR for container images and an Amazon RDS database. The sample application under image/ is a small FastAPI
 service backed by PostgreSQL, but you can swap in any containerized workload.

Key features:

Modular design – reusable Terraform modules for networking, ECS, load balancer, database, DNS, SSL certificate, ECR, observability and cost guardrails. Each module is self‑contained with clearly defined inputs and outputs.

Production‑ready network – a VPC spanning two Availability Zones, with public subnets for the ALB and private subnets for ECS tasks and the database.

Application load balancing – an AWS Application Load Balancer with HTTP→HTTPS redirection, listeners on 443 and a target group on port 8080.

ECS Fargate service – the ECS module provisions a Fargate cluster, task definition and service. It creates an execution role with least‑privilege policies and configures CloudWatch Logs. The service is registered with the ALB and runs the container with environment variables and Secrets Manager integration.

Amazon RDS database – a module for creating a PostgreSQL instance with its own security group and database subnet group. Outputs include the Secrets Manager ARN and connection details which feed into the ECS task.

Secure container registry – an ECR repository with immutable tags and scan‑on‑push enabled to store your application images.

DNS and ACM – Route 53 zone creation, SSL certificate issuance and validation, and DNS records for the load balancer.

Observability – optional CloudWatch alarm module that triggers an SNS email when ECS CPU utilization exceeds a threshold.

Cost guardrails – optional budget and scheduled actions to cap monthly ECS spend and automatically scale the service down at night.

Remote state – a separate bootstrapping module for creating an S3 bucket and DynamoDB table to store Terraform state and manage locking.

Project structure
.  
├── .github/workflows/            # GitHub Actions workflows for provisioning and destroying PR infrastructure  
├── DNS-Boostrap/                # initial Route 53 zone creation (one‑time)  
├── bootstrap/                   # S3/DynamoDB backend for remote state  
├── image/                       # sample FastAPI application (Dockerfile, code)  
│   ├── Dockerfile  
│   ├── requirements.txt  
│   └── api/ (main.py, models.py, database.py, Alembic migrations, etc.)  
├── modules/                     # reusable Terraform modules  
│   ├── acm/                    # ACM certificate creation
│   ├── alb/                    # Application Load Balancer
│   ├── cost_guardrails/        # budget and scheduled shutdown
│   ├── db/                     # Amazon RDS (PostgreSQL)
│   ├── dns/                    # Route 53 records for ALB and validation
│   ├── ecr/                    # ECR repository
│   ├── ecs/                    # ECS cluster, task definition and service
│   ├── network/                # VPC, subnets, NAT, database subnet group
│   └── observability/         # CloudWatch alarm and SNS notification
├── live/                       # environment configurations
│   └── dev/                   # example development environment
│       ├── main.tf            # pulls modules together
│       ├── variables.tf       # environment variables (region, domain, tags…)
│       └── outputs.tf         # exposes useful outputs such as ECR URL, cluster name
└── .gitignore

Prerequisites

Terraform ≥ 1.3 and the AWS CLI installed.

An AWS account with permissions to provision the resources listed above.

A registered domain for DNS and SSL (default is veliacr.com). You can change this via the domain variable.

For remote state, you should bootstrap the S3 bucket and DynamoDB table once before running the rest of the modules.

Bootstrapping the backend and DNS zone

Configure your AWS CLI credentials (e.g. via aws configure).

Create the remote state backend:

cd bootstrap
terraform init
terraform apply -var="region=us-east-1" -var="environment=dev"


This creates an encrypted S3 bucket and DynamoDB table. Update your backend configuration in other modules to point to this bucket.

(Optional) Create the initial Route 53 hosted zone:

cd DNS-Boostrap
terraform init
terraform apply -var="domain=example.com" -var="region=us-east-1"


Note down the nameservers output and update your domain’s registrar to use these name servers. After the zone is delegated, you no longer need to run this directory.

Deploying an environment

The live/dev folder demonstrates how to assemble the modules into a working environment. It expects values such as the AWS region, environment name, application name and contact email.

Change into the environment directory:

cd live/dev


Edit variables.tf if you need to override defaults. For example:

environment – dev/stage/prod.

region – AWS region (e.g. us-east-1).

domain – your domain name.

app_name – used to name resources, the ECS task family and ECR repository.

email – used for notifications (CloudWatch alarms and budgets).

Initialize and apply:

terraform init
terraform plan
terraform apply -var="app_name=quiz-app" -var="email=you@example.com"


Terraform will output values such as the ECR repository URL, ECS cluster name and ECS service name.

Building and pushing the application image

The sample service under image/ is a small FastAPI app that exposes a /health endpoint and CRUD operations for quiz questions and choices. To build and push it:

# Build the image locally
cd image
docker build -t <account-id>.dkr.ecr.<region>.amazonaws.com/<repo-name>:v1 .

# Authenticate and push
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com

docker push <account-id>.dkr.ecr.<region>.amazonaws.com/<repo-name>:v1


Where <repo-name> is the ECR repository created by the jean_ecr_module (see terraform output). After pushing, update the tag or repository URL in your Terraform variables if needed.

Module details
Module	Purpose	Key inputs (variables)	Key outputs
network	Creates a VPC across two Availability Zones with public/private/database subnets, NAT Gateway and tags.	region, environment, vpc_cidr, az_count, newbits	vpc_id, public_subnets, private_subnets, database_subnet_group
acm	Requests an AWS ACM certificate for a given domain. Validation is performed via DNS.	domain, common_tags	certificate_arn, domain_validation_options
alb	Creates an Application Load Balancer with HTTP→HTTPS redirect and a default target group on port 8080. Public security group rules allow inbound HTTP/HTTPS.	environment, region, vpc_id, subnets, vpc_cidr, certificate	alb_arn, alb_dns_name, alb_zone_id, alb_sg_id, target_group_arn
ecr	Sets up an ECR repository with immutable tags and scan on push.	app_name, environment, region, common_tags	repository_url, arn
ecs	Provisions an ECS Fargate cluster, task definition and service. Defines an execution role, CloudWatch log group, security group and attaches the service to the load balancer. Passes Secrets Manager secret and environment variables to the container.	app_name, environment, region, common_tags, target_group_arn, private_subnets, vpc_id, alb_sg_id, ecr_repository_url, db_master_secret_arn, db_host, db_name	ecs_sg_id, ecs_cluster_name, ecs_service_name, ecs_autoscaling_resource_id
db	Creates a PostgreSQL database instance using the terraform-aws-modules/rds module, along with a dedicated security group.	environment, region, vpc_id, ecs_sg_id, private_subnets, db_subnet_name	db_master_secret_arn, db_host, db_name
dns	Uses Route 53 to create alias records for the ALB and validation records for the ACM certificate.	domain, alb_dns_name, alb_zone_id, dvo	name_servers, zone_id, validation_record_fqdns
observability	Sets up a CloudWatch alarm on ECS CPU utilization and an SNS topic/subscription to send email notifications.	environment, app_name, cluster_name, service_name, email	(no explicit outputs)
cost_guardrails	Implements a monthly AWS Budget on ECS service usage. It also creates IAM policies and scheduled actions to automatically scale the service to zero at night (22:00) and back to one at 08:00.	email, ecs_id	(no explicit outputs)
CI/CD & GitHub Actions

This repository includes two GitHub Actions workflows under .github/workflows that automatically spin up and tear down preview environments for pull requests:

Deploy (main.yml) – triggered when a pull request is opened, synchronized or reopened. The workflow:

Assumes an AWS IAM role using GitHub’s OIDC provider and installs Terraform.

Initializes Terraform in live/dev, selects or creates a workspace derived from the pull request number and runs terraform plan and apply with an environment variable unique to the PR.

Retrieves outputs such as the ECR repository URL and ECS cluster/service names.

Logs into ECR and builds/pushes the application image from the image/ directory, tagging it with both v1 and the commit SHA.

Scales the ECS service to run one Fargate task and waits until the service is stable.

Optionally performs a health check on the deployed domain via the wait_for_response action.

Destroy PR Infra (destroy-infra.yml) – triggered when a pull request is closed. It:

Selects the corresponding Terraform workspace for the PR.

Retrieves the ECR repository name and deletes all images in it.

Runs terraform destroy with the PR’s environment to remove all AWS resources.

Deletes the temporary workspace, ensuring no stray resources remain.

These workflows provide self‑service preview environments for each pull request and automatically clean up when the work is finished, reducing manual overhead and avoiding orphaned infrastructure.

Observability & cost control

CloudWatch alarms – CPU utilization alarms are configured at 90 % by default. Alerts are sent via SNS to the email specified in variables.tf.

AWS Budgets – A budget of 1 USD per month is set for ECS. When the forecasted cost exceeds 100 % of the threshold, Terraform attaches an IAM policy to deny scaling actions. Scheduled autoscaling actions shut the service off overnight to save costs.

Cleaning up

To avoid ongoing charges, destroy resources when you are finished:

cd live/dev
terraform destroy -var="app_name=quiz-app" -var="email=you@example.com"


Remember to also empty and delete the S3 bucket and DynamoDB table from the bootstrap module when you no longer need the state backend.

Notes

The FastAPI sample includes migration logic and uses an Alembic directory under image/api/. On container startup it waits for PostgreSQL, runs migrations, and then serves traffic on port 8080.

Adjust CPU/memory and desired task counts in the ecs module if your workload requires more resources.

You can create additional environments (e.g., stage or prod) by copying live/dev to live/stage and adjusting variables.

Continuous integration and deployment are handled via GitHub Actions workflows located in .github/workflows. These workflows build and push the application image, provision infrastructure for each pull request and destroy it when the PR is closed.
