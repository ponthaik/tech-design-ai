variable "project_id" {
  type        = string
  description = "GCP project that will host the hello-service Cloud Run."
}

variable "region" {
  type        = string
  default     = "asia-southeast1"
  description = "Single region. Sing only — no multi-region for an example service."
}

variable "vpc_network_name" {
  type        = string
  default     = "shared-internal-asia"
  description = "Existing VPC chosen by the orchestrator (resources_chosen.vpc_network)."
}

variable "artifact_registry_repo" {
  type        = string
  default     = "apps"
  description = "Existing Artifact Registry repo in <region> that holds the hello-service image."
}

variable "image" {
  type        = string
  description = <<EOT
Fully-qualified container image, MUST be pinned to a digest, e.g.
asia-southeast1-docker.pkg.dev/<project>/apps/hello-service@sha256:abcd...
EOT
  validation {
    condition     = can(regex("@sha256:[0-9a-f]{64}$", var.image))
    error_message = "var.image must be pinned to a sha256 digest, not a floating tag."
  }
}

variable "invoker_sa" {
  type        = string
  description = "Email of the service account allowed to invoke /hello (e.g. uptime-checker or a sister workload)."
  default     = ""
}

variable "labels" {
  type = map(string)
  default = {
    app         = "hello-service"
    owner       = "platform-eng"
    environment = "dev"
    cost_center = "shared-platform"
  }
  description = "Resource labels."
}
