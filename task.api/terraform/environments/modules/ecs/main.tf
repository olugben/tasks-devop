# =====================================================
# ECS MODULE
# modules/ecs/main.tf
# =====================================================

resource "aws_ecs_cluster" "this" {
  name = var.app_name
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.app_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn      = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name  = var.app_name
      image = var.image_url

      portMappings = [
        {
          containerPort = var.container_port
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = var.app_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn

  launch_type      = "FARGATE"
  platform_version = "LATEST"
  desired_count    = 1

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [var.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.app_name
    container_port   = var.container_port
  }

  depends_on = [
    aws_ecs_task_definition.this
  ]
}