# terraform/environments/stg
# edit `.tfvars` and set `project_id`
# edit backend.tf
terraform init
terraform plan -var-file=".tfvars" -target="google_project_iam_member.secret_accessor" -target="google_storage_bucket_iam_member.cloud_run_access" -target="google_artifact_registry_repository.db-litestream" -target="google_secret_manager_secret.rails_master_key_litestream"
terraform apply -var-file=".tfvars" -target="google_project_iam_member.secret_accessor" -target="google_storage_bucket_iam_member.cloud_run_access" -target="google_artifact_registry_repository.db-litestream" -target="google_secret_manager_secret.rails_master_key_litestream"

# Add secret value of `master.key` to `rails-master-key-litestream`

# bin/rails db:seed

# Modify build_image.sh
./build_image.sh

terraform apply -var-file=".tfvars"
