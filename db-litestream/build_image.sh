export PROJECT_ID=""
export SERVICE_NAME="db-litestream"
export INSTANCE_NAME="db-litestream"
export REGION="asia-northeast1"
export RAILS_SECRET_NAME="rails-master-key-gcs"

gcloud builds submit --config build_image.yaml \
    --project=$PROJECT_ID \
    --substitutions "_SERVICE_NAME=${SERVICE_NAME},_REGION=${REGION}"
#  --substitutions _PROJECT_ID=$PROJECT_ID
