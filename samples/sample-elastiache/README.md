# ElastiCache Sample

This sample creates AWS ElastiCache Redis clusters with networking and bastion host.

## Resources Created

- VPC with public, private, and DB subnets
- ElastiCache subnet group
- Single node Redis cluster
- Cluster mode Redis with 2 node groups and 1 replica each
- Bastion host for access

## Variables

- `cache_node_type`: ElastiCache node type (default: cache.t3.micro)
- `project_name`: Project name for tagging (default: Demo)
- `environment`: Environment name (default: Dev)
- `region`: AWS region (default: ap-southeast-1)
- `profile`: AWS profile (default: default)

## Usage

```bash
terraform init
terraform plan
terraform apply
```