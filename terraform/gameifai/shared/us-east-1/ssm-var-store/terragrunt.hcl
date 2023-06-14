terraform {
  source = "../../../../modules/ssm-storage"
}

include {
  path = find_in_parent_folders()
}

dependency "sns_slack_notification"{
  config_path = "../sns-slack-notification"
}

dependencies {
  paths = ["../sns-slack-notification"]
}

locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  global_secret_vars = read_terragrunt_config(find_in_parent_folders("global_secrets.hcl"))
  aws_region   = local.region_vars.locals.aws_region
  account_id   = local.account_vars.locals.aws_account_id
  cicd_slack_webhook = local.global_secret_vars.locals.cicd_slack_webhook
}

inputs = {
  ssm_variable_name = "sns_cicd_alert_topic_arn"
  ssm_variable_value = dependency.sns_slack_notification.outputs.this_slack_topic_arn
}
