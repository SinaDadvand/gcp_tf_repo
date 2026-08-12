variable "project_id" {
  type    = string
  default = "p-np-adt-de"
}

variable "region" {
  type    = string
  default = "us-west1"
}

variable "zone" {
  type    = string
  default = "us-west1-a"
}

variable "instance_name" {
  description = "Name for the Compute Engine instance"
  type        = string
  default     = "linux-practice-vm-de"
}