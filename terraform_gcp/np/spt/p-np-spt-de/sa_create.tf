// ############################################################
//    Service Accounts for p-np-spt-de
// ############################################################

resource "google_service_account" "soundboard_runner_spt" {
  depends_on   = [google_project_service.iam_api_spt]
  project      = var.project_id
  account_id   = "sa-soundboard-runner-spt"
  display_name = "Cloud Run Service Account for SPT Soundboard App"
}

resource "google_service_account" "github_ar_pusher_spt" {
  depends_on   = [google_project_service.iam_api_spt]
  project      = var.project_id
  account_id   = "sa-gha-ar-pusher-spt"
  display_name = "GitHub Actions Artifact Registry Pusher SA for SPT"
}
