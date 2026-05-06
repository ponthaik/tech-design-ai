output "service_url" {
  value       = google_cloud_run_v2_service.hello.uri
  description = "Internal URL of the hello-service. Reachable from inside VPC shared-internal-asia."
}

output "service_account_email" {
  value       = google_service_account.hello_run.email
  description = "Runtime SA. Grant /hello invoker rights to whoever needs to call it."
}

output "log_metric_name" {
  value       = google_logging_metric.hello_world_lines.name
  description = "Log-based metric counting 'hello world' stdout lines (heartbeat sanity check)."
}
