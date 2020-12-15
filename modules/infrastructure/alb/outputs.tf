output "load_balancer_arn" {
  value = aws_lb.app.arn
}

output "alb_sg" {
  value = aws_security_group.elb.id
}