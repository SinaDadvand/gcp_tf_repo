// ############################################################
//    Enabling GCP APIs for p-core-iam-hub
// ############################################################

resource "google_project_service" "iam_api" {
  project            = var.project_id
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "resource_manager_api" {
  project            = var.project_id
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudidentity_api" {
  project            = var.project_id
  service            = "cloudidentity.googleapis.com"
  disable_on_destroy = false
}