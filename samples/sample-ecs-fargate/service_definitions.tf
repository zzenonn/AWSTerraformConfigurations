resource "aws_iam_role" "ecs_execution_role" {
  count       = length(local.execution_policies) > 0 ? 1 : 0
  name        = "${var.project_name}-${var.environment}-EcsRole"
  path        = "/${var.project_name}/${var.environment}/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
          
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

resource "aws_iam_role_policy" "execution_policy" {
  for_each    = local.execution_policies
  name        = "${var.project_name}-${var.environment}-${each.key}-Policy"
  role        = aws_iam_role.ecs_execution_role[0].id
  policy      = each.value
}

resource "aws_iam_role" "task_role" {
  count       = length(local.task_policies) > 0 ? 1 : 0
  name        = "${var.project_name}-${var.environment}-TaskRole"
  path        = "/${var.project_name}/${var.environment}/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
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

resource "aws_iam_role_policy" "task_policy" {
  for_each    = local.task_policies
  name        = "${var.project_name}-${var.environment}-${each.key}-Policy"
  role        = aws_iam_role.task_role[0].id
  policy      = each.value
}



# While all services here will have the exact same configuration, the CICD will 
# overwrite this with the repos task definition
resource "aws_ecs_task_definition" "services" {
  for_each                 = data.aws_ecr_repository.services
  cpu                      = 256
  memory                   = 512
  family                   = lower("${local.name_tag_prefix}-${each.key}")
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.task_role[0].arn
  execution_role_arn       = aws_iam_role.ecs_execution_role[0].arn
  requires_compatibilities = ["FARGATE"]
  
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

resource "aws_security_group" "task" {
  name        = "${local.name_tag_prefix}-App-Sg"
  description = "Security group for bastion host"
  vpc_id      = module.network.vpc

  ingress {
    from_port        = 0
    to_port          = 65535
    protocol         = 6
    security_groups  = [module.alb.alb_sg]
    description      = "Allow from ELB to this instance"
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "Allow to everywhere"
  }

  tags = {
    Name    = "${local.name_tag_prefix}-Asg-Sg"
    Env     = var.environment
    Project = var.project_name
  }
}

resource "aws_ecs_service" "services" {
  for_each        = data.aws_ecr_repository.services
  name            = each.key
  cluster         = aws_ecs_cluster.cluster.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.services[each.key].arn
  desired_count   = 2
  
  network_configuration {
    subnets         = module.network.private_subnets
    security_groups = [aws_security_group.task.id]
  }
  
  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.green[each.key].arn
    container_name   = lower(each.key)
    container_port   = 80
  }

}