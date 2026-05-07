###############################################################################
# Pub/Sub topics + push subscription
#
# - Main topic: 7-day retention to act as a DR buffer (RFC NFR).
# - DLQ topic:  14-day retention for triage of malformed payloads.
# - Subscription delivers via push with OIDC; retries 5x then routes to DLQ.
###############################################################################

resource "google_pubsub_topic" "main" {
  project                    = var.project_id
  name                       = var.topic_name
  message_retention_duration = "${var.retention_days_main * 24 * 60 * 60}s"

  labels = var.labels
}

resource "google_pubsub_topic" "dlq" {
  project                    = var.project_id
  name                       = var.dlq_topic_name
  message_retention_duration = "${var.retention_days_dlq * 24 * 60 * 60}s"

  labels = var.labels
}

###############################################################################
# DLQ wiring requires the Pub/Sub service agent to publish to the DLQ topic
# and to attach the dead_letter_policy on the subscription.
###############################################################################

data "google_project" "this" {
  project_id = var.project_id
}

locals {
  pubsub_service_agent = "service-${data.google_project.this.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_topic_iam_member" "dlq_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.dlq.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${local.pubsub_service_agent}"
}

# Cloud Run runtime SA — topic-scoped publish on DLQ only (least privilege).
resource "google_pubsub_topic_iam_member" "runner_dlq_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.dlq.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${var.runner_sa_email}"
}

resource "google_pubsub_subscription_iam_member" "main_sub_subscriber" {
  project      = var.project_id
  subscription = google_pubsub_subscription.main.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${local.pubsub_service_agent}"
}

###############################################################################
# Push subscription with OIDC authentication to Cloud Run
###############################################################################

resource "google_pubsub_subscription" "main" {
  project = var.project_id
  name    = var.subscription_name
  topic   = google_pubsub_topic.main.id

  ack_deadline_seconds       = var.ack_deadline_seconds
  message_retention_duration = "${var.retention_days_main * 24 * 60 * 60}s"
  retain_acked_messages      = false
  enable_message_ordering    = false

  expiration_policy {
    ttl = "" # Never expire.
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dlq.id
    max_delivery_attempts = var.max_delivery_attempts
  }

  push_config {
    push_endpoint = var.push_endpoint

    oidc_token {
      service_account_email = var.push_oidc_sa_email
      audience              = var.push_endpoint
    }

    attributes = {
      "x-goog-version" = "v1"
    }
  }

  labels = var.labels

  depends_on = [
    google_pubsub_topic_iam_member.dlq_publisher,
  ]
}
