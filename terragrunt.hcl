# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract the variables we need for easy access
   iam_name_prefix = local.account_vars.locals.iam_name_prefix
  account_name = local.account_vars.locals.account_name
  account_id   = local.account_vars.locals.aws_account_id
  aws_region   = local.region_vars.locals.aws_region
  aws_profile = "tf_${local.iam_name_prefix}_role"
  arn_role    = "arn:aws:iam::${local.account_id}:role/${local.aws_profile}"
  environment = local.environment_vars.locals.environment


  default_tags = {
    # Mandatory tags
    component      = "missing"
    productbilling = "missing"
    team           = "missing"

    # Optional tags with defaults
    automation  = "terragrunt-default"
    environment = "${local.environment_vars.locals.environment}"

    # Not user managed tags
    tf_repo           = "terraform-infra-${local.environment_vars.locals.environment}"
    tf_stage          = "${local.environment_vars.locals.environment}"
    tf_component_path = "${path_relative_to_include()}"
  }

  tags = merge(
    local.default_tags,
    lookup(local.account_vars, "tags", {}),
    lookup(local.region_vars, "tags", {}),
    lookup(local.environment_vars, "tags", {}),
  )

}

inputs = merge(
  local.region_vars.locals,
  local.environment_vars.locals,
)




# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = "${local.aws_region}"
  profile = "${local.aws_profile}"

  default_tags {
    tags = ${jsonencode(local.tags)}
  }
}
EOF
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"

  config = {
    region                 = "${local.aws_region}"
    bucket                 = "oxcloud-terraform-${local.account_vars.locals.aws_account_id}-state"
    key                    = "${path_relative_to_include()}/terraform.tfstate"
    encrypt                = true
    skip_bucket_versioning = true

    profile        = "${local.aws_profile}"
    dynamodb_table = "terraform-${local.environment_vars.locals.environment}-locks"   ###
    role_arn       = "${local.arn_role}" #REQUIRED for executions if we are using sts assume role
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

terraform {
  after_hook "show_plan" {
    commands = ["plan"]
    execute  = ["bash", "-c", "if [ -f terraform.plan ]; then terraform show -no-color terraform.plan > terraform_plan.hcl; fi"]
  }

  extra_arguments "retry_lock" {
    commands  = get_terraform_commands_that_need_locking()
    arguments = ["-lock-timeout=10m"]

  }

}



