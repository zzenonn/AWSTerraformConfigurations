# Sample EKS Cluster

This terraform template creates an EKS cluster running on EC2 instances. The kubernetes-manifests directory contains sample manifests to deploy into the cluster.

## Using IAM Roles for Service Accounts

This template creates the appropriate OIDC provider to connect the cluster's SA to IAM. To apply the SAs required for the apps, run `kubectl apply -f kubernetes-manifests/kube-sa.yaml`.

## Installing the ALB Controller

It is recommended to use vesion 2 of the AWS ALB Controller. It can be installed via Helm chart.

1. Add the eks repo to helm. `helm repo add eks https://aws.github.io/eks-charts`
2. Update Kube Config `aws eks update-kubeconfig --region ap-southeast-1 --name Kubernetes-Test-Dev-Cluster`
3. Install the ALB Controller via Helm. The manifest applied earlier already creates the appropriate service account. `helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=Kubernetes-Test-Dev-Cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller`
4. Enable Container Insights
```
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster_name}}/Kubernetes-Test-Dev-Cluster/;s/{{region_name}}/ap-southeast-1/" | kubectl apply -f -
```