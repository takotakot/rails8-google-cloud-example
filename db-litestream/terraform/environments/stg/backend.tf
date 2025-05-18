terraform {
  backend "gcs" {
    bucket = ""
    prefix = "terraform/db-litestream/stg"
  }
}
