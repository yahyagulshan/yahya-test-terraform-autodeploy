######################
# old code for Ec2
########################

# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "4.52.0"
#     }
#     random = {
#       source  = "hashicorp/random"
#       version = "3.4.3"
#     }
#   }
#   required_version = ">= 1.1.0"
# }

# provider "aws" {
#   region = "us-east-1"
# }

# resource "random_pet" "sg" {}

# data "aws_ami" "ubuntu" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["099720109477"] # Canonical
# }

# resource "aws_instance" "web" {
#   ami                    = data.aws_ami.ubuntu.id
#   instance_type          = "t2.micro"
#   vpc_security_group_ids = [aws_security_group.web-sg.id]

#   user_data = <<-EOF
#               #!/bin/bash
#               apt-get update
#               apt-get install -y apache2
#               sed -i -e 's/80/8080/' /etc/apache2/ports.conf
#               echo "Hello World" > /var/www/html/index.html
#               systemctl restart apache2
#               EOF
# }

# resource "aws_security_group" "web-sg" {
#   name = "${random_pet.sg.id}-sg"
#   ingress {
#     from_port   = 8080
#     to_port     = 8080
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   // connectivity to ubuntu mirrors is required to run `apt-get update` and `apt-get install apache2`
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# output "web-address" {
#   value = "${aws_instance.web.public_dns}:8080"
# }


######################################
## new code for control-tower
######################################

provider "aws" {
  region = "us-east-1"
}

# Fetch organization details
data "aws_organizations_organization" "main" {}

# Create Organizational Units
# organizational unit-1
resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = data.aws_organizations_organization.main.roots[0].id
}

# organizational unit-2
resource "aws_organizations_organizational_unit" "Security" {
  name      = "Security"
  parent_id = data.aws_organizations_organization.main.roots[0].id
}

# Create AWS Accounts with unique emails
resource "aws_organizations_account" "sandbox" {
  name      = "sandbox"
  email     = "sandbox-unique@example.com"
  parent_id = aws_organizations_organizational_unit.sandbox.id
}

resource "aws_organizations_account" "Security" {
  name      = "logarchive"
  email     = "logarchive-unique@example.com"
  parent_id = aws_organizations_organizational_unit.logarchive.id
}

resource "aws_organizations_account" "Security" {
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