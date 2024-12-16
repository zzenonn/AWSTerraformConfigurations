# Sample EKS Cluster

This terraform template creates an EKS cluster running on EC2 instances. The kubernetes-manifests directory contains sample manifests to deploy into the cluster.

## Using IAM Roles for Service Accounts

This project uses IAM Roles for Service Accounts (IRSA) for the AWS Load Balancer Controller, EBS CSI Controller, and Gateway Controller. Follow these steps to configure them:

1. **Retrieve Role ARNs:**
   - Run the following commands to export the IAM Role ARNs as environment variables:

   ```bash
   export ALB_CONTROLLER_ARN=$(terraform output -raw kube_alb_controller_role_arn)
   export GATEWAY_CONTROLLER_ARN=$(terraform output -raw kube_gateway_controller_role_arn)
   export EBS_CSI_CONTROLLER_ARN=$(terraform output -raw kube_ebs_csi_controller_role_arn)
   export ADOT_COLLECTOR_ARN=$(terraform output -raw kube_adot_collector_role_arn)
   ```

2. **Install the Helm Chart:**
   - Use Helm to install the chart with the retrieved Role ARNs:

   ```bash
   helm install aws-sa-chart kube-sa-helm-chart \
    --set roleArns.albController=$ALB_CONTROLLER_ARN \
    --set roleArns.gatewayController=$GATEWAY_CONTROLLER_ARN \
    --set roleArns.ebsCsiController=$EBS_CSI_CONTROLLER_ARN \
    --set roleArns.adotCollector=$ADOT_COLLECTOR_ARN
   ```

## Fargate Configuration

When using fargate, the coredns deployments need to be re-annotated and rolled out.

```
kubectl patch deployment coredns \
    -n kube-system \
    --type json \
    -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
```

```
kubectl rollout restart -n kube-system deployment coredns
```

## Installing the ALB Controller

It is recommended to use vesion 2 of the AWS ALB Controller. It can be installed via Helm chart.

1. Add the eks repo to helm. `helm repo add eks https://aws.github.io/eks-charts`
2. Update Kube Config `aws eks update-kubeconfig --region ap-southeast-1 --name Kubernetes-Test-Dev-Cluster`
3. Install the ALB Controller via Helm. The manifest applied earlier already creates the appropriate service account. `helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n aws-load-balancer-controller-system --set clusterName=Kubernetes-Test-Dev-Cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --set region=ap-southeast-1 --set vpcId=<vpc-id> --set ingressClass=alb` 
4. Enable Container Insights
```
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster_name}}/Kubernetes-Test-Dev-Cluster/;s/{{region_name}}/ap-southeast-1/" | kubectl apply -f -
```

## Installing the AWS ALB Controller

It is recommended to use version 2 of the AWS ALB Controller. Follow these steps to install it:

1. **Get Cluster Name and Region:**

   ```bash
   export EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
   export REGION=$(terraform output -raw region)
   export VPC_ID=$(terraform output -raw vpc_id)
   ```

2. **Add EKS Helm Repository:**

   ```bash
   helm repo add eks https://aws.github.io/eks-charts
   ```

3. **Update Kubeconfig:**export EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
   export REGION=$(terraform output -raw region)
   export VPC_ID=$(terraform output -raw vpc_id)

   ```bash
   aws eks update-kubeconfig --region $REGION --name $EKS_CLUSTER_NAME
   ```

4. **Install ALB Controller via Helm:**

   ```bash
   helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
     -n aws-load-balancer-controller-system \
     --set clusterName=$EKS_CLUSTER_NAME \
     --set serviceAccount.create=false \
     --set serviceAccount.name=aws-load-balancer-controller \
     --set region=$REGION \
     --set ingressClass=alb \
     --set vpcId=$VPC_ID
   ```

5. **Enable Fargate Logging:**

    ```bash
    helm install eks-fargate-logging ./eks-fargate-logging --set region=$REGION --set logGroupName=<your-log-group-name> 
    ```

6. **Enable Container Insights:**

    For EC2
    
   ```bash
   curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster_name}}/$EKS_CLUSTER_NAME/;s/{{region_name}}/$REGION/" | kubectl apply -f -
   ```

   For Fargate, ensure that the `amazon*` and `fargate*` are part of the Fargate profile selector.

   ```bash
   curl https://raw.githubusercontent.com/aws-observability/aws-otel-collector/main/deployment-template/eks/otel-fargate-container-insights.yaml | sed "s/YOUR-EKS-CLUSTER-NAME/$EKS_CLUSTER_NAME/;s/region=us-east-1/region=$REGION/" | kubectl apply -f -
   ```

   

## Enabling the EBS CSI Addon

For persistent volume claims, EKS versions > 1.23 now need to have the EBS CSI driver enabled.

`eksctl create addon --name aws-ebs-csi-driver --cluster Kubernetes-Test-Dev-Cluster --service-account-role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/Kubernetes-Test-Dev-Kube-EBS-CSI-Controller-Role --force`

This assumes the service accounts were created.