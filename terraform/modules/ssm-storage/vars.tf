variable "description" {
  type        = string
  description = "ssm var description"
  default = ""
}

variable "ssm_variable_name" {
  type        = string
  description = "ssm variable name"
}

variable "ssm_variable_value" {
  type        = string
  description = "ssm variable value"
}
