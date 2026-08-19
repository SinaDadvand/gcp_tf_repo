// ############################################################
//    Google Groups for NP ADT Environment
// ############################################################

resource "google_cloud_identity_group" "soundboard_users_adt" {
  depends_on   = [google_project_service.cloudidentity_api]
  display_name = "Soundboard App ADT Authorized Users"
  parent       = "customers/${var.customer_id}"

  group_key {
    id = "soundboard-app-users-adt@yourdomain.com"
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

resource "google_cloud_identity_group_membership" "soundboard_user_1_adt" {
  group = google_cloud_identity_group.soundboard_users_adt.id

  preferred_member_key {
    id = "your.email@gmail.com"
  }

  roles {
    name = "MEMBER"
  }
}