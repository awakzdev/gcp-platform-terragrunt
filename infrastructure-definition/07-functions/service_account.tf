### Cloud functions SA
locals {
  cloud_functions_sa_roles = [
    "roles/bigquery.jobUser",
    "roles/bigquery.dataEditor",
    "roles/cloudfunctions.invoker",
    "roles/cloudsql.client",
    "roles/cloudtrace.agent",
    "roles/compute.networkUser",
    "roles/firebase.analyticsViewer",
    "roles/iam.serviceAccountTokenCreator",
    "roles/pubsub.publisher",
    "roles/secretmanager.secretAccessor",
    "roles/storage.admin",
    "roles/datastore.user"
  ]
}

resource "google_service_account" "cloud_functions_sa" {
  account_id   = "${var.name_prefix}-cloud-functions-sa"
  description  = "Cloud functions execution service account"
  display_name = "${var.name_prefix}-cloud-functions-sa"
}

resource "google_project_iam_member" "cloud_functions_sa_permissions" {
  count   = length(local.cloud_functions_sa_roles)
  project = var.gcp_project
  role    = local.cloud_functions_sa_roles[count.index]
  member  = "serviceAccount:${google_service_account.cloud_functions_sa.email}"
}

# resource "google_project_iam_member" "cloud_functions_sa_permissions" {
#   project = var.gcp_project
#   role    = "roles/secretmanager.secretAccessor"
#   member  = "serviceAccount:${google_service_account.cloud_functions_sa.email}"
# }

# resource "google_project_iam_member" "cloud_functions_sa_permissions" {
#   project = var.gcp_project
#   role    = "roles/cloudfunctions.invoker"
#   member  = "serviceAccount:${google_service_account.cloud_functions_sa.email}"
# }

# resource "google_project_iam_member" "cloud_functions_sa_permissions" {
#   project = var.gcp_project
#   role    = "roles/pubsub.publisher"
#   member  = "serviceAccount:${google_service_account.cloud_functions_sa.email}"
# }

# resource "google_project_iam_member" "cloud_functions_sa_permissions" {
#   project = var.gcp_project
#   role    = "roles/bigquery.jobUser"
#   member  = "serviceAccount:${google_service_account.cloud_functions_sa.email}"
# }
# resource "google_project_iam_member" "cloud_functions_sa_permissions" {
#   project = var.gcp_project
#   role    = "roles/cloudsql.client"
#   member  = "serviceAccount:${google_service_account.cloud_functions_sa.email}"
# }

# resource "google_project_iam_member" "cloud_functions_sa_permissions" {
#   project = var.gcp_project
#   role    = "roles/bigquery.jobUser"
#   member  = "serviceAccount:${google_service_account.cloud_functions_sa.email}"
# }

# resource "google_project_iam_member" "cloud_functions_sa_permissions" {
#   project = var.gcp_project
#   role    = "roles/cloudtrace.agent"
#   member  = "serviceAccount:${google_service_account.cloud_functions_sa.email}"
# }
# resource "google_project_iam_member" "cloud_functions_sa_permissions" {
#   project = var.gcp_project
#   role    = "roles/firebase.analyticsViewer"
#   member  = "serviceAccount:${google_service_account.cloud_functions_sa.email}"
# }
# resource "google_project_iam_member" "cloud_functions_sa_permissions" {
#   project = var.gcp_project
#   role    = "roles/iam.serviceAccountTokenCreator"
#   member  = "serviceAccount:${google_service_account.cloud_functions_sa.email}"
# }
