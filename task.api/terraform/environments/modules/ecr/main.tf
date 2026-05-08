# =====================================================
# ECR MODULE
# modules/ecr/main.tf
# =====================================================

resource "aws_ecr_repository" "this" {
  name = var.app_name
}

output "repository_url" {
  value = aws_ecr_repository.this.repository_url
}
