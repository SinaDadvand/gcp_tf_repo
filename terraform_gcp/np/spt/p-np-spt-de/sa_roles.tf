// ############################################################
//    Assigning Runtime Permissions to Soundboard Runner SA (SPT)
// ############################################################

resource "google_project_iam_member" "soundboard_logs_spt" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.soundboard_runner_spt.email}"
}

resource "google_project_iam_member" "soundboard_ar_reader_spt" {
  depends_on = [google_project_service.artifactregistry_api_spt]
  project    = var.project_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.soundboard_runner_spt.email}"
}

// ############################################################
//    Granting Access to ALL Secret Manager Secrets for Cloud Run SA
// ############################################################

resource "google_project_iam_member" "soundboard_all_secrets_access_spt" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.soundboard_runner_spt.email}"
}

// ############################################################
//    IAM Permissions for WIF Image Pusher Service Account
// ############################################################

// 1. Artifact Registry Writer (Allows pushing docker images)
resource "google_artifact_registry_repository_iam_member" "pusher_ar_writer_spt" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.soundboard_repo_spt.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.github_ar_pusher_spt.email}"
}

// 2. Allow GitHub WIF Principal to impersonate this Service Account
resource "google_service_account_iam_member" "wif_pusher_impersonation_spt" {
  service_account_id = google_service_account.github_ar_pusher_spt.name
  role               = "roles/iam.workloadIdentityUser"
  // GitHub Actions Workload Identity Federation mapping for soundboard_app repository
  member             = "principalSet://iam.googleapis.com/projects/304516994920/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/SinaDadvand/soundboard_app"
}

// ############################################################
//    Cloud Run Deployment Permissions for Pusher SA
// ############################################################

// 1. Grant Cloud Run Developer role (to manage services and revisions)
resource "google_project_iam_member" "pusher_run_developer_spt" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.github_ar_pusher_spt.email}"
}

// 2. Grant Service Account User role on the runner SA (allows pusher to deploy Cloud Run with runner SA attached)
resource "google_service_account_iam_member" "pusher_act_as_runner_spt" {
  service_account_id = google_service_account.soundboard_runner_spt.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_ar_pusher_spt.email}"
}
