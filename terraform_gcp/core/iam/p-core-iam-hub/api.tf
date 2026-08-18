# Enable IAM API
resource "google_project_service" "iam_api" {
  project            = var.project_id
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

# Enable Cloud Resource Manager API (Required for IAM policy bindings)
resource "google_project_service" "resource_manager_api" {
  project            = var.project_id
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}