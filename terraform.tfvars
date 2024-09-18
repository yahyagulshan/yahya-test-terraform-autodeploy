accounts = {
  "audit" = { email = "audit@example.com", ou = "SecurityOU" },
  "logarchive" = { email = "logarchive@example.com", ou = "SecurityOU" },
  "sandbox" = { email = "sandbox@example.com", ou = "SandboxOU" }
}

ou_names = ["SecurityOU", "SandboxOU"]
s3_bucket_name = "control-tower-centralized-logging"
