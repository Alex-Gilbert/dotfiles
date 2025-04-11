# rds-sg-check.nu

let clusters = ["artiv-staging-cluster", "artiv-dev-cluster"]

# Loop through each RDS instance
$clusters | each { |cluster|
    let db = (
      aws rds describe-db-instances --db-instance-identifier $cluster --region us-east-2
      | from json
      | get DBInstances.0
    )

    print $"\n=== [( $cluster )] Security Group Analysis ==="
    let sg_list = $db.VpcSecurityGroups | get VpcSecurityGroupId

    $sg_list | each { |sg|
        let perms = (
          aws ec2 describe-security-groups --group-ids $sg --region us-east-2
          | from json
          | get SecurityGroups.0.IpPermissions
        )

        let allows_5432 = (
          $perms
          | where {|perm| $perm.IpProtocol == "tcp" and $perm.FromPort == 5432 and $perm.ToPort == 5432 }
        )

        if ($allows_5432 | is-empty) {
            print $"- SG ($sg) ❌ does NOT allow port 5432"
        } else {
            print $"- SG ($sg) ✅ ALLOWS port 5432!"
        }
    }
}
