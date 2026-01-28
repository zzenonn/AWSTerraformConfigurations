# OpenSearch Sample

This sample creates AWS OpenSearch cluster with networking and bastion host.

## Resources Created

- VPC with public, private, and DB subnets
- OpenSearch domain with 3 nodes
- Security group for OpenSearch access
- Bastion host for access

## Variables

- `opensearch_instance_type`: OpenSearch instance type (default: t3.small.search)
- `opensearch_instance_count`: Number of OpenSearch instances (default: 3)
- `opensearch_version`: OpenSearch engine version (default: OpenSearch_2.3)
- `project_name`: Project name for tagging (default: Demo-OpenSearch)
- `environment`: Environment name (default: Dev)
- `region`: AWS region (default: ap-southeast-1)
- `profile`: AWS profile (default: default)

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Testing

After deployment, connect to the bastion host via Session Manager and test OpenSearch connectivity:

### Set Environment Variable
```bash
export OPENSEARCH_ENDPOINT="<endpoint>"
```

### Basic Connectivity Test
```bash
curl -k https://$OPENSEARCH_ENDPOINT/_cluster/health
```

### Create Index and Add Document
```bash
# Create an index
curl -k -X PUT "https://$OPENSEARCH_ENDPOINT/test-index"

# Add a document
curl -k -X POST "https://$OPENSEARCH_ENDPOINT/test-index/_doc/1" \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello OpenSearch"}'

# Search documents
curl -k -X GET "https://$OPENSEARCH_ENDPOINT/test-index/_search"
```