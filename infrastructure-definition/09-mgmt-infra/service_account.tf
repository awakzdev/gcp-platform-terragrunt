resource "google_service_account" "mgmt_vm_sa" {
  account_id   = "${var.name_prefix}-mgmt-vm-sa"
  description  = "Management VM service account"
  display_name = "${var.name_prefix}-mgmt-vm-sa"
}

resource "google_project_iam_member" "mgmt_vm_sa_permissions" {
  project = var.gcp_project
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.mgmt_vm_sa.email}"
}
