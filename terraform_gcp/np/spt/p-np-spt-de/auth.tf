resource "google_identity_platform_config" "auth_config" {
  project = var.project_id
  autodelete_anonymous_users = false
  authorized_domains = [
    "localhost",
    "${var.project_id}.firebaseapp.com",
    "${var.project_id}.web.app",
    "soundboard-app-fb-spt-1050996219084.us-west1.run.app",
    "soundboard-user-sina-spt-1050996219084.us-west1.run.app",
    "soundboard-user-cesar-spt-1050996219084.us-west1.run.app"
  ]
}
