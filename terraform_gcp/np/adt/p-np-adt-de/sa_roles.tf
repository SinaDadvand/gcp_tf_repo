// ############################################################
//    Assigning Runtime Permissions to Soundboard Runner SA (ADT)
// ############################################################

resource "google_project_iam_member" "soundboard_logs_adt" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.soundboard_runner_adt.email}"
}

resource "google_project_iam_member" "soundboard_ar_reader_adt" {
  depends_on = [google_project_service.artifactregistry_api_adt]
  project    = var.project_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.soundboard_runner_adt.email}"
}


// ############################################################
//    Granting Access to Discord Bot Secret for Cloud Run SA
// ############################################################

resource "google_secret_manager_secret_iam_member" "soundboard_discord_secret_access_adt" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.discord_bot_token_adt.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.soundboard_runner_adt.email}"
}

// ############################################################
//    IAM Permissions for WIF Image Pusher Service Account
// ############################################################

// 1. Artifact Registry Writer (Allows pushing docker images)
resource "google_artifact_registry_repository_iam_member" "pusher_ar_writer_adt" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.soundboard_repo_adt.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.github_ar_pusher_adt.email}"
}

// 2. Allow GitHub WIF Principal to impersonate this Service Account
resource "google_service_account_iam_member" "wif_pusher_impersonation" {
  service_account_id = google_service_account.github_ar_pusher_adt.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/304516994920/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/YOUR_GITHUB_USERNAME/soundboard_app"
}