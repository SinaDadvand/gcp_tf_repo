// ############################################################
//    Artifact Registry Docker Repository (ADT)
// ############################################################

resource "google_artifact_registry_repository" "soundboard_repo_adt" {
  depends_on    = [google_project_service.artifactregistry_api_adt]
  project       = var.project_id
  location      = var.region
  repository_id = "soundboard-app-adt"
  description   = "Docker repository for Soundboard App ADT container images"
  format        = "DOCKER"
}