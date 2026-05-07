###############################################################################
# Concrete values from .scratch/2026-05-07T1030-K7m3Qz/07-lz-advice.json
# and .scratch/.../03-components.yaml
#
# Non-secret only. Secrets / repo identifiers must be supplied via the CI
# pipeline (TF_VAR_*) or a -var-file kept outside the repo.
###############################################################################

project_id                 = "prj-p-pbqi-a1b2"
region                     = "asia-southeast1"
env_code                   = "p"
shared_vpc_host_project_id = "vpc-p-svpc-spoke"
shared_vpc_network_name    = "vpc-p-svpc-spoke"
subnet_self_link           = "projects/vpc-p-svpc-spoke/regions/asia-southeast1/subnetworks/sn-p-svpc-asia-southeast1"
vpc_connector_cidr         = "10.48.196.0/28"

container_image = "asia-southeast1-docker.pkg.dev/prj-p-pbqi-a1b2/app/ingest:latest"

# CI/CD federation — supplied per-org. The values below are illustrative.
github_org  = "abacusdigital"
github_repo = "pubsub-bq-ingest"
