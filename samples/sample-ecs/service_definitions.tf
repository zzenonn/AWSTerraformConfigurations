
# While all services here will have the exact same configuration, the CICD will 
# overwrite this with 
resource "aws_ecs_task_definition" "services" {
  for_each                 = data.aws_ecr_repository.services
  cpu                      = 128
  memory                   = 128
  family                   = lower("${local.name_tag_prefix}-${each.key}")
  requires_compatibilities = ["EC2"]
  
  container_definitions = <<-EOF
[
  {
    "name": "${lower(each.key)}",
    "image": "${each.value.repository_url}",
    "essential": true,
    "portMappings": [
      {
        "protocol": "tcp",
        "containerPort": 80
      }
    ]
  }
]
  EOF
}

resource "aws_ecs_service" "services" {
  for_each        = data.aws_ecr_repository.services
  name            = each.key
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.services[each.key].arn
  desired_count   = 2
  
  deployment_controller {
    type = "CODE_DEPLOY"
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.green[each.key].arn
    container_name   = lower(each.key)
    container_port   = 80
  }

}