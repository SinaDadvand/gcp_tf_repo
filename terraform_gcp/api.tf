# Enable Compute Engine API
resource "google_project_service" "compute_api" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}