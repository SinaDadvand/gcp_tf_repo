// ############################################################
//    IAM Role Assignments for Central Service Accounts
// ############################################################

resource "google_project_iam_member" "sec_auditor_viewer" {
  depends_on = [google_project_service.resource_manager_api]
  project    = var.project_id
  role       = "roles/viewer"
  member     = "serviceAccount:${google_service_account.sec_auditor.email}"
}