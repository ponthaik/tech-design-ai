###############################################################################
# Service accounts
###############################################################################

resource "google_service_account" "runner" {
  project      = var.project_id
  account_id   = "sa-pbqi-runner"
  display_name = "Cloud Run runtime SA — pubsub-bq-ingest"
  description  = "Identity used by cr-p-pbqi at runtime; writes to BigQuery and DLQ topic."
}

resource "google_service_account" "invoker" {
  project      = var.project_id
  account_id   = "sa-pbqi-pubsub-invoker"
  display_name = "Pub/Sub push-OIDC SA — pubsub-bq-ingest"
  description  = "Generates OIDC tokens that Pub/Sub uses to call the Cloud Run service."
}

resource "google_service_account" "deployer" {
  project      = var.project_id
  account_id   = "sa-pbqi-deployer"
  display_name = "CI/CD deployer SA — pubsub-bq-ingest"
  description  = "Impersonated by GitHub Actions via WIF; deploys infra + new revisions."
}

###############################################################################
# Project-level least-privilege bindings for the runtime SA
#
# Note: roles/bigquery.dataEditor is intentionally NOT granted at the project
# level — it is bound to the dataset only (see modules/bigquery/main.tf).
# The bindings below are operational roles required project-wide.
###############################################################################

resource "google_project_iam_member" "runner_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.runner.email}"
}

resource "google_project_iam_member" "runner_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.runner.email}"
}

# bigquery.jobUser is required to run Storage Write API jobs; project-wide
# but constrained to the runner SA only.
resource "google_project_iam_member" "runner_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.runner.email}"
}

###############################################################################
# Workload Identity Federation pool + provider for GitHub Actions
#
# attribute_condition restricts token minting to the named GitHub repo only.
###############################################################################

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "wif-pool-pbqi"
  display_name              = "GitHub WIF pool (pubsub-bq-ingest)"
  description               = "Allows GitHub Actions in the configured repo to impersonate sa-pbqi-deployer."
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "wif-provider-github"
  display_name                       = "GitHub OIDC provider"

  # Only tokens from the specific org+repo can authenticate.
  attribute_condition = "assertion.repository_owner == \"${var.github_org}\" && assertion.repository == \"${var.github_org}/${var.github_repo}\""

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.aud"              = "assertion.aud"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"              = "assertion.ref"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Allow the configured GitHub repository (any branch/PR) to impersonate the
# deployer SA. Tighten to specific refs by changing the principalSet filter.
resource "google_service_account_iam_member" "github_wif_impersonation" {
  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_org}/${var.github_repo}"
}

###############################################################################
# Outputs
###############################################################################
