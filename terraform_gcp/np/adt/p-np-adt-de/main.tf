# Primary resources for p-np-adt-de

resource "google_compute_instance" "vm_instance" {
  depends_on   = [google_project_service.compute_api]
  name         = "p-np-adt-de-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }
}
