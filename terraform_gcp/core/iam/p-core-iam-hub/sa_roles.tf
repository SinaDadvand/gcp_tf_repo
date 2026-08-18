# Grant Central Runner Service Usage Admin on State Management Project
resource "google_project_iam_member" "gha_runner_state_mgmt" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageAdmin"
  member  = "serviceAccount:${google_service_account.central_gha_runner.email}"
}

# Grant Security Auditor Viewer permissions
resource "google_project_iam_member" "sec_auditor_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.sec_auditor.email}"
}