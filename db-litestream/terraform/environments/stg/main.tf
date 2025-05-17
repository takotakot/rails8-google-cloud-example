locals {
  project_services = [
    "servicenetworking.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "vpcaccess.googleapis.com",
    "secretmanager.googleapis.com",
    "iap.googleapis.com",
    "storage.googleapis.com",
  ]
}

resource "google_project_service" "services" {
  for_each = toset(local.project_services)

  project = var.project_id
  service = each.key

  disable_dependent_services = true
  disable_on_destroy         = false
}

# Artifact Registry Repository
resource "google_artifact_registry_repository" "db-litestream" {
  location      = var.region
  provider      = google
  repository_id = "db-litestream"
  format        = "docker"

  depends_on = [google_project_service.services["artifactregistry.googleapis.com"]]
}

output "artifact_registry_repository_db-litestream_url" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.db-litestream.repository_id}"
}

# Secret Managerのシークレット作成
resource "google_secret_manager_secret" "rails_master_key_litestream" {
  secret_id = "rails-master-key-litestream"

  replication {
    auto {}
  }

  lifecycle {
    ignore_changes = []
  }

  depends_on = [google_project_service.services["secretmanager.googleapis.com"]]
}

# Cloud Run Service
resource "google_service_account" "db-litestream" {
  account_id   = "db-litestream"
  display_name = "Structured Logging Service Account"
  project      = var.project_id

  depends_on = [google_project_service.services["iam.googleapis.com"]]
}

resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.db-litestream.email}"

  depends_on = [google_project_service.services["run.googleapis.com"]]
}


# Cloud Storage Bucket for SQLite database files
resource "google_storage_bucket" "sqlite_bucket" {
  name          = "${var.project_id}-db-litestream-sqlite-bucket"
  location      = var.region
  storage_class = "STANDARD"

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 7
    }
  }

  depends_on = [google_project_service.services["storage.googleapis.com"]]
}

# IAM policy for Cloud Run to access the bucket
resource "google_storage_bucket_iam_member" "cloud_run_access" {
  bucket = google_storage_bucket.sqlite_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.db-litestream.email}"

  depends_on = [google_storage_bucket.sqlite_bucket]
}

resource "google_cloud_run_v2_service" "db-litestream" {
  name     = "db-litestream"
  location = var.region

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.db-litestream.repository_id}/db-litestream:latest"

      ports {
        container_port = 8080
      }

      env {
        name  = "HTTP_PORT"
        value = "8080"
      }

      env {
        name = "RAILS_MASTER_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.rails_master_key_litestream.secret_id
            version = "latest"
          }
        }
      }

      env {
        name  = "PROJECT_ID"
        value = var.project_id
      }

      env {
        name  = "LITESTREAM_REPLICA_BUCKET"
        value = google_storage_bucket.sqlite_bucket.name
      }

      startup_probe {
        initial_delay_seconds = 10
        failure_threshold     = 180
        period_seconds        = 1
        timeout_seconds       = 1
        http_get {
          path = "/up"
          port = 8080
        }
      }

      liveness_probe {
        failure_threshold = 3
        period_seconds    = 5
        timeout_seconds   = 5
        http_get {
          path = "/up"
          port = 8080
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    service_account = google_service_account.db-litestream.email
  }

  invoker_iam_disabled = true

  lifecycle {
    ignore_changes = [
      #   template[0].containers[0].env[0].value_source[0].secret_key_ref[0].version,
      template[0].containers[0].env,
      template[0].containers[0].image,
    ]
  }

  #   traffic {
  #     latest_revision = true
  #     percent         = 100
  #   }
  deletion_protection = false

  depends_on = [
    google_project_service.services["run.googleapis.com"],
    google_project_service.services["servicenetworking.googleapis.com"],
    google_project_service.services["cloudbuild.googleapis.com"],
    google_project_iam_member.secret_accessor,
  ]
}

output "cloud_run_service_url" {
  value = google_cloud_run_v2_service.db-litestream.uri
}
