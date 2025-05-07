terraform {
  backend "gcs" {
    bucket = ""
    prefix = "terraform/structured-logging/stg"
  }
}
