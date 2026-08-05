output "instance_name" {
  value       = google_compute_instance.vm_instance.name
  description = "Name of the created VM"
}

output "public_ip" {
  value       = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
  description = "Public IP address of the VM"
}