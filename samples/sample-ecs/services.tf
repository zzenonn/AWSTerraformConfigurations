resource "aws_ecs_cluster" "cluster" {
  name = "${local.ecs_cluster_name}-EcsCluster"
}

resource "aws_lb_target_group" "blue" {
  for_each = local.services  
  name     = "${local.name_tag_prefix}-Blue-${each.key}-Tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.network.vpc
  tags = {
      Name    = "${local.name_tag_prefix}-Blue-${each.key}"
      Cluster = local.ecs_cluster_name
      Service = each.key
      Env     = var.environment
      Project = var.project_name
    }
}

resource "aws_lb_target_group" "green" {
  for_each = local.services
  name     = "${local.name_tag_prefix}-Green-${each.key}-Tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.network.vpc
  tags = {
      Name    = "${local.name_tag_prefix}-Green-${each.key}"
      Cluster = local.ecs_cluster_name
      Service = each.key
      Env     = var.environment
      Project = var.project_name
    }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = module.webapp.load_balancer_arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "This is a default error page"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_rule" "service" {
  for_each = local.services
  listener_arn = aws_lb_listener.app.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green[each.key].arn
  }
  
  condition {
    path_pattern {
      values = ["/${local.services[each.key]}"]
    }
  }
}