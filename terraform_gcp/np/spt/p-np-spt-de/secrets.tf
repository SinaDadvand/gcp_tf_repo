// ############################################################
//    Secret Manager Secrets for p-np-spt-de
// ############################################################

resource "google_secret_manager_secret" "discord_bot_token_spt" {
  depends_on = [google_project_service.secretmanager_api_spt]
  project    = var.project_id
  secret_id  = "discord-bot-token-spt"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "discord_bot_token_spt_version" {
  secret      = google_secret_manager_secret.discord_bot_token_spt.id
  secret_data = "dummy-discord-bot-token-spt" # Placeholder, should be managed securely
}

resource "google_secret_manager_secret" "firebase_api_key_spt" {
  depends_on = [google_project_service.secretmanager_api_spt]
  project    = var.project_id
  secret_id  = "firebase-api-key-spt"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "firebase_api_key_spt_version" {
  secret      = google_secret_manager_secret.firebase_api_key_spt.id
  secret_data = "dummy-firebase-api-key-spt" # Placeholder, should be managed securely
}

// ############################################################
//   Per-User Discord Bot Token Secrets (soundboard_user_*)
// ############################################################

resource "google_secret_manager_secret" "soundboard_user_discord_token" {
  depends_on = [google_project_service.secretmanager_api_spt]
  for_each   = var.soundboard_users
  project    = var.project_id
  secret_id  = "soundboard_user_discord_token_${each.key}_spt"

  labels = {
    user = each.key
    env  = "spt"
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "soundboard_user_discord_token_version" {
  for_each    = var.soundboard_users
  secret      = google_secret_manager_secret.soundboard_user_discord_token[each.key].id
  secret_data = "dummy-discord-bot-token-${each.key}-spt"
}
