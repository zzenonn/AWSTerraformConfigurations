/*
This template is for provisioning of a cicd pipeline with an ecs blue green 
deployment
*/

resource "aws_s3_bucket" "artifact_store" {
  bucket_prefix = lower(local.name_tag_prefix)
  force_destroy = true
}

resource "aws_iam_role" "codepipeline" {
  name_prefix = "${var.project_name}-${var.environment}"
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
    Service = var.service
  }
}

resource "aws_iam_role_policy" "codepipeline" {
  name_prefix = local.name_tag_prefix
  role        = aws_iam_role.codepipeline.id
  policy      = <<-EOF
{
    "Statement": [
        {
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Condition": {
                "StringEqualsIfExists": {
                    "iam:PassedToService": [
                        "cloudformation.amazonaws.com",
                        "elasticbeanstalk.amazonaws.com",
                        "ec2.amazonaws.com",
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Action": [
                "codecommit:CancelUploadArchive",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:UploadArchive"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplication",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codestar-connections:UseConnection"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "elasticbeanstalk:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "s3:*",
                "sns:*",
                "cloudformation:*",
                "rds:*",
                "sqs:*",
                "ecs:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "lambda:InvokeFunction",
                "lambda:ListFunctions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "opsworks:CreateDeployment",
                "opsworks:DescribeApps",
                "opsworks:DescribeCommands",
                "opsworks:DescribeDeployments",
                "opsworks:DescribeInstances",
                "opsworks:DescribeStacks",
                "opsworks:UpdateApp",
                "opsworks:UpdateStack"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStacks",
                "cloudformation:UpdateStack",
                "cloudformation:CreateChangeSet",
                "cloudformation:DeleteChangeSet",
                "cloudformation:DescribeChangeSet",
                "cloudformation:ExecuteChangeSet",
                "cloudformation:SetStackPolicy",
                "cloudformation:ValidateTemplate"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Effect": "Allow",
            "Action": [
                "devicefarm:ListProjects",
                "devicefarm:ListDevicePools",
                "devicefarm:GetRun",
                "devicefarm:GetUpload",
                "devicefarm:CreateUpload",
                "devicefarm:ScheduleRun"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "servicecatalog:ListProvisioningArtifacts",
                "servicecatalog:CreateProvisioningArtifact",
                "servicecatalog:DescribeProvisioningArtifact",
                "servicecatalog:DeleteProvisioningArtifact",
                "servicecatalog:UpdateProduct"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:ValidateTemplate"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:DescribeImages"
            ],
            "Resource": "*"
        }
    ],
    "Version": "2012-10-17"
}
EOF
}


resource "aws_iam_role" "codebuild" {
  name_prefix = "${var.project_name}-${var.environment}"
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
    Service = var.service
  }
}

resource "aws_iam_role_policy" "codebuild" {
  name_prefix = local.name_tag_prefix
  role        = aws_iam_role.codebuild.id
  policy      = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "ssm:GetParametersByPath",
                "ssm:GetParameters",
                "ssm:GetParameter",
                "serverlessrepo:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
          "Effect":"Allow",
          "Action": [
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketVersioning",
            "s3:PutObject"
          ],
          "Resource": [
            "${aws_s3_bucket.artifact_store.arn}",
            "${aws_s3_bucket.artifact_store.arn}/*"
          ]
        },     
        {
            "Action": [
              "ecr:BatchCheckLayerAvailability",
              "ecr:CompleteLayerUpload",
              "ecr:GetAuthorizationToken",
              "ecr:InitiateLayerUpload",
              "ecr:PutImage",
              "ecr:DescribeRepositories",
              "ecr:UploadLayerPart"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_codebuild_project" "service" {
  name          = local.name_tag_prefix
  description   = "Build for ${var.service} service"
  build_timeout = "30"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.codebuild_compute
    image                       = var.codebuild_image
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "PROJECTNAME"
      value = lower(var.project_name)
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = lower(var.environment)
    }

    environment_variable {
      name  = "SERVICE"
      value = lower(var.service)
    }

    dynamic "environment_variable" {
      for_each = var.codebuild_environment_vars

      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }


  }

  source {
    type = "CODEPIPELINE"
  }
  tags = {
    Env     = var.environment
    Project = var.project_name
    Service = var.service
  }
}

resource "aws_codepipeline" "codepipeline" {
  name     = local.name_tag_prefix
  pipeline_type = "V2"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifact_store.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      namespace        = "SourceVariables"
      output_artifacts = ["${local.name_tag_prefix}-source_output"]

      configuration = {
        BranchName       = lower(var.environment)
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = "${var.git_owner}/${var.git_repo}"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["${local.name_tag_prefix}-source_output"]
      output_artifacts = ["${local.name_tag_prefix}-build_output"]
      version          = "1"

      configuration = {
        EnvironmentVariables = <<-EOF
[{
	"name": "EXECUTION_ID",
	"value": "#{codepipeline.PipelineExecutionId}",
	"type": "PLAINTEXT"
}, {
	"name": "COMMIT_ID",
	"value": "#{SourceVariables.CommitId}",
	"type": "PLAINTEXT"
}]
EOF
        ProjectName          = aws_codebuild_project.service.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name = "${var.environment}-Approval"
      category = "Approval"
      owner           = "AWS"
      provider        = "Manual"
      version = 1
      run_order = 1
    }

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["${local.name_tag_prefix}-build_output"]
      version         = "1"
      run_order       = 2

      configuration = {
        ApplicationName                = var.codedeploy_app
        DeploymentGroupName            = var.codedeploy_deployment_group
        TaskDefinitionTemplateArtifact = "${local.name_tag_prefix}-build_output"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "${local.name_tag_prefix}-build_output"
        AppSpecTemplatePath            = "appspec.yaml"
        Image1ArtifactName             = "${local.name_tag_prefix}-build_output"
        Image1ContainerName            = "IMAGE1_NAME"

      }
    }
  }
}