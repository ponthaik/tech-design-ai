variable "project_id" {
  description = "Project hosting Pub/Sub resources."
  type        = string
}

variable "topic_name" {
  description = "Main topic name."
  type        = string
}

variable "dlq_topic_name" {
  description = "Dead-letter topic name."
  type        = string
}

variable "subscription_name" {
  description = "Push subscription name."
  type        = string
}

variable "push_endpoint" {
  description = "Cloud Run URL (e.g. https://cr-p-pbqi-xyz.a.run.app/v1/ingest)."
  type        = string
}

variable "push_oidc_sa_email" {
  description = "Service account whose OIDC token Pub/Sub mints when calling Cloud Run."
  type        = string
}

variable "runner_sa_email" {
  description = "Cloud Run runtime SA — granted topic-scoped publisher on the DLQ for application-level routing."
  type        = string
}

variable "ack_deadline_seconds" {
  description = "Subscription ack deadline."
  type        = number
  default     = 60
}

variable "retention_days_main" {
  description = "Message retention on the main topic, in days."
  type        = number
  default     = 7
}

variable "retention_days_dlq" {
  description = "Message retention on the DLQ topic, in days."
  type        = number
  default     = 14
}

variable "max_delivery_attempts" {
  description = "Push subscription max redelivery attempts before DLQ."
  type        = number
  default     = 5
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}
