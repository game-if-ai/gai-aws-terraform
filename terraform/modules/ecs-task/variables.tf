variable "region" {
  type    = string
  default = "us-east-1"
}

variable "container_name" {
  type = string
}

variable "task_name" {
  type = string
}
variable "account_id" {
  type = string
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the resource."
  default     = {}
}
