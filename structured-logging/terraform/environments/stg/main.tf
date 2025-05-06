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
