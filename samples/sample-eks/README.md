# Sample EKS Cluster

This Terraform template creates an EKS cluster running on EC2 instances. The `kubernetes-manifests` directory contains sample manifests to deploy into the cluster.

---

## Table of Contents
1. [Using IAM Roles for Service Accounts](#using-iam-roles-for-service-accounts)
2. [Fargate Configuration](#fargate-configuration)
3. [Installing the AWS ALB Controller](#installing-the-aws-alb-controller)
4. [Enabling the EBS CSI Addon](#enabling-the-ebs-csi-addon)
5. [Karpenter](#karpenter)

---

## Using IAM Roles for Service Accounts

This project uses IAM Roles for Service Accounts (IRSA) for the AWS Load Balancer Controller, EBS CSI Controller, Gateway Controller, and other components. Follow these steps to configure them:

1. **Retrieve Role ARNs:**
   Export the IAM Role ARNs as environment variables:

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
   Use Helm to install the chart with the retrieved Role ARNs:

   ```bash
   helm upgrade --install aws-sa-chart helm-charts/kube-sa-helm-chart \
    --set roleArns.albController=$ALB_CONTROLLER_ARN \
    --set roleArns.gatewayController=$GATEWAY_CONTROLLER_ARN \
    --set roleArns.ebsCsiController=$EBS_CSI_CONTROLLER_ARN \
    --set roleArns.adotCollector=$ADOT_COLLECTOR_ARN
   ```

---

## Fargate Configuration

When using Fargate, the CoreDNS deployments need to be re-annotated and rolled out:

```bash
kubectl patch deployment coredns \
    -n kube-system \
    --type json \
    -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
```

```bash
kubectl rollout restart -n kube-system deployment coredns
```

---

## Installing the AWS ALB Controller

To install version 2 of the AWS ALB Controller, follow these steps:

1. **Export Cluster Name and Region:**

   ```bash
   export EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
   export REGION=$(terraform output -raw region)
   export VPC_ID=$(terraform output -raw vpc_id)
   ```

2. **Add the EKS Helm Repository:**

   ```bash
   helm repo add eks https://aws.github.io/eks-charts
   ```

3. **Update Kubeconfig:**

   ```bash
   aws eks update-kubeconfig --region $REGION --name $EKS_CLUSTER_NAME
   ```

4. **Install the ALB Controller:**

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

   - For EC2:

     ```bash
     curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster_name}}/$EKS_CLUSTER_NAME/;s/{{region_name}}/$REGION/" | kubectl apply -f -
     ```

   - For Fargate:

     ```bash
     curl https://raw.githubusercontent.com/aws-observability/aws-otel-collector/main/deployment-template/eks/otel-fargate-container-insights.yaml | sed "s/YOUR-EKS-CLUSTER-NAME/$EKS_CLUSTER_NAME/;s/region=us-east-1/region=$REGION/" | kubectl apply -f -
     ```

---

## Enabling the EBS CSI Addon

EKS versions > 1.23 require the EBS CSI driver for persistent volume claims. Enable the addon using the following command:

```bash
eksctl create addon \
  --name aws-ebs-csi-driver \
  --cluster $EKS_CLUSTER_NAME \
  --service-account-role-arn $EBS_CSI_CONTROLLER_ARN \
  --force
```

This assumes the service accounts were created.

---

## Karpenter

Karpenter is a Kubernetes cluster autoscaler that provisions EC2 instances based on workload requirements. Follow these steps to configure and install Karpenter:

1. **Identity Mapping for Nodes:**

   Allow nodes to log in to the cluster:

   ```bash
   eksctl create iamidentitymapping \
     --username system:node:{{EC2PrivateDNSName}} \
     --cluster "$EKS_CLUSTER_NAME" \
     --arn "$KARPENTER_NODE_IAM_ROLE_ARN" \
     --group system:bootstrappers \
     --group system:nodes
   ```

2. **Install Karpenter via Helm:**

   ```bash
   helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
     --version "${KARPENTER_VERSION}" \
     --namespace "karpenter" --create-namespace \
     --set "settings.clusterName=${EKS_CLUSTER_NAME}" \
     --set "settings.interruptionQueue=${KARPENTER_INTERRUPTION_QUEUE}" \
     --set controller.resources.requests.cpu=1 \
     --set controller.resources.requests.memory=1Gi \
     --set controller.resources.limits.cpu=1 \
     --set controller.resources.limits.memory=1Gi \
     --set replicas=1 \
     --wait
   ```

3. **Optional: Enable IRSA for Karpenter:**

   Karpenter uses pod identity by default for authorization. Pod identity is automatically configured in this cluster. If using IRSA, create the service account:

   ```bash
   eksctl create iamserviceaccount \
     --name karpenter \
     --namespace "${KARPENTER_NAMESPACE}" \
     --cluster "${EKS_CLUSTER_NAME}" \
     --role-name "${EKS_CLUSTER_NAME}-karpenter" \
     --attach-policy-arn "arn:${AWS_PARTITION}:iam::${AWS_ACCOUNT_ID}:policy/KarpenterControllerPolicy-${EKS_CLUSTER_NAME}" \
     --approve \
     --override-existing-serviceaccounts
   ```
