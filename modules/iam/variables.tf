variable "project_id" {
  description = "Service project ID."
  type        = string
}

variable "project_number" {
  description = "Numeric project number (used in WIF principal references)."
  type        = string
}

variable "github_org" {
  description = "GitHub organisation that may impersonate the deployer SA via WIF."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without org prefix) authorised to deploy."
  type        = string
}
