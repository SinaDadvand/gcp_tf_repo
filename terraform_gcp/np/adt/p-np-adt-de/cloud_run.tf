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

      env {
        name = "FIREBASE_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.firebase_api_key_adt.secret_id
            version = "latest"
          }
        }
      }  
      
      env {
        name  = "FIREBASE_AUTH_DOMAIN"
        value = "${var.project_id}.firebaseapp.com" # Evaluates to p-np-adt-de.firebaseapp.com
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
resource "google_cloud_run_service_iam_member" "public_access" {
  location = google_cloud_run_v2_service.soundboard_app_fb_adt.location
  project  = google_cloud_run_v2_service.soundboard_app_fb_adt.project
  service  = google_cloud_run_v2_service.soundboard_app_fb_adt.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

// ############################################################
//    Per-User Cloud Run v2 Services: soundboard_user_*
// ############################################################

resource "google_cloud_run_v2_service" "soundboard_user_app" {
  depends_on = [
    google_project_service.run_api_adt,
    google_project_service.identitytoolkit_api_adt,
    google_project_iam_member.soundboard_ar_reader_adt,
    google_storage_bucket_iam_member.soundboard_user_runner_access
  ]
  for_each = var.soundboard_users
  name     = "soundboard-user-${each.key}-adt"
  location = var.region
  project  = var.project_id

  labels = {
    user = each.key
    env  = "adt"
    app  = "soundboard"
  }

  template {
    service_account = google_service_account.soundboard_runner_adt.email

    scaling {
      max_instance_count = 1
    }

    volumes {
      name = "user-audio"
      gcs {
        bucket    = google_storage_bucket.soundboard_user_audio[each.key].name
        read_only = false
      }
    }

    containers {
      name  = "soundboard-container"
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.soundboard_repo_adt.repository_id}/app:latest"

      ports {
        container_port = 8080
      }

      volume_mounts {
        name       = "user-audio"
        mount_path = "/mnt/user-audio"
      }

      env {
        name  = "AUDIO_DIR"
        value = "/mnt/user-audio"
      }

      env {
        name  = "CONFIG_PATH"
        value = "/mnt/user-audio/soundboard_config.json"
      }

      env {
        name  = "ALLOWED_USERS"
        value = join(",", distinct([each.value.email, "sina.dadvand@gmail.com"]))
      }

      env {
        name  = "USER_NAME"
        value = each.key
      }

      env {
        name  = "BOT_NAME"
        value = "Soundboard (${each.value.display_name})"
      }

      env {
        name = "DISCORD_BOT_TOKEN"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.soundboard_user_discord_token[each.key].secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "FIREBASE_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.firebase_api_key_adt.secret_id
            version = "latest"
          }
        }
      }

      env {
        name  = "FIREBASE_AUTH_DOMAIN"
        value = "${var.project_id}.firebaseapp.com"
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
resource "google_cloud_run_service_iam_member" "soundboard_user_public_access" {
  for_each = var.soundboard_users
  location = google_cloud_run_v2_service.soundboard_user_app[each.key].location
  project  = google_cloud_run_v2_service.soundboard_user_app[each.key].project
  service  = google_cloud_run_v2_service.soundboard_user_app[each.key].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
