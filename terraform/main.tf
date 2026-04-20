terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.24.0" # Latest as of March 2026
    }
  }
}

provider "google" {
  project     = var.project
  region      = var.region
}



resource "google_storage_bucket" "raw" {
  name     = var.gcs_bucket_name
  location = var.location

  # Optional, but recommended settings:
  storage_class               = var.gcs_storage_class
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 90 // days
    }
  }

  force_destroy = true
}


resource "google_bigquery_dataset" "staging" {
  dataset_id = var.bq_dataset_name
}
