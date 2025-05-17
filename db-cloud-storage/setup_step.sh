# terraform/environments/stg
# edit `.tfvars`
# edit backend.tf
terraform init
terraform plan -var-file=".tfvars" -target="google_project_iam_member.secret_accessor" -target="google_storage_bucket_iam_member.cloud_run_access" -target="google_artifact_registry_repository.db-cloud-storage"
terraform apply -var-file=".tfvars" -target="google_project_iam_member.secret_accessor" -target="google_storage_bucket_iam_member.cloud_run_access" -target="google_artifact_registry_repository.db-cloud-storage"

# Add secret value of `master.key` to `rails-master-key-gcs`

# bin/rails db:seed

# Modify build_image.sh
./build_image.sh

# RAILS_ENV=production bin/rails db:prepare
# 実行後、`storage/` の `production_cable.sqlite3`, `production_cache.sqlite3`, `production_queue.sqlite3`, `production.sqlite3` をバケットに転送

terraform apply -var-file=".tfvars"
