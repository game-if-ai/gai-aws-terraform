terraform {
  source = "git@github.com:mentorpal/terraform-modules//modules/gitflow_cicd_pipeline?ref=v1.6.16"
}

include {
  path = find_in_parent_folders()
}

dependency "ssm_var_store"{
  config_path = "../../ssm-var-store"
  skip_outputs = true
}

dependencies {
  paths = ["../../ssm-var-store"]
}


locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  global_secret_vars = read_terragrunt_config(find_in_parent_folders("global_secrets.hcl"))
  aws_region   = local.region_vars.locals.aws_region
  account_id   = local.account_vars.locals.aws_account_id
  codestar_connection_arn = local.global_secret_vars.locals.codestar_connection_arn
}

inputs = {
    codestar_connection_arn = local.codestar_connection_arn
    project_name            = "gai-code-executor"
    github_repo_name        = "gai-code-executor"
    github_org              = "game-if-ai"
    github_branch_dev       = "main"
    github_branch_release   = "release"

    # reference: https://github.com/cloudposse/terraform-aws-codebuild#inputs
    build_image  = "aws/codebuild/standard:7.0"
    deploy_image = "aws/codebuild/standard:7.0"
    # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html
    build_compute_type   = "BUILD_GENERAL1_MEDIUM"
    deploys_compute_type = "BUILD_GENERAL1_MEDIUM"
    build_cache_type     = "NO_CACHE"
    deploy_cache_type    = "NO_CACHE"

    build_buildspec       = "cicd/buildspec.yml"
    deploy_dev_buildspec  = "cicd/deployspec-dev.yml"
    deploy_qa_buildspec   = "cicd/deployspec-qa.yml"
    deploy_prod_buildspec = "cicd/deployspec-prod.yml"

    builds_privileged_mode  = false
    deploys_privileged_mode = false

    enable_e2e_tests            = false
    enable_status_notifications = true

    tags = {
        Source  = "terraform"
        Project = "gameifai"
    }
}
