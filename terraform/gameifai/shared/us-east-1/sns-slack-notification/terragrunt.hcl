terraform {
  source = "git@github.com:mentorpal/terraform-modules//modules/notify-slack?ref=tags/v1.6.1"
}

include {
  path = find_in_parent_folders()
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
    create_sns_topic = true
    sns_topic_name   = "slack-cicd-alerts"

    lambda_function_name = "notify-slack-cicd"
    lambda_description	 = "forward SNS messages to Slack"

    slack_webhook_url = local.cicd_slack_webhook
    slack_channel     = "learning-science-cicd"
    slack_username    = "uscictlsalerts"
}
