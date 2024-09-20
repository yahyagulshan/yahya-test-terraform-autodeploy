provider "aws" {
  region = "us-east-1"
}

# Fetch organization details
data "aws_organizations_organization" "main" {}

# Create Organizational Units
resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = data.aws_organizations_organization.main.roots[0].id
}

resource "aws_organizations_organizational_unit" "logarchive" {
  name      = "LogArchive"
  parent_id = data.aws_organizations_organization.main.roots[0].id
}

resource "aws_organizations_organizational_unit" "audit" {
  name      = "Audit"
  parent_id = data.aws_organizations_organization.main.roots[0].id
}

# Create AWS Accounts with unique emails
resource "aws_organizations_account" "sandbox" {
  name      = "sandbox"
  email     = "sandbox-unique@example.com"
  parent_id = aws_organizations_organizational_unit.sandbox.id
}

resource "aws_organizations_account" "logarchive" {
  name      = "logarchive"
  email     = "logarchive-unique@example.com"
  parent_id = aws_organizations_organizational_unit.logarchive.id
}

resource "aws_organizations_account" "audit" {
  name      = "audit"
  email     = "audit-unique@example.com"
  parent_id = aws_organizations_organizational_unit.audit.id
}

# Create S3 Bucket for Logging
resource "aws_s3_bucket" "config_bucket" {
  bucket_prefix = "config-bucket-"
}

# S3 Bucket Policy for AWS Config
resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.config_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action = "s3:PutObject",
        Resource = "${aws_s3_bucket.config_bucket.arn}/*"
      }
    ]
  })
}

# Create IAM Role for AWS Config
resource "aws_iam_role" "config_role" {
  name = "config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach IAM Policy to Role
resource "aws_iam_role_policy_attachment" "config_policy" {
  role      = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole" # Ensure this policy exists and is attachable
}

# Create AWS Config Configuration Recorder
resource "aws_config_configuration_recorder" "example" {
  name     = "example-recorder"
  role_arn  = aws_iam_role.config_role.arn
  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

# Create AWS Config Delivery Channel
resource "aws_config_delivery_channel" "example" {
  name           = "example-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
}

# Start Configuration Recorder
resource "aws_config_configuration_recorder_status" "example" {
  name      = aws_config_configuration_recorder.example.name
  is_enabled = true
}

# Example Config Rule
resource "aws_config_config_rule" "example" {
  name        = "example-config-rule"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
}
