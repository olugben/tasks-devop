# =====================================================
# CLOUDWATCH MODULE
# modules/cloudwatch/main.tf
# =====================================================

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 7
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.this.name
}
