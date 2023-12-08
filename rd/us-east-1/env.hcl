# Set common variables for the environment. This is automatically pulled in in the root terragrunt.hcl configuration to
# feed forward to the child modules.
locals {
  environment = "rd"
  #kms_arn = "fill_in_the_kms_arn"
}