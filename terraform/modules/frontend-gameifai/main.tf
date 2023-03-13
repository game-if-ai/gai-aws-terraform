# some resources must be created in N.Virginia
provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

###
# Find a certificate for our domain that has status ISSUED
# NOTE that for now, this infra depends on managing certs INSIDE AWS/ACM
###
data "aws_acm_certificate" "cdn" {
  provider = aws.us-east-1
  domain   = var.aws_acm_certificate_domain
  statuses = ["ISSUED"]
}

locals {
  namespace = "${var.eb_env_namespace}-${var.eb_env_stage}"

  static_page_asset_aliases = [var.site_domain_name]
}

######
# CloudFront distro in front of s3
#

# the default policy does not include query strings as cache keys
resource "aws_cloudfront_cache_policy" "cdn_s3_cache" {
  name        = "${local.namespace}-cdn-s3-origin-cache-policy"
  min_ttl     = 0
  max_ttl     = 31536000 # 1yr
  default_ttl = 2592000  # 1 month

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "cdn_s3_request" {
  name = "${local.namespace}-cdn-s3-origin-request-policy"

  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function
resource "aws_cloudfront_function" "cf_fn_origin_root" {
  # Note this is not a lambda function, but a CloudFront Function!
  name    = "${local.namespace}-cffn-origin"
  runtime = "cloudfront-js-1.0"
  comment = "Rewrites root s3 bucket requests to index.html for all apps (home, chat, admin)"
  publish = true
  code    = file("${path.module}/scripts/gai-rewrite-default-index-s3-origin.js")
}

# fronts just an s3 bucket with static assets (javascript, css, ...) for frontend apps hosting
module "cdn_static_assets" {
  source                             = "git::https://github.com/cloudposse/terraform-aws-cloudfront-s3-cdn.git?ref=tags/0.82.4"
  acm_certificate_arn                = data.aws_acm_certificate.cdn.arn
  aliases                            = local.static_page_asset_aliases
  allowed_methods                    = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
  block_origin_public_access_enabled = true # so only CDN can access it
  # having a default cache policy made the apply fail:
  # cache_policy_id                   = resource.aws_cloudfront_cache_policy.cdn_s3_cache.id
  # origin_request_policy_id          = resource.aws_cloudfront_cache_policy.cdn_s3_request.id
  cached_methods                    = ["GET", "HEAD"]
  cloudfront_access_logging_enabled = false
  compress                          = true

#   default_root_object = "/home/index.html"
  dns_alias_enabled   = true
  environment         = var.aws_region

  # cookies are used in graphql right? but seems to work with "none":
  forward_cookies = "none"

  # from the docs: "Amazon S3 returns this index document when requests are made to the root domain or any of the subfolders"
  # if this is the case then aws_lambda_function.cf_fn_origin_root is not required
  index_document      = "index.html"
  ipv6_enabled        = true
  log_expiration_days = 30
  name                = var.eb_env_name
  namespace           = var.eb_env_namespace

  ordered_cache = [
    {
      target_origin_id                  = "" # default s3 bucket
      path_pattern                      = "*"
      viewer_protocol_policy            = "redirect-to-https"
      min_ttl                           = 0
      default_ttl                       = 2592000  # 1 month
      max_ttl                           = 31536000 # 1yr
      forward_query_string              = false
      forward_cookies                   = "none"
      forward_cookies_whitelisted_names = []

      viewer_protocol_policy      = "redirect-to-https"
      cached_methods              = ["GET", "HEAD"]
      allowed_methods             = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
      compress                    = true
      forward_header_values       = []
      forward_query_string        = false
      cache_policy_id             = resource.aws_cloudfront_cache_policy.cdn_s3_cache.id
      origin_request_policy_id    = resource.aws_cloudfront_origin_request_policy.cdn_s3_request.id
      lambda_function_association = []
      trusted_signers             = []
      trusted_key_groups          = []
      response_headers_policy_id  = ""
      function_association = [{
        # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#function-association
        event_type   = "viewer-request"
        function_arn = aws_cloudfront_function.cf_fn_origin_root.arn
      }]
    }
  ]

  # comment out to create a new bucket:
  # origin_bucket	= ""
  origin_force_destroy = true
  parent_zone_name     = var.aws_route53_zone_name
  # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html
  price_class = "PriceClass_100"
  # this are artifacts generated from github code, no need to version them:
  viewer_protocol_policy = "redirect-to-https"
    stage       = var.eb_env_stage

#   versioning_enabled     = true # test backup
#   web_acl_id             = module.cdn_firewall.wafv2_webacl_arn
}
