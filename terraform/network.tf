resource "google_compute_network" "vpc" {
  name                    = "smart-construction-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "smart-construction-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Cloud NAT para as VMs sem IP público baixarem imagens do Artifact Registry e pacotes SO
resource "google_compute_router" "router" {
  name    = "smart-construction-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "smart-construction-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Tráfego HTTP do Load Balancer + Health Checks para o Nginx nas VMs de App
resource "google_compute_firewall" "allow_lb_to_app" {
  name    = "sc-allow-lb-to-app"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["smart-app"]
}

# PostgreSQL (5432) isolado: aceita conexões APENAS das VMs de aplicação
resource "google_compute_firewall" "allow_postgres_internal" {
  name    = "sc-allow-postgres-from-app"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_tags = ["smart-app"]
  target_tags = ["smart-db"]
}

# SSH restrito ao túnel seguro IAP (Identity-Aware Proxy) para o Ansible
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "sc-allow-iap-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["smart-app", "smart-db"]
}