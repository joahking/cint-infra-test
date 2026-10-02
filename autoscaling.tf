resource "aws_autoscaling_group" "app" {
  name = "${var.name}-asg"

  min_size         = var.asg_min_ec2_count
  desired_capacity = var.asg_min_ec2_count
  max_size         = var.asg_max_ec2_count

  vpc_zone_identifier = aws_subnet.private[*].id

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [
    aws_lb_target_group.app.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 120

  tag {
    key                 = "Name"
    value               = "${var.name}-app"
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.name}-"
  image_id      = data.aws_ssm_parameter.amazon_linux.value
  instance_type = "t2.nano"

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  user_data = base64encode(
    templatefile("${path.module}/user_data/application.sh", {
      db_host       = aws_db_instance.app.address
      db_port       = aws_db_instance.app.port
      db_name       = aws_db_instance.app.db_name
      db_secret_arn = aws_db_instance.app.master_user_secret[0].secret_arn
    })
  )
}
