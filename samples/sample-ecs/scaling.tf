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