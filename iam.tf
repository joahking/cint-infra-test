# Grant EC2s permissions to get the RDS secret

resource "aws_iam_role" "app" {
  name = "${var.name}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "app_secrets" {
  name = "${var.name}-app-secrets"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "secretsmanager:GetSecretValue"
      ]

      Resource = aws_db_instance.app.master_user_secret[0].secret_arn
    }]
  })
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.name}-app-profile"
  role = aws_iam_role.app.name

  tags = local.tags
}