# Example: Granting Read/Viewer access across the central project
# Un-comment and update email addresses when ready to enforce group access.

# resource "google_project_iam_member" "developer_viewers" {
#   project = var.hub_project_id
#   role    = "roles/viewer"
#   member  = "group:gcp-developers@yourdomain.com"
# }