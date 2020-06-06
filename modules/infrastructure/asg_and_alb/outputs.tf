output "load_balancer_arn" {
  value = aws_lb.app.arn
}

output "asg" {
  value = aws_autoscaling_group.instances.name
}
