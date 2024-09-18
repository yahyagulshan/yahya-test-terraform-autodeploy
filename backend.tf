terraform {
  backend "local" {

		path = "./state/terraform.tfstate"
	}
}

# terraform {
#   backend "s3" {
#     encrypt = true
#     key     = "terraform.tfstate"
#   }
# }