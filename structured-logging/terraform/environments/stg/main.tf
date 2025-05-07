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
resource "google_artifact_registry_repository" "structured-logging" {
  location      = var.region
  provider      = google
  repository_id = "structured-logging"
  format        = "docker"

  depends_on = [google_project_service.services["artifactregistry.googleapis.com"]]
}

output "artifact_registry_repository_structured-logging_url" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.structured-logging.repository_id}"
}

# Secret Managerのシークレット作成
resource "google_secret_manager_secret" "rails_master_key" {
  secret_id = "rails-master-key"

  replication {
    auto {}
  }

  lifecycle {
    ignore_changes = []
  }

  depends_on = [google_project_service.services["secretmanager.googleapis.com"]]
}

# Cloud Run Service
resource "google_service_account" "structured-logging" {
  account_id   = "structured-logging"
  display_name = "Structured Logging Service Account"
  project      = var.project_id

  depends_on = [google_project_service.services["iam.googleapis.com"]]
}

resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.structured-logging.email}"

  depends_on = [google_project_service.services["run.googleapis.com"]]
}

resource "google_cloud_run_v2_service" "structured-logging" {
  name     = "structured-logging"
  location = var.region

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.structured-logging.repository_id}/structured-logging:latest"

      ports {
        container_port = 80
      }

      env {
        name = "RAILS_MASTER_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.rails_master_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name  = "PROJECT_ID"
        value = var.project_id
      }

      startup_probe {
        initial_delay_seconds = 15
        failure_threshold     = 5
        period_seconds        = 5
        timeout_seconds       = 5
        http_get {
          path = "/up"
        }
      }

      liveness_probe {
        failure_threshold = 3
        period_seconds    = 5
        timeout_seconds   = 5
        http_get {
          path = "/up"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    # invoker_iam_disabled = true

    service_account = google_service_account.structured-logging.email
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

  depends_on = [
    google_project_service.services["run.googleapis.com"],
    google_project_service.services["servicenetworking.googleapis.com"],
    google_project_service.services["cloudbuild.googleapis.com"],
    google_project_iam_member.secret_accessor,
  ]
}

output "cloud_run_service_url" {
  value = google_cloud_run_v2_service.structured-logging.uri
}
