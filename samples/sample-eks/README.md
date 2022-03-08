# Sample EKS Cluster

This terraform template creates an EKS cluster running on EC2 instances. The kubernetes-manifests directory contains sample manifests to deploy into the cluster.

## Using IAM Roles for Service Accounts

This template creates the appropriate OIDC provider to connect the cluster's SA to IAM. To apply the SAs required for the apps, run `kubectl apply -f kubernetes-manifest/kube-sa.yaml`.

## Installing the ALB Controller

It is recommended to use vesion 2 of the AWS ALB Controller. It can be installed via Helm chart.

1. Add the eks repo to helm. `helm repo add eks https://aws.github.io/eks-charts`
2. Install the ALB Controller via Helm. The manifest applied earlier already creates the appropriate service account. `helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=Kubernetes-Test-Dev-Cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller`