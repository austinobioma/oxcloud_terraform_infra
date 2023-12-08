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

dependency "policy" {
  config_path = "../../policies/austin-policy/"
  mock_outputs = {
    arn = "arn-234fu48j"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  create_user = true
  create_iam_user_login_profile = true
  create_iam_access_key = true
  name = "austin"
  password_reset_required = true
  policy_arns = [
    "${dependency.policy.outputs.arn}"
  ]


  tags = {
    component      = "iam"
    env            = local.env_vars.locals.environment
    productbilling = "oxcloud"
    team           = "devops"
    terraform      = true
  }
}