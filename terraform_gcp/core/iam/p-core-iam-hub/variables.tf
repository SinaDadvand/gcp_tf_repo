variable "project_id" {
  type    = string
  default = "p-core-iam-hub"
}

variable "region" {
  type    = string
  default = "us-west1"
}

variable "zone" {
  type    = string
  default = "us-west1-a"
}

variable "admin_users" {
  type        = list(string)
  description = "List of user emails with platform admin access"
  default     = []
}