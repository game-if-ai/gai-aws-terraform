# create iam user for external cicd tools (github actions),
# and export credentials to SSM

resource "aws_iam_user" "confidential" {
  name = var.name
}

resource "aws_iam_access_key" "access_key" {
  user = aws_iam_user.confidential.name
}

resource "aws_iam_user_policy" "confidential_manage_pool_users" {
  name = var.name
  user = aws_iam_user.confidential.name
  # https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazoncognitouserpools.html
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "apigateway:*",
        "cloudformation:*",
        "cloudfront:Get*",
        "cloudfront:CreateInvalidation",
        "cloudwatch:*",
        "dynamodb:*",
        "ecr:*",
        "ecs:*",
        "iam:GetRole",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:PutRolePolicy",
        "iam:PassRole",
        "execute-api:*",
        "events:*",
        "kinesis:*",
        "kms:*",
        "lambda:*",
        "logs:*",
        "s3:*",
        "sqs:*",
        "sns:*",
        "ses:*",
        "secretsmanager:Describe*",
        "secretsmanager:Get*",
        "secretsmanager:List*",
        "states:*",
        "wafv2:*",
        "xray:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ssm:Describe*",
        "ssm:Get*",
        "ssm:List*"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ssm:*:*:parameter/*"
    }
  ]
}
EOF
}

resource "aws_ssm_parameter" "access_key" {
  name        = "/shared/gameifai/cicd/access_key"
  description = "Access key ID for CICD pipelines (Github Actions)"
  type        = "SecureString"
  value       = aws_iam_access_key.access_key.id

  tags = var.tags
}

resource "aws_ssm_parameter" "secret_key" {
  name        = "/shared/gameifai/cicd/secret_key"
  description = "Secret (Access) key for CICD pipelines"
  type        = "SecureString"
  value       = aws_iam_access_key.access_key.secret

  tags = var.tags
}

output "user_arn" {
  value = aws_iam_user.confidential.arn
}