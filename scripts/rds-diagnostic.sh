#!/usr/bin/env bash

set -euo pipefail

REGION="us-east-2"
CLUSTERS=("artiv-dev-cluster" "artiv-staging-cluster")

echo "🔍 Running RDS Public Access Diagnostics in region: $REGION"
echo "------------------------------------------------------------"

for CLUSTER in "${CLUSTERS[@]}"; do
    echo -e "\n📦 Checking RDS instance: $CLUSTER"

    # Fetch basic instance details
    ENDPOINT=$(aws rds describe-db-instances \
        --db-instance-identifier "$CLUSTER" \
        --region "$REGION" \
        --query "DBInstances[0].Endpoint.Address" \
        --output text)

    PUBLICLY_ACCESSIBLE=$(aws rds describe-db-instances \
        --db-instance-identifier "$CLUSTER" \
        --region "$REGION" \
        --query "DBInstances[0].PubliclyAccessible" \
        --output text)

    SUBNETS=$(aws rds describe-db-instances \
        --db-instance-identifier "$CLUSTER" \
        --region "$REGION" \
        --query "DBInstances[0].DBSubnetGroup.Subnets[*].SubnetIdentifier" \
        --output text)

    echo "📡 Endpoint:              $ENDPOINT"
    echo "🌐 PubliclyAccessible:    $PUBLICLY_ACCESSIBLE"
    echo "📍 Subnets:"
    for SUBNET_ID in $SUBNETS; do
        echo "  ─ $SUBNET_ID"

        # Is this subnet set to auto-assign public IPs?
        PUB_IP_SETTING=$(aws ec2 describe-subnets \
            --subnet-ids "$SUBNET_ID" \
            --region "$REGION" \
            --query "Subnets[0].MapPublicIpOnLaunch" \
            --output text)

        echo "     🔁 MapPublicIpOnLaunch: $PUB_IP_SETTING"

        # Check for IGW route in route table
        ROUTES=$(aws ec2 describe-route-tables \
            --filters Name=association.subnet-id,Values="$SUBNET_ID" \
            --region "$REGION" \
            --query "RouteTables[0].Routes" \
            --output json)

        IGW_FOUND=$(echo "$ROUTES" | grep -q '"GatewayId": "igw-' && echo "yes" || echo "no")
        echo "     🌍 IGW route present:   $IGW_FOUND"
    done

    echo "------------------------------------------------------------"
done

echo -e "\n✅ Done. If IGW is missing or MapPublicIpOnLaunch is false, the RDS instance will NOT have a real public IP, even if 'PubliclyAccessible=true'."
