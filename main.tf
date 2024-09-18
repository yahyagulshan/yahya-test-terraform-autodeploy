provider "aws" {
  region = "us-east-1"
}

module "control_tower" {
  source = "./modules/control_tower"

  ou_names        = ["SecurityOU", "SandboxOU"]
  accounts        = {
    audit      = { email = "audit@example.com", ou = "SecurityOU" }
    logarchive = { email = "logarchive@example.com", ou = "SecurityOU" }
    sandbox    = { email = "sandbox@example.com", ou = "SandboxOU" }
  }
  s3_bucket_name  = "control-tower-centralized-logging"
}

# Outputs for reference
output "s3_bucket_name" {
  value = module.control_tower.s3_bucket_name
}






