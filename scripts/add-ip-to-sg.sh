#!/usr/bin/env bash

SG_ID="sg-02f8ad1efecbd3cef"
REGION="us-east-2"
PORT=5432
TTL_SECONDS=600
MY_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)

echo "Allowing $MY_IP/32 to access port $PORT for $TTL_SECONDS seconds..."

aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port "$PORT" \
  --cidr "$MY_IP/32" \
  --region "$REGION"

sleep "$TTL_SECONDS"

echo "Revoking $MY_IP/32 from port $PORT..."

aws ec2 revoke-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port "$PORT" \
  --cidr "$MY_IP/32" \
  --region "$REGION"
