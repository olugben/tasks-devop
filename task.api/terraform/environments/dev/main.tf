# =====================================================
# ENVIRONMENT ROOT (environments/dev/main.tf)
# =====================================================

module "vpc" {
  source = "../modules/vpc"
  vpc_cidr = "10.0.0.0/16"
}

module "ecr" {
  source   = "../modules/ecr"
  app_name = var.app_name
}

module "iam" {
  source   = "../modules/iam"
  app_name = var.app_name
}

module "cloudwatch" {
  source   = "../modules/cloudwatch"
  app_name = var.app_name
}

module "alb" {
  source         = "../modules/alb"
  app_name       = var.app_name
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
}

variable "aws_region" {
  default = "eu-west-1"
}
module "ecs" {
  source              = "../modules/ecs"
  app_name            = var.app_name
  image_url           = module.ecr.repository_url
  private_subnets     = module.vpc.private_subnets
  container_port      = var.container_port
  execution_role_arn  = module.iam.execution_role_arn
  target_group_arn    = module.alb.target_group_arn
  log_group_name      = module.cloudwatch.log_group_name
  aws_region = var.aws_region
  security_group_id = module.vpc.ecs_security_group_id
}
