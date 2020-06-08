resource "aws_iam_role" "codedeploy" {
  name = "${var.project_name}-${var.environment}-Codedeploy"
  path = "/${var.project_name}/${var.environment}/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "codedeploy.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
}
EOF

  tags = {
    Env     = var.environment
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = data.aws_iam_policy.codedeploy_ecs.arn
}

resource "aws_codedeploy_app" "services" {
  depends_on        = [aws_iam_role_policy_attachment.codedeploy]
  name              = "${local.name_tag_prefix}-Apps"
  compute_platform  = "ECS"
}

resource "aws_codedeploy_deployment_group" "services" {
  for_each               = data.aws_ecr_repository.services
  app_name               = aws_codedeploy_app.services.name
  deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"
  deployment_group_name  = "${local.name_tag_prefix}-${each.key}"
  service_role_arn       = aws_iam_role.codedeploy.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.cluster.name
    service_name = aws_ecs_service.services[each.key].name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.green_app.arn]
      }
      
      test_traffic_route {
        listener_arns = [aws_lb_listener.blue_app.arn]
      }

      target_group {
        name = aws_lb_target_group.green[each.key].name
      }

      target_group {
        name = aws_lb_target_group.blue[each.key].name
      }
    }
  }
}