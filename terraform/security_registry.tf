resource "google_service_account" "app_sa" {
  account_id   = "smart-construction-app-sa"
  display_name = "Smart Construction VMs Service Account"
}

# --- ARTIFACT REGISTRY (Armazena imagens web, api e gateway) ---
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = "smart-construction"
  description   = "Imagens Docker imutáveis do Smart Construction"
  format        = "DOCKER"
}

resource "google_artifact_registry_repository_iam_member" "vm_registry_reader" {
  location   = google_artifact_registry_repository.docker_repo.location
  repository = google_artifact_registry_repository.docker_repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.app_sa.email}"
}

# --- SECRET MANAGER (Segredos fora do Git e dos logs) ---
locals {
  secrets = [
    "sc-db-password",
    "sc-jwt-secret",
    "sc-admin-password",
    "sc-s3-access-key",
    "sc-s3-secret-key"
  ]
}

resource "google_secret_manager_secret" "app_secrets" {
  for_each  = toset(local.secrets)
  secret_id = each.value

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "vm_secret_accessor" {
  for_each  = google_secret_manager_secret.app_secrets
  secret_id = each.value.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app_sa.email}"
}