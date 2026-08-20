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