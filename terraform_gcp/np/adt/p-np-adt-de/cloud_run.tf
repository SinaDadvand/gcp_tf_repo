// ############################################################
//    Firebase Cloud Run v2 Service: soundboard-app-fb-adt
// ############################################################

resource "google_cloud_run_v2_service" "soundboard_app_fb_adt" {
  depends_on = [
    google_project_service.run_api_adt,
    google_project_service.identitytoolkit_api_adt,
    google_project_iam_member.soundboard_ar_reader_adt
  ]
  name     = "soundboard-app-fb-adt"
  location = var.region
  project  = var.project_id

  template {
    service_account = google_service_account.soundboard_runner_adt.email

    scaling {
      max_instance_count = 1
    }

    containers {
      name  = "soundboard-container"
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.soundboard_repo_adt.repository_id}/app:latest"

      ports {
        container_port = 8080
      }

      env {
        name = "DISCORD_BOT_TOKEN"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.discord_bot_token_adt.secret_id
            version = "latest"
          }
        }
      }

      // Configure explicit email allowlist
      env {
        name  = "ALLOWED_USERS"
        value = "sina.dadvand@gmail.com,friend@gmail.com"
      }

      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
        cpu_idle = false
      }

      startup_probe {
        timeout_seconds   = 240
        period_seconds    = 240
        failure_threshold = 1
        tcp_socket {
          port = 8080
        }
      }
    }
  }
}