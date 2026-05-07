variable "project_id" {
  description = "Project that owns the dataset."
  type        = string
}

variable "region" {
  description = "Dataset location (BigQuery regional)."
  type        = string
}

variable "dataset_id" {
  description = "Dataset ID (e.g. ds_pubsub_ingest)."
  type        = string
}

variable "table_id" {
  description = "Table ID (e.g. events)."
  type        = string
}

variable "runner_sa_email" {
  description = "Email of the runtime SA that needs dataEditor on the dataset."
  type        = string
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}
