###############################################################################
# Root composition for the pubsub-bq-ingest workload.
#
#   Pub/Sub topic ──> Push subscription (OIDC)
#                          │
#                          ▼
#               Cloud Run v2 (internal-only ingress)
#                          │
#                          ▼
#                    BigQuery (Storage Write API)
#
# All existing LZ resources (host VPC, subnet, project) are referenced as
# `data` blocks — never created by this module set.
###############################################################################

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# ----------------------------------------------------------------------------
# Existing LZ resources — read-only data sources
# ----------------------------------------------------------------------------

data "google_project" "service" {
  project_id = var.project_id
}

data "google_compute_network" "shared_vpc" {
  project = var.shared_vpc_host_project_id
  name    = var.shared_vpc_network_name
}

data "google_compute_subnetwork" "lz_subnet" {
  self_link = var.subnet_self_link
}

# ----------------------------------------------------------------------------
# Required APIs
# ----------------------------------------------------------------------------

locals {
  required_apis = toset([
    "run.googleapis.com",
    "pubsub.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "artifactregistry.googleapis.com",
    "vpcaccess.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ])
}

resource "google_project_service" "enabled" {
  for_each                   = local.required_apis
  project                    = var.project_id
  service                    = each.key
  disable_on_destroy         = false
  disable_dependent_services = false
}

# ----------------------------------------------------------------------------
# IAM — service accounts, dataset-scoped bindings, WIF
# ----------------------------------------------------------------------------

module "iam" {
  source = "./modules/iam"

  project_id     = var.project_id
  project_number = data.google_project.service.number

  github_org  = var.github_org
  github_repo = var.github_repo

  depends_on = [google_project_service.enabled]
}

# ----------------------------------------------------------------------------
# BigQuery — dataset, table, dataset-scoped IAM
# ----------------------------------------------------------------------------

module "bigquery" {
  source = "./modules/bigquery"

  project_id      = var.project_id
  region          = var.region
  dataset_id      = "ds_pubsub_ingest"
  table_id        = "events"
  runner_sa_email = module.iam.runner_sa_email
  labels          = var.labels

  depends_on = [google_project_service.enabled]
}

# ----------------------------------------------------------------------------
# Pub/Sub — topic, DLQ, push subscription with OIDC
# ----------------------------------------------------------------------------

module "pubsub" {
  source = "./modules/pubsub"

  project_id            = var.project_id
  topic_name            = "pbqi-events"
  dlq_topic_name        = "pbqi-events-dlq"
  subscription_name     = "pbqi-events-sub"
  push_endpoint         = "${module.cloudrun.service_url}/v1/ingest"
  push_oidc_sa_email    = module.iam.invoker_sa_email
  runner_sa_email       = module.iam.runner_sa_email
  ack_deadline_seconds  = 60
  retention_days_main   = 7
  retention_days_dlq    = 14
  max_delivery_attempts = 5
  labels                = var.labels

  depends_on = [
    google_project_service.enabled,
    module.cloudrun,
    module.iam,
  ]
}

# ----------------------------------------------------------------------------
# Serverless VPC connector
# ----------------------------------------------------------------------------

resource "google_vpc_access_connector" "egress" {
  provider = google-beta
  project  = var.project_id
  name     = "vpc-conn-${var.env_code}-as-se1"
  region   = var.region

  # The LZ provisions a /28 subnet for the connector inside the shared VPC.
  # Using the subnet form means we do NOT pass ip_cidr_range/network — the
  # subnet itself dictates the range (var.vpc_connector_cidr is informational
  # and is enforced by the LZ subnet provisioner).
  subnet {
    name       = data.google_compute_subnetwork.lz_subnet.name
    project_id = var.shared_vpc_host_project_id
  }

  machine_type  = "e2-micro"
  min_instances = 2
  max_instances = 4

  depends_on = [google_project_service.enabled]
}

# ----------------------------------------------------------------------------
# Cloud Run v2 service (ingestion)
# ----------------------------------------------------------------------------

module "cloudrun" {
  source = "./modules/cloudrun"

  project_id       = var.project_id
  region           = var.region
  env_code         = var.env_code
  service_name     = "cr-${var.env_code}-pbqi"
  container_image  = var.container_image
  runner_sa_email  = module.iam.runner_sa_email
  invoker_sa_email = module.iam.invoker_sa_email
  vpc_connector_id = google_vpc_access_connector.egress.id
  bq_project       = var.project_id
  bq_dataset       = module.bigquery.dataset_id
  bq_table         = module.bigquery.table_id
  labels           = var.labels

  depends_on = [
    google_project_service.enabled,
    google_vpc_access_connector.egress,
    module.bigquery,
  ]
}
