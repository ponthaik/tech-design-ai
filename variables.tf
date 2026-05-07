###############################################################################
# Root variables
#
# Concrete values supplied via terraform.tfvars (LZ advice + RFC stub).
###############################################################################

variable "project_id" {
  description = "GCP service project that hosts the Cloud Run + BigQuery workload."
  type        = string
}

variable "region" {
  description = "Primary region for all regional resources."
  type        = string
  default     = "asia-southeast1"
}

variable "env_code" {
  description = "Single-letter LZ environment code (p = production)."
  type        = string
  validation {
    condition     = contains(["p", "n", "d"], var.env_code)
    error_message = "env_code must be one of: p, n, d."
  }
}

variable "shared_vpc_host_project_id" {
  description = "Host project that owns the Shared VPC (e.g. vpc-p-svpc-spoke)."
  type        = string
}

variable "shared_vpc_network_name" {
  description = "Name of the existing Shared VPC network in the host project."
  type        = string
}

variable "subnet_self_link" {
  description = "Self-link of the LZ-managed subnet that the Serverless VPC connector attaches to."
  type        = string
}

variable "vpc_connector_cidr" {
  description = "/28 CIDR for the Serverless VPC Access connector."
  type        = string
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/28$", var.vpc_connector_cidr))
    error_message = "vpc_connector_cidr must be a /28 CIDR block."
  }
}

variable "container_image" {
  description = "Fully-qualified container image URI for the Cloud Run ingestion service."
  type        = string
}

# ----------------------------------------------------------------------------
# Workload Identity Federation (CI/CD)
# ----------------------------------------------------------------------------

variable "github_org" {
  description = "GitHub organisation that owns the deployment repository."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without org prefix) authorised to deploy."
  type        = string
}

# ----------------------------------------------------------------------------
# Tags / labels
# ----------------------------------------------------------------------------

variable "labels" {
  description = "Common resource labels."
  type        = map(string)
  default = {
    workload    = "pubsub-bq-ingest"
    owner       = "data-platform"
    managed-by  = "terraform"
    cost-centre = "data"
  }
}
