# Cluster will be spinned up using terraform
#  

## Use terraform version v0.12.16 and terragrunt version v0.21.6

## Sources directory contains all common infrastructure. Terragrunt directory contains all environment specific variables. For each application in environment only one terragrunt.hcl file is created. Additionaly common settings are in common.tfvars

## To run terragrunt you need to set environment variables:
 - ARM_SUBSCRIPTION_ID
 - ARM_CLIENT_ID (app_id of service principal)
 - ARM_CLIENT_SECRET (secret of service principal)
 - ARM_TENANT_ID
 - ARM_ACCESS_KEY (azure storage key with terraform state)
 - TF_VAR_postgres_admin_password
 - TF_VAR_client_id (service principal for k8s app id)
 - TF_VAR_client_secret (service principal for k8s secret)

 # You can now create the test environment by going to terragrunt/test directory and running:
 - terragrunt plan-all
 - terragrunt apply-all
