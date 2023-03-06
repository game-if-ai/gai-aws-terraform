terraform {
  source = "${path_relative_from_include()}/modules//deploy-iam-user"
}

include {
  path = find_in_parent_folders()
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
}

inputs = {
  name = "cicd-github-actions-${local.env}"
}
