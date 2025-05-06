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
