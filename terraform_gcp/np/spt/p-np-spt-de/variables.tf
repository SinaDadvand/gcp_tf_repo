variable "project_id" {
  type    = string
  default = "p-np-spt-de"
}

variable "region" {
  type    = string
  default = "us-west1"
}

variable "zone" {
  type    = string
  default = "us-west1-a"
}

variable "soundboard_users" {
  description = "Map of dedicated soundboard users for isolated Cloud Run and GCS instances"
  type = map(object({
    email        = string
    display_name = string
  }))
  default = {
    "sina" = {
      email        = "sina.dadvand@gmail.com"
      display_name = "Sina"
    }
    "cesar" = {
      email        = "crcastillo85@gmail.com"
      display_name = "Cesar"
    }
  }
}
