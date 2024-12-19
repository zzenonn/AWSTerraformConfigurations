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
   export EKS_NODE_ROLE_ARN=$(terraform output -raw kube_node_role_arn)
   export KARPENTER_CONTROLLER_ROLE_ARN=$(terraform output -raw kube_karpenter_controller_role_arn)

   export EKS_NODE_ROLE=$(terraform output -raw kube_node_role_name)
   export KARPENTER_INTERRUPTION_QUEUE=$(terraform output -raw karpenter_interruption_sqs_queue_name)
   ```

2. **Install the Helm Chart:**
   - Use Helm to install the chart with the retrieved Role ARNs:

   ```bash
   helm upgrade --install aws-sa-chart helm-charts/kube-sa-helm-chart \
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

3. **Update Kubeconfig:**

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


helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --version "${KARPENTER_VERSION}" \
  --namespace "karpenter" --create-namespace \
  --set "settings.clusterName=${EKS_CLUSTER_NAME}" \
  --set "settings.interruptionQueue=${KARPENTER_INTERRUPTION_QUEUE}" \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${KARPENTER_IAM_ROLE_ARN} \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi \
  --set replicas=1 \
  --wait

Identity MAP for 

eksctl create iamidentitymapping \
  --username system:node:{{EC2PrivateDNSName}} \
  --cluster "$EKS_CLUSTER_NAME" \
  --arn "$KARPENTER_NODE_IAM_ROLE_ARN" \
  --group system:bootstrappers \
  --group system:nodes

  eksctl create iamserviceaccount \
  --name karpenter \
  --namespace "${KARPENTER_NAMESPACE}" \
  --cluster "${EKS_CLUSTER_NAME}" \
  --role-name "${EKS_CLUSTER_NAME}-karpenter" \
  --attach-policy-arn "arn:${AWS_PARTITION}:iam::${AWS_ACCOUNT_ID}:policy/KarpenterControllerPolicy-${EKS_CLUSTER_NAME}" \
  --approve \
  --override-existing-serviceaccounts
