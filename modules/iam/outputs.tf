output "runner_sa_email" {
  description = "Email of the Cloud Run runtime SA."
  value       = google_service_account.runner.email
}

output "runner_sa_name" {
  description = "Fully-qualified resource name of the runtime SA."
  value       = google_service_account.runner.name
}

output "invoker_sa_email" {
  description = "Email of the Pub/Sub OIDC invoker SA."
  value       = google_service_account.invoker.email
}

output "deployer_sa_email" {
  description = "Email of the CI/CD deployer SA (impersonated via WIF)."
  value       = google_service_account.deployer.email
}

output "wif_pool_name" {
  description = "Resource name of the WIF pool."
  value       = google_iam_workload_identity_pool.github.name
}

output "wif_provider_name" {
  description = "Resource name of the WIF provider — feed into google-github-actions/auth."
  value       = google_iam_workload_identity_pool_provider.github.name
}
