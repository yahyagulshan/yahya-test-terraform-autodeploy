output "s3_bucket_name" {
  value = aws_s3_bucket.control_tower_log_bucket.bucket
}

output "security_ou_id" {
  value = aws_organizations_organizational_unit.security_ou.id
}

output "sandbox_ou_id" {
  value = aws_organizations_organizational_unit.sandbox_ou.id
}
