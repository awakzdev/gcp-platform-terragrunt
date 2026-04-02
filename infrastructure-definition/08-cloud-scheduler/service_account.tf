resource "google_service_account" "cloud_scheduler_sa" {
  account_id   = "${var.name_prefix}-cloud-scheduler-sa"
  description  = "Cloud scheduler execution service account"
  display_name = "${var.name_prefix}-cloud-scheduler-sa"
}

resource "google_project_iam_member" "cloud_functions_admin" {
  project = var.gcp_project
  role    = "roles/cloudfunctions.invoker"
  member  = "serviceAccount:${google_service_account.cloud_scheduler_sa.email}"
}
