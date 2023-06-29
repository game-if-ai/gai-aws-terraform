resource "aws_ssm_parameter" "stored_var" {
  name        = "/shared/${var.ssm_variable_name}"
  description = var.description
  type        = "String"
  value       = var.ssm_variable_value
  overwrite   = true
}