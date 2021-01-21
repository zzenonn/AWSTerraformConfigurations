provider "aws" {
  profile = "terraform"
  region  = "ap-southeast-1"
}

module "network" {
    source          = "../../modules/infrastructure/network"
    project_name    = var.project_name
    environment     = var.environment
    db_port         = var.db_port
    networks        = var.networks
}

module "alb" {
    source              = "../../modules/infrastructure/alb"
    project_name        = module.network.project_name
    environment         = module.network.environment
    vpc                 = module.network.vpc
    private_subnets     = module.network.private_subnets
    public_subnets      = module.network.public_subnets
}

module "cicd" {
    for_each                        = local.services
    source                          = "../../modules/cicd/ecs"
    project_name                    = module.network.project_name
    environment                     = module.network.environment
    service                         = each.key
    git_owner                       = "zzenonn"
    git_repo                        = lower("${var.project_name}-${each.key}service")
    codestar_connection_arn         = var.codestar_connection_arn
    codedeploy_app                  = aws_codedeploy_app.services.name
    codedeploy_deployment_group     = aws_codedeploy_deployment_group.services[each.key].deployment_group_name
    codebuild_environment_vars      = {
        "SUBNETS"                   = join("\",\"", module.network.private_subnets)
        "SECURITY_GROUPS"           = join("\",\"", [aws_security_group.task.id])
        "TASK_ROLE"                 = aws_iam_role.task_role[0].arn
        "EXECUTION_ROLE"            = aws_iam_role.ecs_execution_role[0].arn
    }
}
