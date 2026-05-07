###############################################################################
# BigQuery dataset + partitioned/clustered events table
#
# Encryption: Google-managed keys (data classification = internal, per RFC C5).
# Audit logging: data-access audit logs enabled at the org/project level (C6),
# this module does not need to configure them locally.
###############################################################################

resource "google_bigquery_dataset" "events" {
  project    = var.project_id
  dataset_id = var.dataset_id
  location   = var.region

  description                     = "Events ingested by cr-p-pbqi from Pub/Sub via Storage Write API."
  default_partition_expiration_ms = null
  default_table_expiration_ms     = null

  labels = var.labels
}

resource "google_bigquery_table" "events" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.events.dataset_id
  table_id   = var.table_id

  description              = "Validated events from pbqi-events topic. Partition: event_ts (DAY); cluster: event_type."
  deletion_protection      = true
  require_partition_filter = false

  time_partitioning {
    type  = "DAY"
    field = "event_ts"
  }

  clustering = ["event_type"]

  schema = jsonencode([
    {
      name        = "event_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Idempotency key supplied by the producer."
    },
    {
      name        = "event_ts"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Event time as supplied by the producer; partition column."
    },
    {
      name        = "event_type"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Logical event class — clustering column."
    },
    {
      name        = "payload"
      type        = "JSON"
      mode        = "NULLABLE"
      description = "Application payload."
    },
    {
      name        = "ingest_ts"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Ingest timestamp written by Cloud Run service."
    },
  ])

  labels = var.labels
}

###############################################################################
# Dataset-scoped IAM bindings (least privilege — NOT project-wide)
###############################################################################

# Cloud Run runtime SA — write access at the dataset level only.
resource "google_bigquery_dataset_iam_member" "runner_data_editor" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.events.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.runner_sa_email}"
}
