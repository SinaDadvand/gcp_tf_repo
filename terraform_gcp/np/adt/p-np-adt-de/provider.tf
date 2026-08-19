// ############################################################
//    Provider & GCS Backend for p-np-adt-de
// ############################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "p-tf-state-mgmt-bucket"
    prefix = "np/adt/p-np-adt-de/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}