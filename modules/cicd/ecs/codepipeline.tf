/*
This template is for provisioning of a cicd pipeline with an ecs blue green 
deployment
*/

resource "aws_s3_bucket" "artifact_store" {
  bucket_prefix = local.name_tag_prefix
  acl    = "private"
}

resource "aws_iam_role" "codepipeline" {
  count       = length(var.iam_policies) > 0 ? 1 : 0
  name_prefix = "${var.project_name}-${var.environment}-${each.key}"
  path        = "/${var.project_name}/${var.environment}/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "codepipeline.amazonaws.com"
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

resource "aws_iam_role_policy" "codepipeline" {
  for_each    = var.iam_policies
  name_prefix = "${var.project_name}-${var.environment}-${each.key}"
  role        = aws_iam_role.asg_role[0].id
  policy      = each.value
}


resource "aws_iam_role" "codebuild" {
  count       = length(var.iam_policies) > 0 ? 1 : 0
  name_prefix = "${var.project_name}-${var.environment}-${each.key}"
  path        = "/${var.project_name}/${var.environment}/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "codebuild.amazonaws.com"
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

resource "aws_iam_role_policy" "codebuild" {
  for_each    = var.iam_policies
  name_prefix = "${var.project_name}-${var.environment}-${each.key}"
  role        = aws_iam_role.asg_role[0].id
  policy      = each.value
}
