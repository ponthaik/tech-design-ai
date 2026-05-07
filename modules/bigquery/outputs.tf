output "dataset_id" {
  description = "BigQuery dataset ID."
  value       = google_bigquery_dataset.events.dataset_id
}

output "table_id" {
  description = "BigQuery table ID."
  value       = google_bigquery_table.events.table_id
}

output "table_self_link" {
  description = "Self-link of the events table."
  value       = google_bigquery_table.events.self_link
}
