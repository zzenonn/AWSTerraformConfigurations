# Sample ECS Deployment

This configuration deploys the following infrastructure:

![architecture](../../__assets/ecs_architecture.png)

Along with VPCs and network ACLs (ommitted see [this configuration](../../modules/infrastructure/network). It also relies on [this configuration](../../modules/infrastructure/asg_and_alb) for the load balancer and EC2 instances.

This configuration only holds the cluster definition, service definitions, scaling rules, and Codedeploy application.
