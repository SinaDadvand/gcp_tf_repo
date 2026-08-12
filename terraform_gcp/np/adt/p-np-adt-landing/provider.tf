terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Configures remote state storage in your dedicated management bucket
  backend "gcs" {
    bucket = "p-tf-state-mgmt-bucket" #"REPLACE_WITH_YOUR_BUCKET_NAME" # e.g., tf-state-mgmt-1722800000-bucket
    prefix = "np/adt/p-np-adt-landing/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}