#!/bin/bash

# Configurable settings
CLUSTER_NAME="artiv2"
REGION="us-east-2"
ROLE_ARN="arn:aws:iam::308531106085:role/artiv-dev-pgbouncer-portforward-role"
SESSION_NAME="artiv-dev-portforward"
PROFILE_NAME="artiv-portforward"

echo "🔐 Assuming role: $ROLE_ARN"

# Assume the role and capture credentials
read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< $(aws sts assume-role \
  --role-arn "$ROLE_ARN" \
  --role-session-name "$SESSION_NAME" \
  --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" \
  --output text)

# Check for success
if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" || -z "$AWS_SESSION_TOKEN" ]]; then
  echo "❌ Failed to assume role. Aborting."
  exit 1
fi

echo "✅ Role assumed successfully."

# Export credentials
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN

echo "🌐 Updating kubeconfig for cluster: $CLUSTER_NAME"

# Update kubeconfig using assumed role credentials (in-memory)
aws eks update-kubeconfig \
  --region "$REGION" \
  --name "$CLUSTER_NAME" \
  --profile "$PROFILE_NAME" 2>/dev/null || \
aws eks update-kubeconfig \
  --region "$REGION" \
  --name "$CLUSTER_NAME"

# Test access
echo "🔍 Testing Kubernetes access..."
kubectl get pods -n pgbouncer-artiv-dev

echo "🎯 You're now ready to port-forward with:"
echo "kubectl port-forward pod/<pgbouncer-pod-name> 5432:5432 -n pgbouncer-artiv-dev"
