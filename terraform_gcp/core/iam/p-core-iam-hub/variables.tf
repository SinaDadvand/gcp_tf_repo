// ############################################################
//    Variables for Core IAM Hub
// ############################################################

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

variable "customer_id" {
  type        = string
  description = "Google Workspace / Cloud Identity Customer ID"
  default     = "C0123456" # Replace with your actual Cloud Identity Customer ID
}