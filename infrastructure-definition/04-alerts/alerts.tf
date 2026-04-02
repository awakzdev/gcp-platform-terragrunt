resource "google_monitoring_alert_policy" "workflows" {
  display_name = "Workflows alert policy" # This will be shown as the primary topic when alerting
  combiner     = "OR"
  conditions {
    display_name = "Error condition"
    condition_matched_log {
      filter = "resource.type=\"workflows.googleapis.com/Workflow\" severity=ERROR"
    }
  }

  documentation {
    content = "This message will show up within your text field - [markup](www.google.com) is available"
  }

  notification_channels = [for email in google_monitoring_notification_channel.email_notification : email.name]
  # if multiple notifications channels exist the following example may be used:
  # notification_channels = concat([for email in google_monitoring_notification_channel.email_notification: email.name], [google_monitoring_notification_channel.default.name])

  alert_strategy {
    notification_rate_limit {
      period = "300s" # 300 = 5 minutes \ 3600 = 1 hour
    }
  }

  lifecycle {
    replace_triggered_by = [
      google_monitoring_notification_channel.email_notification
    ]
    create_before_destroy = true
  }
}

locals {
  alert_email_address = jsondecode(file("${path.module}/alert_mail.json"))
}

resource "google_monitoring_notification_channel" "email_notification" {
  for_each = toset(local.alert_email_address)

  display_name = "Log errors notification channel - ${split("@", each.key)[0]}"
  type         = "email"
  labels = {
    email_address = each.key
  }
  force_delete = true
}
