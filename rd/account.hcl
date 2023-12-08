# Set account-wide variables. These are automatically pulled in to configure the remote state bucket in the root
# terragrunt.hcl configuration.
locals {
  account_name    = "Real Cloud"
  aws_account_id  = "011138670495"
  iam_name_prefix = "oxcloud"

  aws_profile = "tf_${local.iam_name_prefix}_role"
  arn_role    = "arn:aws:iam::${local.aws_account_id}:role/${local.aws_profile}"
}
