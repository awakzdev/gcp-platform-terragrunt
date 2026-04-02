## SERVICE ACCOUNTS FOR GKE SERVICES ##

# External DNS SA
resource "google_service_account" "external_dns_sa" {
  account_id   = "${var.name_prefix}-external-dns"
  description  = "SA for external dns"
  display_name = "${var.name_prefix}-external-dns"
}

resource "google_project_iam_member" "external_dns_sa_permissions" {
  project = var.gcp_project
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.external_dns_sa.email}"
}

resource "google_service_account" "dns_solver_sa" {
  account_id   = "${var.name_prefix}-dns-solver"
  description  = "SA for cert manager dns solver"
  display_name = "${var.name_prefix}-dns-solver"
}

resource "google_project_iam_member" "dns_solver_sa_permissions" {
  project = var.gcp_project
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.dns_solver_sa.email}"
}
resource "google_service_account" "external_secrets_sa" {
  account_id   = "${var.name_prefix}-external-secrets"
  description  = "External secrets operator service account"
  display_name = "${var.name_prefix}-external-secrets"
}

resource "google_project_iam_member" "external_secrets_sa_permissions" {
  project = var.gcp_project
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.external_secrets_sa.email}"
}

resource "google_project_iam_member" "external_secrets_sa_viewer_permissions" {
  project = var.gcp_project
  role    = "roles/secretmanager.viewer"
  member  = "serviceAccount:${google_service_account.external_secrets_sa.email}"
}

### Application access SA
resource "google_service_account" "app_access_sa" {
  account_id   = "${var.name_prefix}-app-access"
  description  = "Application access FIXME - migrate to workload identity"
  display_name = "${var.name_prefix}-app-access"
}

resource "google_project_iam_member" "app_access_sa_permissions" {
  project = var.gcp_project
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.app_access_sa.email}"
}

resource "google_service_account_key" "app_access_key" {
  service_account_id = google_service_account.app_access_sa.name
}

### Argocd SSO SA
resource "google_service_account" "argocd_sso_sa" {
  account_id   = "${var.name_prefix}-argocd-sso"
  description  = "Argocd SA for SSO with Google Workspace"
  display_name = "${var.name_prefix}-argocd-sso"
}

# resource "google_project_iam_member" "argocd_sso_sa_permissions" {
#   project = var.gcp_project
#   role    = "roles/editor"
#   member  = "serviceAccount:${google_service_account.app_access_sa.email}"
# }

### Config connector  SA
resource "google_service_account" "config_connector_sa" {
  account_id   = "${var.name_prefix}-config-connector"
  description  = "Config connector service account to create GCP resources from GKE manifests"
  display_name = "${var.name_prefix}-config-connector"
}

resource "google_project_iam_member" "config_connector_sa_permissions" {
  project = var.gcp_project
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.config_connector_sa.email}"
}

### Config connector  SA
resource "google_service_account" "gitlab_runner_sa" {
  account_id   = "${var.name_prefix}-gitlab-runner"
  description  = "Gitlab Runner service account to run builds with workload identity permissions"
  display_name = "${var.name_prefix}-gitlab-runner"
}

resource "google_project_iam_member" "gitlab_runner_sa_permissions" {
  project = var.gcp_project
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.gitlab_runner_sa.email}"
}

### Application access SA
resource "google_service_account" "carwiz_backend_sa" {
  account_id   = "${var.name_prefix}-mycompany-backend"
  description  = "SA for backend service access via gke workload identity"
  display_name = "${var.name_prefix}-mycompany-backend"
}

locals {
  backend_roles = [
    "roles/firebaseappcheck.admin",
    "roles/editor",
    "roles/iam.serviceAccountTokenCreator",
    ### All the roles below are included in editor and should be enabled and tightened when editor role is dropped due to security exposure

    # "roles/cloudfunctions.invoker",
    # "roles/bigquery.jobUser",
    # "roles/cloudsql.client",
    # "roles/cloudtrace.agent",
    # "roles/firebase.analyticsViewer",
    # "roles/pubsub.publisher"
  ]
}

resource "google_project_iam_member" "carwiz_backend_sa_permissions" {
  project = var.gcp_project
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.carwiz_backend_sa.email}"
}

### UI access SA
resource "google_service_account" "carwiz_ui_sa" {
  account_id   = "${var.name_prefix}-mycompany-ui"
  description  = "SA for ui service access via gke workload identity"
  display_name = "${var.name_prefix}-mycompany-ui"
}

locals {
  ui_roles = [
    "roles/editor",
    "roles/bigquery.admin"
    ### All the roles below are included in editor and should be enabled and tightened when editor role is dropped due to security exposure

    # "roles/cloudfunctions.invoker",
    # "roles/bigquery.jobUser",
    # "roles/cloudsql.client",
    # "roles/cloudtrace.agent",
    # "roles/firebase.analyticsViewer",
    # "roles/pubsub.publisher"
  ]
}
resource "google_project_iam_member" "carwiz_ui_sa_permissions" {
  count   = length(local.ui_roles)
  project = var.gcp_project
  role    = local.ui_roles[count.index]
  member  = "serviceAccount:${google_service_account.carwiz_ui_sa.email}"
}