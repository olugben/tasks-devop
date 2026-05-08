# =====================================================
# VPC MODULE
# modules/vpc/main.tf
# =====================================================

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count      = 2
  vpc_id     = aws_vpc.this.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
}
resource "aws_security_group" "ecs" {
  name   = "${var.vpc_cidr}-ecs-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# outputs
output "vpc_id" { value = aws_vpc.this.id }
output "public_subnets" { value = aws_subnet.public[*].id }
output "private_subnets" { value = aws_subnet.private[*].id }
