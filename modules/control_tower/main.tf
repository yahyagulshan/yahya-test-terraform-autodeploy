# Fetch AWS Organization details
data "aws_organizations_organization" "org" {}

# Organizational Units (OUs)
resource "aws_organizations_organizational_unit" "security_ou" {
  name      = var.ou_names[0]
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "sandbox_ou" {
  name      = var.ou_names[1]
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

# Accounts Creation
resource "aws_organizations_account" "audit" {
  email     = var.accounts["audit"].email
  name      = "Audit"
  role_name = "OrganizationAccountAccessRole"
}

resource "aws_organizations_account" "logarchive" {
  email     = var.accounts["logarchive"].email
  name      = "LogArchive"
  role_name = "OrganizationAccountAccessRole"
}

resource "aws_organizations_account" "sandbox" {
  email     = var.accounts["sandbox"].email
  name      = "Sandbox"
  role_name = "OrganizationAccountAccessRole"
}

# S3 Bucket for centralized logging
resource "aws_s3_bucket" "control_tower_log_bucket" {
  bucket = var.s3_bucket_name

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# S3 Bucket Policy for logging
resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.control_tower_log_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "s3:GetBucketAcl"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Resource = "${aws_s3_bucket.control_tower_log_bucket.arn}"
      },
      {
        Action    = "s3:PutObject"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Resource = "${aws_s3_bucket.control_tower_log_bucket.arn}/AWSLogs/*"
      }
    ]
  })
}

# Move Accounts to OUs using AWS CLI (local-exec)
resource "null_resource" "move_audit_account" {
  provisioner "local-exec" {
    command = "aws organizations move-account --account-id ${aws_organizations_account.audit.id} --source-parent-id ${data.aws_organizations_organization.org.roots[0].id} --destination-parent-id ${aws_organizations_organizational_unit.security_ou.id}"
  }
  depends_on = [aws_organizations_account.audit, aws_organizations_organizational_unit.security_ou]
}

resource "null_resource" "move_logarchive_account" {
  provisioner "local-exec" {
    command = "aws organizations move-account --account-id ${aws_organizations_account.logarchive.id} --source-parent-id ${data.aws_organizations_organization.org.roots[0].id} --destination-parent-id ${aws_organizations_organizational_unit.security_ou.id}"
  }
  depends_on = [aws_organizations_account.logarchive, aws_organizations_organizational_unit.security_ou]
}

resource "null_resource" "move_sandbox_account" {
  provisioner "local-exec" {
    command = "aws organizations move-account --account-id ${aws_organizations_account.sandbox.id} --source-parent-id ${data.aws_organizations_organization.org.roots[0].id} --destination-parent-id ${aws_organizations_organizational_unit.sandbox_ou.id}"
  }
  depends_on = [aws_organizations_account.sandbox, aws_organizations_organizational_unit.sandbox_ou]
}

# SCP Policy Definition (prevents CloudTrail deletion)
resource "aws_organizations_policy" "deny_cloudtrail_deletion" {
  name = "DenyCloudTrailDeletion"
  content = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "cloudtrail:DeleteTrail",
        "cloudtrail:StopLogging"
      ],
      "Resource": "*"
    }
  ]
}
EOF
  type = "SERVICE_CONTROL_POLICY"
}

# Attach SCP to each account
resource "aws_organizations_policy_attachment" "audit_scp" {
  policy_id = aws_organizations_policy.deny_cloudtrail_deletion.id
  target_id = aws_organizations_account.audit.id
}

resource "aws_organizations_policy_attachment" "logarchive_scp" {
  policy_id = aws_organizations_policy.deny_cloudtrail_deletion.id
  target_id = aws_organizations_account.logarchive.id
}

resource "aws_organizations_policy_attachment" "sandbox_scp" {
  policy_id = aws_organizations_policy.deny_cloudtrail_deletion.id
  target_id = aws_organizations_account.sandbox.id
}