locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  # source = "git::https://${get_env("GH_USER", "")}:${get_env("GH_TOKEN", "")}@github.com/grycare/cloud_terraform_modules.git//network/vpc?ref=0.0.2"
  source = "../../../../../../oxcloud_terraform_modules/iam/modules/iam-user"
}

include "root" {
  path = find_in_parent_folders()
  //expose = true
}

inputs = {
  create_user = true
  create_iam_user_login_profile = true
  create_iam_access_key = true
  name = "peter"
  password_reset_required = true


  tags = {
    component      = "iam"
    env            = local.env_vars.locals.environment
    productbilling = "oxcloud"
    team           = "devops"
    terraform      = true
  }
}