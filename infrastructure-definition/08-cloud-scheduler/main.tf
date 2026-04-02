locals {
  jobs = jsondecode(file("${path.module}/jobs.json"))
}

resource "google_cloud_scheduler_job" "job" {
  for_each = local.jobs

  name        = "${var.name_prefix}-${each.key}"
  description = lookup(each.value, "description", null)
  schedule    = each.value.schedule
  time_zone   = each.value.timeZone
  region      = "us-central1"
  paused      = lookup(each.value, "state", null) == "PAUSED" ? true : false

  dynamic "retry_config" {
    for_each = contains(keys(each.value), "retryConfig") ? [1] : []
    content {
      max_backoff_duration = each.value.retryConfig.maxBackoffDuration
      max_doublings        = each.value.retryConfig.maxDoublings
      max_retry_duration   = each.value.retryConfig.maxRetryDuration
      min_backoff_duration = each.value.retryConfig.minBackoffDuration
      retry_count          = lookup(each.value.retryConfig, "retryCount", null) != null ? each.value.retryConfig.retryCount : null
    }
  }

  dynamic "pubsub_target" {
    for_each = contains(keys(each.value), "pubsubTarget") ? [1] : []
    content {
      topic_name = can(regex("projects/", each.value.pubsubTarget.topicName)) ? each.value.pubsubTarget.topicName : "projects/${var.gcp_project}/topics/${var.name_prefix}-${each.value.pubsubTarget.topicName}"
      data       = each.value.pubsubTarget.data
    }
  }

  dynamic "http_target" {
    for_each = contains(keys(each.value), "httpTarget") ? [1] : []
    content {
      http_method = each.value.httpTarget.httpMethod
      uri         = each.value.httpTarget.uri
      body        = lookup(each.value.httpTarget, "body", null) != null ? base64encode(each.value.httpTarget.body) : null

      dynamic "oidc_token" {
        for_each = contains(keys(each.value.httpTarget), "oidcToken") ? [1] : []
        content {
          service_account_email = lookup(each.value.httpTarget.oidcToken, "serviceAccountEmail", null) != null ? each.value.httpTarget.oidcToken.serviceAccountEmail : google_service_account.cloud_scheduler_sa.email
          audience              = lookup(each.value.httpTarget.oidcToken, "audience", null) != null ? each.value.httpTarget.oidcToken.audience : each.value.httpTarget.uri
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      retry_config, paused
    ]
  }
}
