# terraform {
#   backend "local" {

# 		path = "./state/terraform.tfstate"
# 	}
# }

terraform {
  backend "s3" {
	bucket = "yahya-terraform-backend"
    encrypt = true
	region = "us-east-1"
    key     = "terraform.tfstate"
  }
}



