// ############################################################
//    Artifact Registry for p-np-spt-de
// ############################################################

resource "google_artifact_registry_repository" "soundboard_repo_spt" {
  depends_on = [google_project_service.artifactregistry_api_spt]
  location      = var.region
  repository_id = "soundboard-app-spt"
  description   = "Docker repository for SPT soundboard application"
  format        = "DOCKER"
  project       = var.project_id
}
