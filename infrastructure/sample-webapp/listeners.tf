resource "aws_lb_target_group" "app" {
  name     = "${local.name_tag_prefix}-App-Tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.network.vpc
}


resource "aws_lb_listener" "app" {
  load_balancer_arn = module.webapp.load_balancer_arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_autoscaling_policy" "webapp" {
  name                      = "${local.name_tag_prefix}-Cpu-Target"
  policy_type               = "TargetTrackingScaling"
  adjustment_type           = "ChangeInCapacity"
  autoscaling_group_name    = module.webapp.asg
  estimated_instance_warmup = 60
  
  
  target_tracking_configuration{
    predefined_metric_specification {
      predefined_metric_type    = "ASGAverageCPUUtilization"
      
    }
    target_value = 60
  }
}