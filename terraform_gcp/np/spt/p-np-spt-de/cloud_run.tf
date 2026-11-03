// ############################################################
//    Firebase Cloud Run v2 Service: soundboard-app-fb-spt
// ############################################################

resource "google_cloud_run_v2_service" "soundboard_app_fb_spt" {
  depends_on = [
    google_project_service.run_api_spt,
    google_project_service.identitytoolkit_api_spt,
    google_project_iam_member.soundboard_ar_reader_spt
  ]
  name     = "soundboard-app-fb-spt"
  location = var.region
  project  = var.project_id

  template {
    service_account = google_service_account.soundboard_runner_spt.email

    scaling {
      max_instance_count = 1
    }

    containers {
      name  = "soundboard-container"
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.soundboard_repo_spt.repository_id}/app:latest"

      ports {
        container_port = 8080
      }

      env {
        name = "DISCORD_BOT_TOKEN"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.discord_bot_token_spt.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "FIREBASE_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.firebase_api_key_spt.secret_id
            version = "latest"
          }
        }
      }  
      
      env {
        name  = "FIREBASE_AUTH_DOMAIN"
        value = "${var.project_id}.firebaseapp.com" # Evaluates to p-np-spt-de.firebaseapp.com
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

# Allow public browser access so users can load the login page
resource "google_cloud_run_service_iam_member" "public_access_spt" {
  location = google_cloud_run_v2_service.soundboard_app_fb_spt.location
  project  = google_cloud_run_v2_service.soundboard_app_fb_spt.project
  service  = google_cloud_run_v2_service.soundboard_app_fb_spt.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
