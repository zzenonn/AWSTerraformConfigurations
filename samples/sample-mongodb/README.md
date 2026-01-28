# MongoDB Sharded Cluster Sample

This sample creates a production-ready MongoDB sharded cluster with full replication and high availability.

## Architecture Overview

A MongoDB sharded cluster consists of:
- **Shard Servers**: Store the actual data, each shard is a replica set
- **Config Servers**: Store cluster metadata and configuration, deployed as replica set
- **Mongos Routers**: Query routers that interface with client applications

## TODO - Implementation Specifications

### 1. Network Infrastructure
- [ ] **Network Module**: Use `modules/infrastructure/network` with all variables as parameters
- [ ] **Subnet Strategy**: 
  - Private subnets for MongoDB components (shard servers, config servers) - need NAT gateway for package downloads
  - Public subnets for mongos routers and bastion hosts - direct internet access
  - Database subnets reserved for future RDS/managed database services
- [ ] **Security Groups**:
  - Shard server SG: Allow 27018 from mongos and other shard members
  - Config server SG: Allow 27019 from mongos and other config members  
  - Mongos SG: Allow 27017 from application tier and bastion
  - Inter-cluster communication on all MongoDB ports

### 2. MongoDB Shard Servers (Data Tier)
- [ ] **Terraform ASG Management**: 
  - Use `count` or `for_each` to create `var.shard_count` ASGs
  - Each ASG has `desired_capacity = var.replica_factor`
  - Each ASG gets unique replica set name: `shard${count.index}`
  - Parameterized instance type variable
- [ ] **Storage**:
  - EBS GP3 volumes with configurable size (default: 100GB)
  - Encrypted at rest with KMS
- [ ] **User Data Template**:
  - Install MongoDB 7.0 from official repository
  - Use Terraform templatefile() to inject shard ID and replica set name
  - Start mongod on port 27018 for shard servers
  - Auto-discover other replicas in same ASG via AWS API
  - Initialize replica set on first instance, join on others

### 3. MongoDB Config Servers (Metadata Tier)
- [ ] **ASG Configuration**:
  - Single ASG with 2 instances minimum (config server replica set)
  - Fixed instance count (config servers don't scale horizontally)
  - Parameterized instance type variable
- [ ] **Storage**:
  - EBS GP3 volumes (20GB sufficient for metadata)
  - Encrypted at rest
- [ ] **User Data**:
  - Install MongoDB 7.0
  - Start mongod on port 27019 as config server
  - Configure as config server replica set (csrs)

### 4. MongoDB Mongos Routers (Query Tier)
- [ ] **ASG Configuration**:
  - Variable mongos count (default: 1 for simplicity)
  - Parameterized instance type variable
  - Deploy in public subnets for application access
- [ ] **User Data**:
  - Install MongoDB 7.0
  - Start mongos on port 27017
  - Configure mongos with config server connection strings
  - Applications connect directly to mongos instances (no load balancer needed)

### 5. Variables & Configuration
- [ ] **Cluster Configuration**:
  - `shard_count`: Number of shards (default: 3)
  - `replica_factor`: Replicas per shard (default: 3)
  - `mongos_count`: Number of mongos routers (default: 2)
- [ ] **Instance Configuration**:
  - `shard_instance_type`: Instance type for shard servers (default: t2.micro)
  - `config_instance_type`: Instance type for config servers (default: t2.micro)
  - `mongos_instance_type`: Instance type for mongos routers (default: t2.micro)
- [ ] **Storage Configuration**:
  - `data_volume_size`: Size of data volumes in GB
  - `data_volume_type`: EBS volume type (gp3, io1, io2)
  - `data_volume_iops`: Provisioned IOPS for io1/io2
- [ ] **Network Configuration**:
  - All `modules/infrastructure/network` variables as parameters
  - MongoDB port configurations (27017, 27018, 27019)

### 6. Operational Considerations
- [ ] **Terraform Shard Scaling**:
  - Change `var.shard_count` from 3 to 4 → `terraform apply` creates new ASG
  - New ASG automatically gets replica set name `shard3`
  - User data handles replica set initialization automatically
  - Manual step: Connect to mongos and run `sh.addShard("shard3/ip1:27018,ip2:27018")`
- [ ] **Cluster Initialization**:
  - Automated replica set initialization via user data
  - Shard registration requires manual mongos connection
  - Database and collection sharding setup
- [ ] **Maintenance**:
  - Rolling update strategy for MongoDB upgrades
  - Automated balancer configuration
  - Index management across shards

### 7. Testing & Validation
- [ ] **Bastion Host**:
  - MongoDB shell and tools installation
  - Connection testing scripts
  - Performance testing utilities (mongoperf, YCSB)
- [ ] **Health Checks**:
  - Replica set status validation
  - Shard balancing verification
  - Connection pool monitoring

## Deployment Strategy

1. **Phase 1**: Network infrastructure using `modules/infrastructure/network`
2. **Phase 2**: Config servers ASG deployment and replica set initialization
3. **Phase 3**: Shard servers ASG deployment and replica set setup
4. **Phase 4**: Mongos routers ASG deployment
5. **Phase 5**: Cluster initialization and shard registration
6. **Phase 6**: Testing and validation

## Architecture Notes

- **Terraform-Managed Shards**: One ASG per shard, scaling handled by changing `var.shard_count`
- **Replica Set Naming**: Automatic naming pattern `shard0`, `shard1`, `shard2`, etc.
- **Self-Configuring**: User data handles MongoDB installation and replica set setup
- **Manual Registration**: New shards require manual `sh.addShard()` command via mongos
- **No Load Balancer**: Applications connect directly to mongos instances
- **Cost Optimization**: Default to t2.micro instances but allow parameterization
- **Network Module**: Leverage existing network infrastructure module for consistency