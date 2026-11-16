terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.10.0"
    }
  }


  backend "gcs" {
    bucket = "smart-construction-tfstate-projeto-mensal-4"
    prefix = "prod"
  }
}

provider "google" {
  project               = var.project_id
  region                = var.region
  zone                  = var.zone
  user_project_override = true
  billing_project       = var.project_id
}