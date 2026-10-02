resource "aws_db_subnet_group" "app" {
  name = "${var.name}-db"

  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "app" {
  identifier = "${var.name}-db"

  engine         = "postgres"
  engine_version = var.postgres_version

  instance_class        = var.db_instance_class
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"

  db_name  = var.db_name
  username = var.db_username

  manage_master_user_password = true

  db_subnet_group_name = aws_db_subnet_group.app.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  publicly_accessible = false

  multi_az = false

  backup_retention_period = 7

  skip_final_snapshot = true
}