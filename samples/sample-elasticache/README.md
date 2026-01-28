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
- `num_node_groups`: Number of node groups/shards for cluster mode (default: 2)
- `replicas_per_node_group`: Number of replicas per node group (default: 1)
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

## Benchmarking

After deployment, connect to the bastion host via Session Manager and run Redis benchmarks using memtier_benchmark (pre-installed).

### Set Environment Variable
```bash
export REDIS_ENDPOINT="<endpoint>"
```

### Sanity Check Test
Quick test to verify connectivity:
```bash
memtier_benchmark \
  -s $REDIS_ENDPOINT \
  -p 6379 \
  --cluster-mode \
  --ratio=1:1 \
  --key-pattern=R:R \
  --key-maximum=100 \
  -n 10 \
  -c 1 \
  -t 1 \
  --hide-histogram
```

### Load Test
5-minute load test with 200 concurrent connections:
```bash
memtier_benchmark \
  -s $REDIS_ENDPOINT \
  -p 6379 \
  --cluster-mode \
  --ratio=1:1 \
  --key-pattern=R:R \
  --key-maximum=1000000 \
  -t 4 \
  -c 50 \
  --test-time=300 \
  --hide-histogram
```

**Load Test Parameters:**
- 4 threads × 50 clients = 200 total connections
- 50% reads, 50% writes (--ratio=1:1)
- Random key distribution across 1M keyspace
- 5-minute duration for stable metrics

**Throughput Calculation:**
The 200 concurrent clients send requests as fast as Redis can handle. Output shows:
```
Totals
-------
Ops/sec:  150000.00
Latency:  0.70 ms
GETs/sec: 75000.00
SETs/sec: 75000.00
```
- Total ops/sec = GETs/sec + SETs/sec
- With --ratio=1:1, GETs/sec ≈ SETs/sec ≈ 50% of total ops/sec