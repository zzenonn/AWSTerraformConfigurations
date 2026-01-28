# Sample EKS Auto Mode Cluster

This Terraform template creates an EKS cluster using **EKS Auto Mode**. The ALB controller, EBS CSI driver, and compute auto-scaling are all managed automatically by EKS. Just apply the configuration and you're ready to deploy workloads!

---

## Table of Contents
1. [What is EKS Auto Mode?](#what-is-eks-auto-mode)
2. [Parameters](#parameters)
3. [Getting Started](#getting-started)
4. [Important Notes](#important-notes)

---

## What is EKS Auto Mode?

EKS Auto Mode is a fully managed Kubernetes experience that automatically handles:
- **Compute provisioning**: Automatically scales nodes based on workload requirements
- **Load balancing**: AWS Load Balancer Controller is pre-installed and managed
- **Storage**: EBS CSI driver is pre-installed and managed
- **Networking**: VPC CNI and Pod Identity Agent are automatically configured

No manual installation of controllers or drivers is required!

---

## Parameters

### Core Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `project_name` | string | `"Demo-EKS-Auto"` | Project name for tagging purposes |
| `environment` | string | `"Dev"` | Environment name for tagging purposes |
| `region` | string | `"ap-southeast-1"` | AWS region to deploy resources |
| `profile` | string | `"default"` | AWS profile to use |

### EKS Cluster Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `eks_version` | string | `"1.31"` | Kubernetes version for the EKS cluster |
| `kms_deletion_window` | number | `10` | KMS key deletion window in days |
| `bootstrap_self_managed_addons` | bool | `false` | Whether to bootstrap self-managed addons |
| `compute_node_pools` | list(string) | `["general-purpose", "system"]` | Node pools for EKS Auto Mode compute configuration |

### Network Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `networks` | object | See below | Network configuration object |
| `db_port` | number | `5432` | Port of the database being used |

**Default Network Configuration:**
```hcl
{
  cidr_block        = "10.0.0.0/16"
  public_subnets    = 3
  private_subnets   = 3
  db_subnets        = 3
  private_cidr_bits = 8
  public_cidr_bits  = 8
  db_cidr_bits      = 8
  nat_gateways      = 3
}
```

---

## Getting Started

1. **Configure Variables:**
   
   Edit `terraform.tfvars.json` or create your own tfvars file with your desired configuration.

2. **Initialize Terraform:**

   ```bash
   terraform init
   ```

3. **Apply Configuration:**

   ```bash
   terraform apply
   ```

4. **Update Kubeconfig:**

   ```bash
   export EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
   export REGION=$(terraform output -raw region)
   aws eks update-kubeconfig --region $REGION --name $EKS_CLUSTER_NAME
   ```

5. **Deploy Your Workloads:**

   You can now deploy Kubernetes manifests directly. The cluster will automatically:
   - Provision compute capacity as needed
   - Create load balancers for Ingress resources
   - Provision EBS volumes for PersistentVolumeClaims

---

## Important Notes

### EKS Auto Mode Features

- **Automatic Compute Scaling**: The cluster automatically provisions and scales EC2 instances based on pod requirements. No need to manually configure node groups or Karpenter.
- **Managed Add-ons**: AWS Load Balancer Controller, EBS CSI Driver, VPC CNI, and Pod Identity Agent are pre-installed and automatically updated.
- **Node Pools**: The cluster uses node pools (`general-purpose` and `system` by default) to organize compute resources. You can customize these via the `compute_node_pools` variable.
- **Simplified Operations**: No need to manage node groups, launch templates, or auto-scaling configurations.

### Network Subnet Sizing

The network module assumes that **public subnets are smaller than or equal to private and database subnets**. This encourages minimizing resource placement in public subnets for security best practices.

### Differences from Standard EKS

Unlike the standard EKS sample (`sample-eks`), this Auto Mode cluster:
- Does not require manual installation of AWS Load Balancer Controller
- Does not require manual installation of EBS CSI Driver
- Does not require Karpenter for auto-scaling
- Uses compute configuration instead of node groups
- Automatically manages node lifecycle and scaling