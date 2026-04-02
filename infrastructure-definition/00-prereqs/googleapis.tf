# This resource is neccessary to run external-secrets successfully.
# Enabling GCP API's
resource "google_project_service" "project" {
  for_each = toset(local.project_api)

  project = var.gcp_project
  service = each.key

  disable_dependent_services = true
  disable_on_destroy         = false
}
