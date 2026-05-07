terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
  }

  # Remote state lives in the LZ-managed GCS bucket.
  # Configured per-environment via partial backend config:
  #   terraform init -backend-config=bucket=<tfstate_bucket> -backend-config=prefix=pubsub-bq-ingest/p
  backend "gcs" {}
}
