// ############################################################
//    Discord Bot Token Secret Container
// ############################################################

resource "google_secret_manager_secret" "discord_bot_token_adt" {
  depends_on = [google_project_service.secretmanager_api_adt]
  project    = var.project_id
  secret_id  = "discord-bot-token-adt"

  replication {
    auto {}
  }
}

// ############################################################
//   Firebase Web API Key for p-np-adt-de
// ############################################################

resource "google_secret_manager_secret" "firebase_api_key_adt" {
  depends_on = [google_project_service.secretmanager_api_adt]
  project    = var.project_id
  secret_id  = "firebase-api-key-adt"

  replication {
    auto {}
  }
}

// ############################################################
//   Per-User Discord Bot Token Secrets (soundboard_user_*)
// ############################################################

resource "google_secret_manager_secret" "soundboard_user_discord_token" {
  depends_on = [google_project_service.secretmanager_api_adt]
  for_each   = var.soundboard_users
  project    = var.project_id
  secret_id  = "soundboard_user_discord_token_${each.key}_adt"

  labels = {
    user = each.key
    env  = "adt"
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "soundboard_user_discord_token_version" {
  for_each    = var.soundboard_users
  secret      = google_secret_manager_secret.soundboard_user_discord_token[each.key].id
  secret_data = "dummy-discord-bot-token-${each.key}-adt"
}