output "service_name" {
  description = "Cloud Run service name."
  value       = google_cloud_run_v2_service.ingest.name
}

output "service_url" {
  description = "HTTPS URL of the Cloud Run service."
  value       = google_cloud_run_v2_service.ingest.uri
}

output "service_id" {
  description = "Fully-qualified Cloud Run resource ID."
  value       = google_cloud_run_v2_service.ingest.id
}
