terraform {
  source = "${path_relative_from_include()}/modules//frontend"
}

include {
  path = find_in_parent_folders()
}

locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  aws_region   = local.region_vars.locals.aws_region
  account_id   = local.account_vars.locals.aws_account_id
}

inputs = {
  region        = local.aws_region
  account_id    = local.account_id
}
