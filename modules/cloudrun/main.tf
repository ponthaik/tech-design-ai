###############################################################################
# Cloud Run v2 ingestion service — INGRESS_TRAFFIC_INTERNAL_ONLY (constraint C3).
#
# Egress is forced through the LZ Serverless VPC connector (PRIVATE_RANGES_ONLY)
# so that the service participates in VPC Flow Logs (constraint C4).
###############################################################################

resource "google_cloud_run_v2_service" "ingest" {
  project  = var.project_id
  location = var.region
  name     = var.service_name

  ingress = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  launch_stage = "GA"

  labels = var.labels

  template {
    service_account = var.runner_sa_email

    scaling {
      min_instance_count = 1
      max_instance_count = 20
    }

    timeout                          = "60s"
    max_instance_request_concurrency = 80

    vpc_access {
      connector = var.vpc_connector_id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    containers {
      image = var.container_image

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle          = false # min=1 implies always-on
        startup_cpu_boost = true
      }

      ports {
        name           = "http1"
        container_port = 8080
      }

      env {
        name  = "BQ_PROJECT"
        value = var.bq_project
      }
      env {
        name  = "BQ_DATASET"
        value = var.bq_dataset
      }
      env {
        name  = "BQ_TABLE"
        value = var.bq_table
      }

      startup_probe {
        initial_delay_seconds = 0
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 3
        tcp_socket {
          port = 8080
        }
      }

      liveness_probe {
        http_get {
          path = "/healthz"
        }
        initial_delay_seconds = 10
        timeout_seconds       = 3
        period_seconds        = 30
        failure_threshold     = 3
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  lifecycle {
    ignore_changes = [
      # CI redeploys update the image tag; let pipeline manage revisions.
      template[0].containers[0].image,
      client,
      client_version,
    ]
  }
}

###############################################################################
# Service-scoped invoker binding (constraint C2 + least privilege).
#
# Only the Pub/Sub OIDC SA may invoke this service. All other principals are
# implicitly denied because Cloud Run requires explicit run.invoker grants.
###############################################################################

resource "google_cloud_run_v2_service_iam_member" "pubsub_invoker" {
  project  = var.project_id
  location = google_cloud_run_v2_service.ingest.location
  name     = google_cloud_run_v2_service.ingest.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.invoker_sa_email}"

  # IAM Condition restricts the role to this exact resource path. The role is
  # already resource-scoped via the *_iam_member resource type; the condition
  # is belt-and-braces to preserve scope if this is ever ported to a broader
  # binding type.
  condition {
    title       = "only_this_service"
    description = "Restrict run.invoker to the cr-p-pbqi service only."
    expression  = "resource.name == \"projects/${var.project_id}/locations/${var.region}/services/${var.service_name}\""
  }
}
