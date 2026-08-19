// ############################################################
//    Execution SA for Soundboard Cloud Run App (ADT)
// ############################################################

resource "google_service_account" "soundboard_runner_adt" {
  depends_on   = [google_project_service.iam_api_adt]
  project      = var.project_id
  account_id   = "sa-soundboard-runner-adt"
  display_name = "Soundboard App Cloud Run Runner (ADT)"
}

// ############################################################
//    Service Account for External GHA Image Pusher (ADT)
// ############################################################

resource "google_service_account" "github_ar_pusher_adt" {
  depends_on   = [google_project_service.iam_api_adt]
  project      = var.project_id
  account_id   = "sa-gha-ar-pusher-adt"
  display_name = "GitHub Actions Artifact Registry Pusher (ADT)"
}