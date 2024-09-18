export
TF_WORKSPACE_KEY_PREFIX=codepipeline

us-east-1-test-account:
	$(eval export AWS_PROFILE=test-account)
	$(eval export AWS_REGION=us-east-1)
	$(eval export AWS_DYNAMODB_TABLE=terraform-backend.lock)
	$(eval export AWS_S3_BUCKET=yahya-test-control-tower-dev-terraform-backend-us-east-1)
	$(eval export ENV_NAME=test)
	@true



terraform-clean:
	rm -rf \
		terraform.tfstate.d \
		.terraform/environment \
		.terraform/terraform.tfstate

init: terraform-clean
	terraform init \
		-backend-config="bucket=${AWS_S3_BUCKET}" \
		-backend-config="workspace_key_prefix=${AWS_REGION}/${TF_WORKSPACE_KEY_PREFIX}" \
		-backend-config="dynamodb_table=${AWS_DYNAMODB_TABLE}" \
		-backend-config="region=${AWS_REGION}"
	- terraform workspace new ${ENV_NAME}
	terraform workspace select ${ENV_NAME}

show: init
	terraform show \
		-var-file=./${AWS_REGION}/${ENV_NAME}/terraform.tfvars \
		-var 'aws_profile=${AWS_PROFILE}' \
		-var 'aws_region=${AWS_REGION}'

plan: init
	terraform plan \
		-var-file=./${AWS_REGION}/${ENV_NAME}/terraform.tfvars \
		-var 'aws_profile=${AWS_PROFILE}' \
		-var 'aws_region=${AWS_REGION}'

apply: init
	terraform apply \
		-var-file=./${AWS_REGION}/${ENV_NAME}/terraform.tfvars \
		-var 'aws_profile=${AWS_PROFILE}' \
		-var 'aws_region=${AWS_REGION}'

destroy: init
	terraform destroy  \
		-var-file=./${AWS_REGION}/${ENV_NAME}/terraform.tfvars \
		-var 'aws_profile=${AWS_PROFILE}' \
		-var 'aws_region=${AWS_REGION}'
