resource "random_string" "random_postfix" {
  length  = 8
  special = false
  numeric = false
  upper   = false
}

resource "google_storage_bucket" "bucket" {
  name                        = "${var.name_prefix}-${var.function_name}-${random_string.random_postfix.result}"
  location                    = var.function_location
  uniform_bucket_level_access = true
  project                     = var.gcp_project
}

resource "google_storage_bucket_object" "function_source" {
  name          = "bootstrap_nodejs_function.zip"
  bucket        = google_storage_bucket.bucket.name
  source        = "./bootstrap_nodejs_function.zip"
  storage_class = "REGIONAL"
  lifecycle {
    ignore_changes = all
  }
}

resource "google_cloudfunctions2_function" "function" {
  name        = replace("${var.name_prefix}-${var.function_name}", "_", "-")
  location    = var.function_location
  description = var.description
  project     = var.gcp_project

  build_config {
    runtime               = var.runtime
    entry_point           = var.entrypoint
    environment_variables = var.build_env_variables

    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.function_source.name
      }
    }
    worker_pool       = var.worker_pool
    docker_repository = var.docker_repository
  }



  dynamic "event_trigger" {
    for_each = var.event_trigger != null ? [var.event_trigger] : []
    content {
      trigger_region        = event_trigger.value["trigger_region"] != null ? event_trigger.value["trigger_region"] : null
      event_type            = event_trigger.value["event_type"] != null ? event_trigger.value["event_type"] : null
      pubsub_topic          = event_trigger.value["pubsub_topic"] != null ? event_trigger.value["pubsub_topic"] : null
      service_account_email = event_trigger.value["service_account_email"] != null ? event_trigger.value["service_account_email"] : null
      retry_policy          = event_trigger.value["retry_policy"] != null ? event_trigger.value["retry_policy"] : null

      dynamic "event_filters" {
        for_each = event_trigger.value.event_filters != null ? event_trigger.value.event_filters : []
        content {
          attribute = event_filters.value.attribute
          value     = event_filters.value.attribute_value
          operator  = event_filters.value.operator
        }
      }
    }
  }

  dynamic "service_config" {
    for_each = var.service_config != null ? [var.service_config] : []
    content {
      max_instance_count    = service_config.value.max_instance_count
      min_instance_count    = service_config.value.min_instance_count
      available_memory      = service_config.value.available_memory
      timeout_seconds       = service_config.value.timeout_seconds
      environment_variables = service_config.value.runtime_env_variables != null ? service_config.value.runtime_env_variables : {}

      vpc_connector                 = service_config.value.vpc_connector
      vpc_connector_egress_settings = service_config.value.vpc_connector != null ? service_config.value.vpc_connector_egress_settings : null
      ingress_settings              = service_config.value.ingress_settings

      service_account_email          = service_config.value.service_account_email
      all_traffic_on_latest_revision = service_config.value.all_traffic_on_latest_revision

      dynamic "secret_environment_variables" {
        for_each = service_config.value.runtime_secret_env_variables != null ? service_config.value.runtime_secret_env_variables : []
        iterator = sev
        content {
          key        = sev.value.key_name
          project_id = sev.value.project_id
          secret     = sev.value.secret
          version    = sev.value.version
        }
      }

      dynamic "secret_volumes" {
        for_each = service_config.value.secret_volumes != null ? service_config.value.secret_volumes : []
        content {
          mount_path = secret_volumes.value.mount_path
          project_id = secret_volumes.value.project_id
          secret     = secret_volumes.value.secret
          dynamic "versions" {
            for_each = secret_volumes.value.versions != null ? secret_volumes.value.versions : []
            content {
              version = versions.value.version
              path    = versions.value.path
            }
          }
        }
      }
    }
  }

  labels = var.labels != null ? var.labels : {}
}
