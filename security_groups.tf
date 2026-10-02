resource "aws_security_group" "alb" {
  name   = "${var.name}-alb"
  vpc_id = aws_vpc.main.id

  egress {
    description     = "Traffic to application instances"
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.app.id]
  }
}

resource "aws_security_group_rule" "alb_http" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_https" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "app" {
  name   = "${var.name}-app"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Outbound application traffic"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name   = "${var.name}-rds"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from application instances"
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [aws_security_group.app.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}