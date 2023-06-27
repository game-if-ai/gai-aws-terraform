variable "env_name" {
  type        = string
  description = ""
}
variable "project_name" {
  type        = string
  description = ""
}

variable "enable_api_firewall_logging" {
  type        = bool
  description = ""
  default = true
}
variable "env_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit`,`XYZ`)"
}
variable "aws_region" {
  type        = string
  description = ""
}
