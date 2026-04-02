resource "google_secret_manager_secret" "secret" {
  project = var.gcp_project

  labels    = var.labels
  secret_id = var.secret_name
  replication {
    automatic = true
  }
}

# Add the secret data to GCP secret manager
resource "google_secret_manager_secret_version" "secret_version" {
  secret      = google_secret_manager_secret.secret.id
  secret_data = var.secret_value

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      secret_data, enabled
    ]
  }
}