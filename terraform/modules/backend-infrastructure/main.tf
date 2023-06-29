locals {
  namespace = "${var.env_name}-${var.project_name}"
}

module "api_firewall" {
  source     = "git::https://github.com/mentorpal/terraform-modules//modules/api-waf?ref=tags/v1.6.0"
  name       = "${local.namespace}-api"
  scope      = "REGIONAL"
  rate_limit = 1000

  disable_bot_protection_for_amazon_ips = true
  excluded_bot_rules = [
    "CategoryMonitoring",
  ]
  excluded_common_rules = [
    "SizeRestrictions_BODY",  # 8kb is not enough
    "CrossSiteScripting_BODY" # flags legit image upload attempts
  ]
  enable_logging = var.enable_api_firewall_logging
  aws_region     = var.aws_region
  tags           = var.env_tags
}

resource "aws_ssm_parameter" "api_firewall_ssm" {
  name  = "/${local.namespace}/api_firewall_arn"
  type  = "String"
  value = module.api_firewall.wafv2_webacl_arn
  tags  = var.env_tags
}