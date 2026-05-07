variable "project_id" {
  description = "Service project."
  type        = string
}

variable "region" {
  description = "Region."
  type        = string
}

variable "env_code" {
  description = "LZ environment code."
  type        = string
}

variable "service_name" {
  description = "Cloud Run service name (e.g. cr-p-pbqi)."
  type        = string
}

variable "container_image" {
  description = "Fully-qualified container image URI."
  type        = string
}

variable "runner_sa_email" {
  description = "Runtime SA email for the service."
  type        = string
}

variable "invoker_sa_email" {
  description = "Pub/Sub OIDC invoker SA email — receives roles/run.invoker on this service only."
  type        = string
}

variable "vpc_connector_id" {
  description = "Resource ID of the Serverless VPC connector for egress."
  type        = string
}

variable "bq_project" {
  description = "BigQuery project for the runtime env var."
  type        = string
}

variable "bq_dataset" {
  description = "BigQuery dataset for the runtime env var."
  type        = string
}

variable "bq_table" {
  description = "BigQuery table for the runtime env var."
  type        = string
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}
