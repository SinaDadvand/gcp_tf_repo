// ############################################################
//    Central Security Auditor Service Account
// ############################################################

resource "google_service_account" "sec_auditor" {
  depends_on   = [google_project_service.iam_api]
  project      = var.project_id
  account_id   = "sec-auditor"
  display_name = "Central Security Auditor"
}