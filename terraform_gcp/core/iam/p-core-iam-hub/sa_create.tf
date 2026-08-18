# Central Automation Service Account (GitHub Actions Runner)
resource "google_service_account" "central_gha_runner" {
  project      = var.project_id
  account_id   = "gha-central-runner"
  display_name = "Central GitHub Actions Runner"
  description  = "Service Account used by GitHub Actions to deploy infrastructure across projects."
}

# Central Security Auditor Service Account
resource "google_service_account" "sec_auditor" {
  project      = var.project_id
  account_id   = "sec-auditor"
  display_name = "Central Security Auditor"
  description  = "Service Account used for automated compliance and security scans."
}