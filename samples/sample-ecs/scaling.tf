resource "aws_autoscaling_policy" "webapp_scale_up" {
  name                      = "${local.name_tag_prefix}-MemoryReservation-Scale-up"
  policy_type               = "StepScaling"
  adjustment_type           = "PercentChangeInCapacity"
  autoscaling_group_name    = module.webapp.asg
  estimated_instance_warmup = 300
  
  
  step_adjustment {
    scaling_adjustment          = 10
    metric_interval_lower_bound = 0
    metric_interval_upper_bound = 20
  }
  
  step_adjustment {
    scaling_adjustment          = 20
    metric_interval_lower_bound = 20
  }

}

resource "aws_autoscaling_policy" "webapp_scale_down" {
  name                      = "${local.name_tag_prefix}-MemoryReservation-Scale-Down"
  policy_type               = "StepScaling"
  adjustment_type           = "PercentChangeInCapacity"
  autoscaling_group_name    = module.webapp.asg
  estimated_instance_warmup = 300
  
  
  step_adjustment {
    scaling_adjustment          = -20
    metric_interval_upper_bound = -20
  }
  
  step_adjustment {
    scaling_adjustment          = -10
    metric_interval_lower_bound = -20
    metric_interval_upper_bound = 0
  }

}

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_name                = "${local.name_tag_prefix}-MemoryReservation-Scale-up"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "MemoryReservation"
  namespace                 = "AWS/ECS"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 60
  alarm_description         = "This metric monitors ECS Cluster memory reservation going up"
  alarm_actions             = [aws_autoscaling_policy.webapp_scale_up.arn]
  dimensions                = {
    ClusterName = aws_ecs_cluster.cluster.name
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_down" {
  alarm_name                = "${local.name_tag_prefix}-MemoryReservation-Scale-down"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "MemoryReservation"
  namespace                 = "AWS/ECS"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 40
  alarm_description         = "This metric monitors ECS Cluster memory reservation going down"
  alarm_actions             = [aws_autoscaling_policy.webapp_scale_down.arn]
  dimensions                = {
    ClusterName = aws_ecs_cluster.cluster.name
  }
}