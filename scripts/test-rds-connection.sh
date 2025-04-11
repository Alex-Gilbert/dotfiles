#!/bin/bash

# RDS Connectivity Checker
# Usage: ./rds_connectivity_check.sh your-endpoint.region.rds.amazonaws.com [port] [username] [database]

# Default values
PORT=${2:-5432}
USERNAME=${3:-postgres}
DATABASE=${4:-postgres}
ENDPOINT=$1

# Check if endpoint is provided
if [ -z "$ENDPOINT" ]; then
    echo "Error: RDS endpoint is required"
    echo "Usage: ./rds_connectivity_check.sh your-endpoint.region.rds.amazonaws.com [port] [username] [database]"
    exit 1
fi

echo "Checking connectivity to $ENDPOINT:$PORT..."

# Check if endpoint resolves to an IP
echo "DNS resolution check:"
if host "$ENDPOINT" > /dev/null 2>&1; then
    echo "✅ DNS resolution successful"
    DNS_OK=true
else
    echo "❌ DNS resolution failed"
    DNS_OK=false
fi

# Check if security group allows access
echo "Security group check:"
if aws rds describe-db-instances --query "DBInstances[?Endpoint.Address=='$ENDPOINT'].VpcSecurityGroups[].VpcSecurityGroupId" --output text > /dev/null 2>&1; then
    SG_IDS=$(aws rds describe-db-instances --query "DBInstances[?Endpoint.Address=='$ENDPOINT'].VpcSecurityGroups[].VpcSecurityGroupId" --output text)
    if [ -n "$SG_IDS" ]; then
        echo "✅ Found security groups: $SG_IDS"
        
        # Get public IP
        PUBLIC_IP=$(curl -s https://checkip.amazonaws.com)
        echo "Your public IP: $PUBLIC_IP"
        
        SG_ACCESS=false
        for SG_ID in $SG_IDS; do
            RULE_COUNT=$(aws ec2 describe-security-groups --group-ids "$SG_ID" --query "SecurityGroups[0].IpPermissions[?ToPort=='$PORT' || FromPort=='$PORT'].IpRanges[].CidrIp" --output text | wc -l)
            if [ "$RULE_COUNT" -gt 0 ]; then
                echo "✅ Security group $SG_ID has rules for port $PORT"
                SG_ACCESS=true
            else
                echo "❌ Security group $SG_ID has no rules for port $PORT"
            fi
        done
    else
        echo "❌ No security groups found for this RDS instance"
        SG_ACCESS=false
    fi
else
    echo "❌ Failed to retrieve security group information"
    SG_ACCESS=false
fi

# Check if port is open
echo "Port check:"
if timeout 5 bash -c "</dev/tcp/$ENDPOINT/$PORT" 2>/dev/null; then
    echo "✅ Port $PORT is open"
    PORT_OK=true
else
    echo "❌ Port $PORT is closed or blocked"
    PORT_OK=false
fi

# Check if RDS instance is publicly accessible
echo "Public accessibility check:"
if aws rds describe-db-instances --query "DBInstances[?Endpoint.Address=='$ENDPOINT'].PubliclyAccessible" --output text 2>/dev/null | grep -q "True"; then
    echo "✅ RDS instance is publicly accessible"
    PUBLIC_OK=true
else
    echo "❓ RDS instance is not publicly accessible or command failed"
    PUBLIC_OK=false
fi

# Try to connect with psql (without password)
echo "PostgreSQL connection test:"
if command -v psql >/dev/null 2>&1; then
    if PGCONNECT_TIMEOUT=5 psql -h "$ENDPOINT" -p "$PORT" -U "$USERNAME" -d "$DATABASE" -c "SELECT 1" >/dev/null 2>&1; then
        echo "✅ PostgreSQL connection successful"
        PSQL_OK=true
    else
        echo "❌ PostgreSQL connection failed (this might be normal if password authentication is required)"
        PSQL_OK=false
    fi
else
    echo "❌ psql command not found"
    PSQL_OK=false
fi

# Final verdict
echo ""
echo "VERDICT:"
if $DNS_OK && $PORT_OK && ($SG_ACCESS || $PUBLIC_OK); then
    echo "✅ YES - You should be able to connect to the RDS instance"
    echo "   If you still can't connect, check your username and password"
    exit 0
else
    echo "❌ NO - Connection to the RDS instance is likely blocked"
    
    if ! $DNS_OK; then
        echo "   → Check if the endpoint address is correct"
    fi
    
    if ! $PORT_OK; then
        echo "   → Check if you're on a network that allows outbound connections to port $PORT"
    fi
    
    if ! $SG_ACCESS && ! $PUBLIC_OK; then
        echo "   → Check if your IP address is allowed in the RDS security group"
        echo "   → Check if the RDS instance is in a public subnet with route to internet gateway (if public access is needed)"
    fi
    
    exit 1
fi
