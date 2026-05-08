# =====================================================
# ALB MODULE
# modules/alb/main.tf
# =====================================================

resource "aws_lb" "this" {
  name               = "${var.app_name}-alb"
  load_balancer_type = "application"
  security_groups    = []
  subnets            = var.public_subnets
}

resource "aws_lb_target_group" "this" {
  name     = "${var.app_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

output "target_group_arn" {
  value = aws_lb_target_group.this.arn
}
