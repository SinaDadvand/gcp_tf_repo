variable "project_id" {
  description = "Target workload GCP Project ID where VM will be deployed"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-west1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-west1-a"
}

variable "terraform_state_bucket_name" {
  description = "Name for the Bucket to house Terraform state file"
  type        = string
  default     = "state_bucket"
}

variable "instance_name" {
  description = "Name for the Compute Engine instance"
  type        = string
  default     = "linux-practice-vm"
}