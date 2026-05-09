# Task API — Production-Ready DevOps Deployment

A Spring Boot Task Management REST API containerized with Docker and deployed to AWS ECS Fargate using a fully automated GitHub Actions CI/CD pipeline and modular Terraform infrastructure.

---

##  Table of Contents

- [Architecture Overview](#architecture-overview)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
- [Infrastructure Deployment (Terraform)](#infrastructure-deployment-terraform)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring & Logging](#monitoring--logging)
- [Design Decisions](#design-decisions)
- [Assumptions Made](#assumptions-made)
- [Limitations & Future Improvements](#limitations--future-improvements)

---

##  Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                            GitHub                                     │
│                                                                       │
│   Push to main ──► GitHub Actions Pipeline                           │
│                          │                                            │
│           ┌──────────────┼──────────────────┐                        │
│           ▼              ▼                  ▼                         │
│      [build job]    [test job]        [docker job]                   │
│      Maven build    Maven test        Docker build                   │
│      Upload JAR     (needs build)     Trivy scan                     │
│                                       Push to Docker Hub             │
│                                            │                          │
│                                       [deploy job]                   │
│                                       │
└──────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼ (when enabled)
┌──────────────────────── AWS (eu-west-1) — Terraform ────────────────┐
│                                                                       │
│   ┌────────────────────────────────────────────────────────────┐     │
│   │                     Custom VPC (10.0.0.0/16)               │     │
│   │                                                            │     │
│   │    Public Subnets                  Private Subnets         │     │
│   │  ┌──────────────────┐           ┌──────────────────────┐  │     │
│   │  │  ALB             │ ────────► │  ECS Fargate         │  │     │
│   │  │  (port 80)       │           │  (task-api, port 8080)│  │     │
│   │  └──────────────────┘           └──────────┬───────────┘  │     │
│   │                                            │               │     │
│   │                               ┌────────────▼───────────┐  │     │
│   │                               │   CloudWatch Log Group  │  │     │
│   │                               │   /ecs/task-api         │  │     │
│   │                               └────────────────────────┘  │     │
│   │                                                            │     │
│   │   ECR Repository    IAM Roles & Policies                   │     │
│   └────────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────────┘
```

**Key points:**
- ECS tasks run in **private subnets** — never directly exposed to the internet
- All public traffic enters through the **ALB** in public subnets
- Container images are stored dockerhub but  in production it will be in  **AWS ECR** (provisioned by Terraform)
- The CI/CD pipeline pushes to **Docker Hub** during this challenge; ECR integration is ready via Terraform for production use
- Container logs stream automatically to **CloudWatch Logs**

---

##  Tech Stack

| Layer | Technology |
|---|---|
| Application | Java 21 / Spring Boot |
| Build Tool | Apache Maven |
| Containerization | Docker (multi-stage build) |
| Container Registry | Docker Hub (CI/CD) / AWS ECR (Terraform-provisioned) |
| CI/CD | GitHub Actions |
| Security Scanning | Trivy (image vulnerability scanning) |
| Infrastructure as Code | Terraform (modular) |
| Cloud Provider | AWS (eu-west-1) |
| Compute | ECS Fargate (serverless) |
| Networking | VPC, Public & Private Subnets, Security Groups |
| Load Balancing | AWS ALB (Application Load Balancer) |
| IAM | AWS IAM Roles & Policies |
| Monitoring / Logging | AWS CloudWatch Logs |
| Local Development | Docker Compose + PostgreSQL |

---

##  Project Structure

```
.
├── task.api/                        # Spring Boot application
│   ├── src/
│   │   ├── main/java/...
│   │   └── test/java/...
│   ├── pom.xml
│   └── Dockerfile                   # Multi-stage build (Maven → JRE Alpine)
│
├── docker-compose.yml               # Local dev: app + PostgreSQL
│
├── terraform/
│   ├── environments/
│   │   └── dev/
│   │       └── main.tf              # Root config — wires all modules together
│   └── modules/
│       ├── vpc/                     # VPC, public/private subnets, IGW, SGs
│       ├── ecr/                     # Elastic Container Registry repository
│       ├── iam/                     # ECS task execution role & policies
│       ├── cloudwatch/              # CloudWatch log group
│       ├── alb/                     # Application Load Balancer + target group
│       └── ecs/                     # ECS cluster, task definition, service
│
└── .github/
    └── workflows/
        └── main.yml               # CI/CD pipeline definition
```

---

## Prerequisites

- **AWS CLI** configured (`aws configure`)
- **Terraform** >= 1.3.0
- **Docker** installed and running
- **Java 21** and **Maven** (for local builds outside Docker)
- **Docker Hub account** with a repository named `task-api`
- GitHub repository with the following **Secrets** configured:

| Secret | Description |
|---|---|
| `DOCKER_USERNAME` | Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub access token |
| `AWS_ACCESS_KEY_ID` | AWS IAM access key |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret key |

---

##  Local Development

The application runs locally with Docker Compose, which starts both the Spring Boot app and a PostgreSQL 16 database.

### 1. Clone the Repository

```bash
git clone https://github.com/olugben/tasks-devop
cd tasks-devop/task.api
```
An example is included in the repository. Please note that the .env file is strictly for testing purposes — we never store credentials in plain text or within .env. And absolutely do not commit it, not even as .env.example.
### 2. Create a `.env` file

```env
POSTGRES_USER=taskuser
POSTGRES_PASSWORD=taskpassword
POSTGRES_DB=taskdb
SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/taskdb
SPRING_DATASOURCE_USERNAME=taskuser
SPRING_DATASOURCE_PASSWORD=taskpassword
```
### 3. Start the stack
Make sure the docker  service is running before the following command
```bash
docker compose up --build
```

This will:
- Start PostgreSQL on host port `5435` → container port `5432`
- Wait for the database health check (`pg_isready`) to pass
- Build and start the Spring Boot app on port `8080`
- Verify app health via `/actuator/health`

### 4. Test the API

```bash
curl http://localhost:8080/actuator/health
```

### 5. Stop the stack

```bash
docker compose down
```

> Persistent data is stored in the `db_data` Docker volume and survives container restarts.

---

##  Infrastructure Deployment (Terraform)

The Terraform configuration is fully modular. Each AWS concern is isolated in its own reusable module under `terraform/modules/`, and wired together in `terraform/environments/dev/main.tf`.

### Modules

| Module | What it provisions |
|---|---|
| `vpc` | Custom VPC (`10.0.0.0/16`), public & private subnets, Internet Gateway, route tables, security groups |
| `ecr` | ECR repository to store Docker images |
| `iam` | `ecsTaskExecutionRole` — grants ECS permission to pull images and write logs to CloudWatch |
| `cloudwatch` | CloudWatch log group `/ecs/task-api` |
| `alb` | Application Load Balancer in public subnets, target group, HTTP listener |
| `ecs` | ECS cluster, Fargate task definition (with CloudWatch log driver configured), ECS service linked to ALB |

### Deploy

```bash
cd terraform/environments/dev

# Initialise providers and modules
terraform init

# Preview changes
terraform plan

# Provision all infrastructure
terraform apply
```

### Destroy

```bash
terraform destroy
```

---

## ⚙️ CI/CD Pipeline

The pipeline is defined in `.github/workflows/main.yml` and triggers automatically on every push to `main`. It is structured as four separate jobs to isolate failures clearly.

```
Push to main
     │
     ▼
┌──────────────────────────────────────────────────┐
│  build                                           │
│  • Checkout code                                 │
│  • Set up Java 21 (Temurin distribution)         │
│  • Cache Maven dependencies (~/.m2)              │
│  • mvn clean package -DskipTests                 │
│  • Upload JAR as GitHub Actions artifact         │
└───────────────────┬──────────────────────────────┘
                    │ needs: build
                    ▼
┌──────────────────────────────────────────────────┐
│  test                                            │
│  • Checkout code                                 │
│  • Set up Java 21 (Temurin distribution)         │
│  • Cache Maven dependencies                      │
│  • mvn test                                      │
└───────────────────┬──────────────────────────────┘
                    │ needs: test
                    ▼
┌──────────────────────────────────────────────────┐
│  docker                                          │
│  • Checkout code                                 │
│  • Build Docker image                            │
│  • Scan image with Trivy                         │
│    (severity: HIGH, CRITICAL)                    │
│    (ignore-unfixed: true, exit-code: 0)          │
│  • Login to Docker Hub                           │
│  • Push image to Docker Hub                      │
└───────────────────┬──────────────────────────────┘
                    │ needs: docker    if: false
                    ▼
┌──────────────────────────────────────────────────┐
│  deploy  — CURRENTLY DISABLED                    │
│  • Configure AWS credentials (eu-west-1)         │
│  • aws ecs update-service                        │
│    --cluster task-api-cluster                    │
│    --service task-api-service                    │
│    --force-new-deployment                        │
└──────────────────────────────────────────────────┘
```

### Notable pipeline decisions

**Separate jobs for build and test** — compiling and testing are separate jobs with an explicit `needs` dependency. This keeps concerns separated: a test failure is immediately distinguishable from a build failure in the GitHub Actions UI.

**Maven dependency caching** — the `~/.m2` directory is cached using the `pom.xml` file hash as the cache key. This avoids re-downloading dependencies on every run, significantly reducing pipeline duration.

**Trivy security scanning** — every Docker image is scanned for `HIGH` and `CRITICAL` CVEs before being pushed. `ignore-unfixed: true` filters out vulnerabilities with no available fix . `exit-code: 0` keeps the pipeline non-blocking while still surfacing the report in the Actions log.

**Deploy job disabled (`if: false`)** — the deploy job is fully written and configured but intentionally gated. if you have configured your aws account   you are  requires only to remove `if: false` condition and populating the AWS secrets — no other changes needed.

---

## 📊 Monitoring & Logging

Application logs are streamed to **AWS CloudWatch Logs** via the `awslogs` log driver, which is configured inside the ECS task definition (provisioned by the `cloudwatch` and `ecs` Terraform modules).

**Log group:** 

### View logs

**AWS Console:**
Navigate to `CloudWatch → Log Groups → /ecs/task-api`

**AWS CLI:**
```bash
aws logs tail /ecs/task-api --follow
```

All Spring Boot `stdout` output — startup events, HTTP request logs, errors, and stack traces — is captured automatically without any changes to the application code.

**Local logging (Docker Compose):**
The `app` service uses the `json-file` log driver with rotation (`max-size: 10m`, `max-file: 3`) to prevent unbounded disk growth during local development.

---

##  Design Decisions

**Multi-stage Dockerfile**
The Dockerfile uses a two-stage build. Stage one uses the full `maven:3.9.6-eclipse-temurin-21` image to compile and package the JAR. Stage two uses the minimal `eclipse-temurin:21-jre-alpine` image to run it. This produces a significantly smaller final image with no build tools included.

**Non-root container user**
The Dockerfile creates a dedicated `appuser` and `appgroup`, sets ownership of the JAR, then switches to that user before the entrypoint. Containers run as root by default; this follows the principle of least privilege and reduces risk in the event of a container escape.

**ECS tasks in private subnets**
ECS Fargate tasks are placed in private subnets with no direct internet-facing access. All inbound traffic is routed through the ALB sitting in public subnets. This is the correct production network topology — compute never needs to be directly reachable from the internet.

**Modular Terraform**
Infrastructure is split into six purpose-specific modules: `vpc`, `ecr`, `iam`, `cloudwatch`, `alb`, and `ecs`. Each module exposes clean inputs and outputs. The `environments/dev/main.tf` root wires them together. This makes it straightforward to add a `staging` or `prod` environment by reusing the same modules with different variable values.

**ECR provisioned by Terraform, Docker Hub used in CI**
Terraform provisions an ECR repository as part of the infrastructure definition. During this challenge the CI pipeline pushes to Docker Hub. The switch to ECR in production requires only updating the image URL in the pipeline — the repository is already provisioned.

**Trivy with `exit-code: 0`**
Trivy scans every image before it is pushed, but does not fail the build on detected vulnerabilities. Many CVEs in standard base images have no upstream fix available; blocking on them would halt deployments without providing a resolution path. The scan report remains visible in the Actions log, giving full visibility without blocking delivery.

**Spring Boot Actuator health check in Docker Compose**
The `app` service health check calls `/actuator/health` — the standard Spring Boot readiness endpoint. Combined with `depends_on: db: condition: service_healthy`, this ensures the application container is only marked ready after PostgreSQL is accepting connections and the application itself has fully started.

**Separate CI jobs**
Four jobs with explicit `needs` chains rather than one large job. This gives clear per-stage status in the GitHub Actions UI, allows GitHub to display granular commit status checks, and makes it straightforward to re-run only the failing stage without repeating the entire pipeline.

---

##  Assumptions Made

- The Spring Boot application exposes its API on **port 8080** and has Spring Boot Actuator available at `/actuator/health`
- A single `dev` environment is sufficient for this challenge; the modular Terraform structure is ready for additional environments without duplication
- The Docker image is tagged `latest` for simplicity in this challenge; production deployments should use the Git commit SHA for immutable, traceable tags
- Terraform state is **local** for this challenge; a remote backend (S3 + DynamoDB locking) would be required for any team or production use
- The target AWS region is **eu-west-1** (Ireland)
- The deploy job is intentionally disabled because AWS credentials are not configured; all other pipeline stages run and pass on every push to `main`

---

##  Limitations & Future Improvements

| Area | Current State | Improvement |
|---|---|---|
| Deploy job | Disabled (`if: false`) | Remove condition once AWS credentials are added to GitHub Secrets |
| Container registry | Docker Hub (CI) vs ECR (Terraform) | Unify: push from CI directly to ECR using IAM OIDC — no static keys required |
| Image tagging | `latest` tag only | Tag with Git commit SHA for immutable, fully traceable deployments |
| Terraform state | Local state file | Migrate to S3 backend + DynamoDB locking for team use |
| HTTPS / TLS | HTTP only (port 80) | Add ACM certificate and HTTPS listener on the ALB |
| Database | Local PostgreSQL via Docker Compose | Add an AWS RDS (PostgreSQL) Terraform module for cloud environments |
| Trivy | Non-blocking (`exit-code: 0`) | Switch to `exit-code: 1` once base image CVEs are resolved upstream |
| Monitoring | CloudWatch Logs only | Add CloudWatch Alarms, a metrics dashboard, and SNS alerting |
| Secrets management | `.env` file locally | Use AWS Secrets Manager or Parameter Store for application-level secrets |
| Auto Scaling | Fixed task count | Add ECS Service Auto Scaling policies based on CPU and memory metrics |
| Multi-environment | Single `dev` environment | Add `staging` and `prod` Terraform workspaces or separate state files |
