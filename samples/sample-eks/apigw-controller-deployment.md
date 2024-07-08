## Deploying the APIGW Controller

To deploy the APIGW controller, follow these steps:

1. **Set the service name to apigatewayv2**:
   ```
   export SERVICE=apigatewayv2
   ```

2. **Retrieve the latest release version of the service controller**:
   ```
   export RELEASE_VERSION=$(curl -sL https://api.github.com/repos/aws-controllers-k8s/${SERVICE}-controller/releases/latest | jq -r '.tag_name | ltrimstr("v")')
   ```

3. **Set the AWS region**:
   ```
   export AGW_AWS_REGION=ap-southeast-1
   export AWS_REGION=ap-southeast-1
   ```

4. **Set the chart repository and reference**:
   ```
   export CHART_REPO=oci://public.ecr.aws/aws-controllers-k8s
   export CHART_REF="$CHART_REPO/$SERVICE --version $RELEASE_VERSION"
   ```

5. **Pull the Helm chart**:
   ```
   helm chart pull $CHART_REF
   helm pull $CHART_REF
   ```

6. **Log in to the Helm registry**:
   ```
   aws ecr-public get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin public.ecr.aws
   ```

7. **Install the controller using Helm**:
   ```
   helm install --create-namespace -n kube-system ack-$SERVICE-controller oci://public.ecr.aws/aws-controllers-k8s/$SERVICE-chart --version=$RELEASE_VERSION --set=aws.region=$AWS_REGION
   ```

8. **Annotate the Service Account**:
   ```
    IRSA_ROLE_ARN=eks.amazonaws.com/role-arn=arn:aws:iam::<account>:role/Kubernetes-Test-Dev-Kube-ACKIAM-Role
    kubectl annotate serviceaccount -n kube-system ack-apigatewayv2-controller
    kubectl annotate serviceaccount -n kube-system ack-apigatewayv2-controller $IRSA_ROLE_ARN
   ```

9. **Restart the deployment**:
   ```
   kubectl rollout restart deployment ack-apigatewayv2-controller-apigatewayv2-chart -n kube-system
   ```

These commands outline the process of deploying the APIGW controller, from setting environment variables to installing the controller and verifying the deployment.