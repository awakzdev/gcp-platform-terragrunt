data "google_compute_network" "default" {
  name = "${var.name_prefix}-vpc"
}

resource "google_redis_instance" "cache" {
  name         = "${var.name_prefix}-redis"
  location_id  = "${var.gcp_region}-a"
  tier         = "BASIC"
  connect_mode = "PRIVATE_SERVICE_ACCESS"

  memory_size_gb     = var.redis_size
  redis_version      = var.redis_version != null ? var.redis_version : null # Latest version will be used if not specified.
  authorized_network = data.google_compute_network.default.id               # The full name of the Google Compute Engine network to which the instance is connected.

  # persistence_config {
  #   persistence_mode = "RDB"
  #   rdb_snapshot_period = "TWELVE_HOURS"
  # }

  labels = {
    terraform   = "true"
    environment = var.name_prefix
  }

  maintenance_policy {
    weekly_maintenance_window {
      day = "TUESDAY"
      start_time {
        hours   = 0
        minutes = 30
        seconds = 0
        nanos   = 0
      }
    }
  }

  lifecycle {
    ignore_changes = [
      memory_size_gb
    ]
  }
}

locals {
  redis_secrets = {
    "REDIS_HOST" = google_redis_instance.cache.host
    "REDIS_PORT" = tostring(google_redis_instance.cache.port)
  }
}

module "redis_secret" {
  source = "../modules/gcp_secret"

  for_each = local.redis_secrets

  secret_name  = "${upper(var.name_prefix)}_${upper(each.key)}"
  secret_value = each.value
  gcp_project  = var.gcp_project
  labels = merge(
    { component = "redis",
    ui = "true" }
  , var.labels)
}