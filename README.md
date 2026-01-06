### Terraform ECS Platform
This repository contains Terraform code to provision a complete AWS ECS Fargate platform for a containerized application. It includes everything from the network layer (VPC, subnets, route tables and NAT Gateway) up through an application load balancer, ECS cluster, Amazon ECR for container images and an Amazon RDS database. The sample application under image/ is a small FastAPI
 service backed by PostgreSQL, but you can swap in any containerized workload.

Key features:
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


## Prerequisites

 * __Terraform ≥ 1.3__ and the AWS CLI installed.
 * An __AWS account__ with permissions to provision the resources listed above.
 * A __registered domain__ for DNS and SSL (default is `veliacr.com`). You can change this via the `domain` variable.
 * For remote state, you should bootstrap the S3 bucket and DynamoDB table once before running the rest of the modules.

## Bootstrapping the backend and DNS zone

 1. Configure your AWS CLI credentials (e.g. via aws configure).
 2. Create the remote state backend:
```text
cd bootstrap
terraform init
terraform apply -var="region=us-east-1" -var="environment=dev"
```

This creates an encrypted S3 bucket and DynamoDB table. Update your backend configuration in other modules to point to this bucket.

 1. (Optional) Create the initial Route 53 hosted zone:
```text
cd DNS-Boostrap
terraform init
terraform apply -var="domain=example.com" -var="region=us-east-1"
```

Note down the nameservers output and update your domain’s registrar to use these name servers. After the zone is delegated, you no longer need to run this directory.

## Deploying an environment

The live/dev folder demonstrates how to assemble the modules into a working environment. It expects values such as the AWS region, environment name, application name and contact email.

 1. Change into the environment directory:
```
cd live/dev
```

 2. Edit variables.tf if you need to override defaults. For example:
  * ```environment``` – dev/stage/prod.
  * ```region``` – AWS region (e.g. us-east-1).
  * ```domain``` – your domain name.
  * ```app_name``` – used to name resources, the ECS task family and ECR repository.
  * ```email``` – used for notifications (CloudWatch alarms and budgets).

### Initialize and apply:
```text
terraform init
terraform plan
terraform apply -var="app_name=quiz-app" -var="email=you@example.com"
```

Terraform will output values such as the ECR repository URL, ECS cluster name and ECS service name.

## Building and pushing the application image

The sample service under image/ is a small FastAPI app that exposes a /health endpoint and CRUD operations for quiz questions and choices. To build and push it:
```
# Build the image locally
cd image
docker build -t <account-id>.dkr.ecr.<region>.amazonaws.com/<repo-name>:v1 .
```
```
# Authenticate and push
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/<repo-name>:v1
```

Where ```<repo-name> ``` is the ECR repository created by the ```jean_ecr_module``` (see terraform output). After pushing, update the tag or repository URL in your Terraform variables if needed.

## Module Details

| Module | Purpose | Key Inputs (Variables) | Key Outputs |
|------|-------|------------------------|-------------|
| **network** | Creates an AWS VPC across two Availability Zones with public, private, and database subnets. Includes NAT Gateway configuration and unified resource tagging. | `region`, `environment`, `vpc_cidr`, `az_count`, `newbits` | `vpc_id`, `public_subnets`, `private_subnets`, `database_subnet_group` |
| **acm** | Requests an AWS ACM SSL certificate for a given domain. Validation is performed via DNS records. | `domain`, `common_tags` | `certificate_arn`, `domain_validation_options` |
| **alb** | Provisions an AWS Application Load Balancer with HTTP to HTTPS redirection and a default target group on port 8080. Configures ALB security groups for inbound web traffic. | `environment`, `region`, `vpc_id`, `subnets`, `vpc_cidr`, `certificate` | `alb_arn`, `alb_dns_name`, `alb_zone_id`, `alb_sg_id`, `target_group_arn` |
| **ecr** | Sets up an Amazon ECR repository with immutable image tags and scan-on-push enabled. | `app_name`, `environment`, `region`, `common_tags` | `repository_url`, `arn` |
| **ecs** | Provisions an ECS Fargate cluster, task definition, and service. Defines execution roles, CloudWatch log groups, ECS security groups, and ALB attachment. Passes Secrets Manager and environment variables to containers. | `app_name`, `environment`, `region`, `common_tags`, `target_group_arn`, `private_subnets`, `vpc_id`, `alb_sg_id`, `ecr_repository_url`, `db_master_secret_arn`, `db_host`, `db_name` | `ecs_sg_id`, `ecs_cluster_name`, `ecs_service_name`, `ecs_autoscaling_resource_id` |
| **db** | Creates a PostgreSQL database instance using terraform-aws-modules/rds with a dedicated database security group and private subnet placement. | `environment`, `region`, `vpc_id`, `ecs_sg_id`, `private_subnets`, `db_subnet_name` | `db_master_secret_arn`, `db_host`, `db_name` |
| **dns** | Uses Amazon Route 53 to create alias A records for the ALB and DNS records required for ACM certificate validation. | `domain`, `alb_dns_name`, `alb_zone_id`, `dvo` | `name_servers`, `zone_id`, `validation_record_fqdns` |
| **observability** | Configures CloudWatch alarms on ECS CPU utilization and creates SNS topic subscriptions to send email notifications. | `environment`, `app_name`, `cluster_name`, `service_name`, `email` | (no explicit outputs) |
| **cost_guardrails** | Implements AWS Budgets and scheduled autoscaling actions to scale ECS service down at night (22:00) and back up in the morning (08:00) to reduce costs. | `email`, `ecs_id` | (no explicit outputs) |

## CI/CD & GitHub Actions

This repository includes two GitHub   Actions workflows under .github/workflows that
automatically spin up and tear down preview environments for pull requests:

 1. Deploy (```main.yml```) – triggered when a pull request is opened, synchronized or reopened. The workflow:
   * Assumes an AWS IAM role using GitHub’s OIDC provider and installs Terraform.
   * Initializes Terraform in live/dev , selects or creates a workspace derived from the pull request number and runs terraform plan and apply with an environment variable unique to the PR.
   * Retrieves outputs such as the ECR repository URL and ECS cluster/service names.
   * Logs into ECR and builds/pushes the application image from the image/ directory, tagging it with both v1 and the commit SHA.
   * Scales the ECS service to run one Fargate task and waits until the service is stable.
   * Optionally performs a health check on the deployed domain via the wait_for_response action.
     
 2. Destroy PR Infra (```destroy-infra.yml```) – triggered when a pull request is closed. The Worfkflow:
   * Selects the corresponding Terraform workspace for the PR.
   * Retrieves the ECR repository name and deletes all images in it.
   * Runs terraform destroy with the PR’s environment to remove all AWS resources.
   * Deletes the temporary workspace, ensuring no stray resources remain.

These workflows provide self‑service preview environments for each pull request and automatically clean up when the work is finished, reducing manual overhead and avoiding orphaned infrastructure.

## Observability & cost control

 * __CloudWatch alarms__ – CPU utilization alarms are configured at 90 % by default. Alerts are sentvia SNS to the email specified in variables.tf .
 * __AWS Budgets__ – A budget of 1 USD per month is set for ECS. When the forecasted cost exceeds 100 % of the threshold, Terraform attaches an IAM policy to deny scaling actions. Scheduled autoscaling actions shut the service off overnight to save costs.

## Cleaning up

To avoid ongoing charges, destroy resources when you are finished:

```
cd live/dev
terraform destroy -var="app_name=quiz-app" -var="email=you@example.com"
```

Remember to also empty and delete the S3 bucket and DynamoDB table from the bootstrap module when you no longer need the state backend.

## Notes

 * The FastAPI sample includes migration logic and uses an Alembic directory under ```image/api/ ```.
 * On container startup it waits for PostgreSQL, runs migrations, and then serves traffic onport 8080.
 * Adjust CPU/memory and desired task counts in the ```ecs``` module if your workload requires moreresources.
 * You can create additional environments (e.g., ```stage``` or ```prod``` ) by copying ```live/dev``` to ```live/stage``` and adjusting variables.
 * Continuous integration and deployment are handled via GitHub Actions workflows located in ```.github/workflows``` .These workflows build and push the application image, provision infrastructure for each pull request and destroy it when the PR is closed
