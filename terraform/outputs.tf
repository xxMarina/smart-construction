output "https_url" {
  value = "https://${google_compute_global_address.lb_ip.address}.sslip.io"
}

output "artifact_registry_url" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}"
}

output "db_private_ip" {
  value = google_compute_instance.db.network_interface[0].network_ip
}