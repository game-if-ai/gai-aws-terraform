# must be in AWS certificate manager:
aws_acm_certificate_domain = "gameifai.org"

# e.g. us-east-1
aws_region = "us-east-1"

# usualy name as `aws_acm_certificate_domain` with . at the end
aws_route53_zone_name = "gameifai.org"

# namespace to prefix all things your app
eb_env_namespace = "gameifai"
eb_env_name      = "gameifai"
eb_env_stage = "qa"

site_domain_name = "qa.gameifai.org"