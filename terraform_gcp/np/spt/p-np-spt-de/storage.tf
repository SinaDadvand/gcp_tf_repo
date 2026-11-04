// ############################################################
//    Google Cloud Storage (GCS) Configuration for SPT
// ############################################################

// ============================================================
// [SOUNDBOARD APP] Per-User Dedicated Audio Storage Buckets
// ============================================================
// Each user (Sina, Cesar) gets a path-isolated GCS bucket to store
// custom sound clips.
// Cloud Run services mount these buckets directly via Cloud Storage FUSE.

resource "google_storage_bucket" "soundboard_user_audio" {
  for_each                    = var.soundboard_users
  name                        = "${var.project_id}-audio-${each.key}"
  location                    = var.region
  project                     = var.project_id
  force_destroy               = false
  uniform_bucket_level_access = true

  labels = {
    user    = each.key
    env     = "spt"
    service = "soundboard"
    app     = "soundboard-app"
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

// [SOUNDBOARD APP] User GUI Access
// Grants each individual user full object administration on their own bucket ONLY,
// enabling direct drag-and-drop file uploads via the Google Cloud Console GUI.
resource "google_storage_bucket_iam_member" "soundboard_user_bucket_access" {
  for_each = var.soundboard_users
  bucket   = google_storage_bucket.soundboard_user_audio[each.key].name
  role     = "roles/storage.objectAdmin"
  member   = "user:${each.value.email}"
}

// [SOUNDBOARD APP] Cloud Run Runtime FUSE Mount Access
// Grants the shared Cloud Run runner Service Account objectAdmin on each bucket
// to allow the Cloud Storage FUSE volume mount to read/write audio and config files.
resource "google_storage_bucket_iam_member" "soundboard_user_runner_access" {
  for_each = var.soundboard_users
  bucket   = google_storage_bucket.soundboard_user_audio[each.key].name
  role     = "roles/storage.objectAdmin"
  member   = "serviceAccount:${google_service_account.soundboard_runner_spt.email}"
}
