output "cloud_run_url" {
  description = "HTTPS URL of the Cloud Run ingestion service (internal-only ingress)."
  value       = module.cloudrun.service_url
}

output "bq_table_id" {
  description = "Fully-qualified BigQuery target table ID (project.dataset.table)."
  value       = "${var.project_id}.${module.bigquery.dataset_id}.${module.bigquery.table_id}"
}

output "pubsub_topic_id" {
  description = "Fully-qualified Pub/Sub main topic ID."
  value       = module.pubsub.topic_id
}

output "pubsub_dlq_topic_id" {
  description = "Fully-qualified Pub/Sub dead-letter topic ID."
  value       = module.pubsub.dlq_topic_id
}

output "wif_provider_resource_name" {
  description = "Workload Identity Provider resource name for use in GitHub Actions auth step."
  value       = module.iam.wif_provider_name
}

output "runner_sa_email" {
  description = "Email of the Cloud Run runtime service account."
  value       = module.iam.runner_sa_email
}

output "invoker_sa_email" {
  description = "Email of the Pub/Sub OIDC invoker service account."
  value       = module.iam.invoker_sa_email
}

output "deployer_sa_email" {
  description = "Email of the WIF-impersonated deployer service account (used by GitHub Actions)."
  value       = module.iam.deployer_sa_email
}
