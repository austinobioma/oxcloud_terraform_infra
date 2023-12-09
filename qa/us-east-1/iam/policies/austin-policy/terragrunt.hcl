locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  instance_policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ec2:Describe*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  POLICY
}

terraform {
  # source = "git::https://${get_env("GH_USER", "")}:${get_env("GH_TOKEN", "")}@github.com/grycare/cloud_terraform_modules.git//network/vpc?ref=0.0.2"
  source = "git::git@github.com:austinobioma/oxcloud_terraform_modules.git//iam/modules/iam-policy?ref=v0.1.0"
}

include "root" {
  path = find_in_parent_folders()
  //expose = true
}

inputs = {
  create_policy = true
  name = "austin_${local.env_vars.locals.environment}_policy"
  policy = jsondecode(local.instance_policy)
 


  tags = {
    component      = "iam"
    env            = local.env_vars.locals.environment
    productbilling = "oxcloud"
    team           = "devops"
    terraform      = true
  }
}