terraform {
  backend "gcs" {
    bucket = ""
    prefix = "terraform/db-cloud-storage/stg"
  }
}
