terraform {
  source = "../../../../modules/backend-infrastructure"
}

include {
  path = find_in_parent_folders()
}

locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  global_secret_vars = read_terragrunt_config(find_in_parent_folders("global_secrets.hcl"))
  aws_region   = local.region_vars.locals.aws_region
  account_id   = local.account_vars.locals.aws_account_id
  codestar_connection_arn = local.global_secret_vars.locals.codestar_connection_arn
  env_name = local.env_vars.locals.environment
}

inputs = {
    env_name = local.env_name
    project_name = "gameifai"
    aws_region = local.aws_region
}
