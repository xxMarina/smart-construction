# --- POLÍTICA DE BACKUP AUTOMÁTICO (Requisito 6) ---
resource "google_compute_resource_policy" "daily_backup" {
  name   = "smart-construction-daily-backup"
  region = var.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "03:00"
      }
    }
    retention_policy {
      max_retention_days    = 7
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
    snapshot_properties {
      storage_locations = [var.region]
      guest_flush       = true
    }
  }
}

# --- DISCOS PERSISTENTES (Gerenciados fora do state para sobreviver ao destroy) ---
data "google_compute_disk" "db_data" {
  name = "smart-construction-backend-data"
  zone = var.zone
}

resource "google_compute_disk_resource_policy_attachment" "db_backup" {
  name = google_compute_resource_policy.daily_backup.name
  disk = data.google_compute_disk.db_data.name
  zone = var.zone
}

data "google_compute_disk" "app_storage" {
  count = 2
  name  = "smart-construction-storage-data-${count.index + 1}"
  zone  = var.zone
}

# --- 2 VMs DE APLICAÇÃO (Nginx, Next.js, FastAPI, SeaweedFS) ---
resource "google_compute_instance" "app" {
  count        = 2
  name         = "smart-construction-app-${count.index + 1}"
  machine_type = var.app_machine_type
  zone         = var.zone
  tags         = ["smart-app"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 20
    }
  }

  attached_disk {
    source      = data.google_compute_disk.app_storage[count.index].id
    device_name = "storage-data"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    # Sem IP público: tráfego entra via Load Balancer e sai via Cloud NAT
  }

  service_account {
    email  = data.google_service_account.app_sa.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update && apt-get install -y docker.io docker-compose-v2
    systemctl enable --now docker
    gcloud auth configure-docker ${var.region}-docker.pkg.dev --quiet
  EOF
}

# --- 1 VM EXCLUSIVA DE BANCO DE DADOS (PostgreSQL 17) ---
resource "google_compute_instance" "db" {
  name         = "smart-construction-db"
  machine_type = var.db_machine_type
  zone         = var.zone
  tags         = ["smart-db"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 20
    }
  }

  attached_disk {
    source      = data.google_compute_disk.db_data.id
    device_name = "backend-data"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
  }

  service_account {
    email  = data.google_service_account.app_sa.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update && apt-get install -y docker.io docker-compose-v2
    systemctl enable --now docker
  EOF
}