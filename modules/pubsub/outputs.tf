output "topic_id" {
  description = "Fully-qualified ID of the main topic."
  value       = google_pubsub_topic.main.id
}

output "dlq_topic_id" {
  description = "Fully-qualified ID of the DLQ topic."
  value       = google_pubsub_topic.dlq.id
}

output "subscription_id" {
  description = "Fully-qualified ID of the push subscription."
  value       = google_pubsub_subscription.main.id
}
