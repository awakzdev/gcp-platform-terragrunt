
locals {
  http_trigger_functions_list_ordered = tolist(local.http_trigger_functions_list)
}

variable "home_function_key" {
  type    = string
  default = "fast_check_http"
}

data "google_compute_ssl_policy" "ssl_policy" {
  name = "${var.name_prefix}-ssl-policy"
}

resource "google_compute_global_address" "functions" {
  name = "${var.name_prefix}-functions-lb-address"
}

resource "google_compute_managed_ssl_certificate" "functions" {
  name = "${var.name_prefix}-actions-certificate"

  managed {
    domains = ["actions.${local.fqdn}."] # trailing dot OK
  }
}

resource "google_compute_target_https_proxy" "lb_proxy" {
  name             = "${var.name_prefix}-functions-lb-proxy"
  url_map          = google_compute_url_map.functions.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.functions.self_link]
  ssl_policy       = data.google_compute_ssl_policy.ssl_policy.name
  lifecycle {
    replace_triggered_by = [google_compute_url_map.functions]
  }
}

resource "google_compute_url_map" "functions" {
  name = replace("actions.${local.fqdn}", ".", "-")

  default_service = google_compute_backend_service.serverless_service[var.home_function_key].self_link

  host_rule {
    hosts        = ["actions.${local.fqdn}"]
    path_matcher = var.name_prefix
  }

  path_matcher {
    name = var.name_prefix

    default_service = google_compute_backend_service.serverless_service[var.home_function_key].self_link

    dynamic "route_rules" {
      for_each = {
        for idx, name in local.http_trigger_functions_list_ordered : name => idx
      }
      content {
        priority = route_rules.value + 1

        match_rules {
          prefix_match = "/${route_rules.key}"
        }

        route_action {
          url_rewrite {
            path_prefix_rewrite = "/${var.name_prefix}-${route_rules.key}"
          }
        }

        service = google_compute_backend_service.serverless_service[route_rules.key].self_link
      }
    }

    route_rules {
      priority = 9999
      match_rules { prefix_match = "/" }
      route_action {
        url_rewrite { path_prefix_rewrite = "/${var.name_prefix}-${var.home_function_key}" }
      }
      service = google_compute_backend_service.serverless_service[var.home_function_key].self_link
    }
  }

  lifecycle {
    replace_triggered_by = [google_compute_backend_service.serverless_service]
  }
}

resource "random_string" "neg_name_suffix" {
  for_each = toset(local.http_trigger_functions_list)
  length   = 8
  special  = false
  upper    = false
  numeric  = false
}

resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  for_each              = toset(local.http_trigger_functions_list)
  name                  = join("-", [replace("${var.name_prefix}-${each.key}-neg", "_", "-"), random_string.neg_name_suffix[each.key].result])
  network_endpoint_type = "SERVERLESS"
  region                = var.gcp_functions_region
  cloud_function { function = "${var.name_prefix}-${each.key}" }
  lifecycle { create_before_destroy = true }
}

resource "google_compute_backend_service" "serverless_service" {
  for_each              = toset(local.http_trigger_functions_list)
  name                  = replace("${var.name_prefix}-${each.key}-backend-service", "_", "-")
  protocol              = "HTTPS"
  port_name             = "http"
  enable_cdn            = false
  security_policy       = null
  load_balancing_scheme = "EXTERNAL"
  backend { group = google_compute_region_network_endpoint_group.serverless_neg[each.key].self_link }
}

resource "google_compute_backend_service" "actions_home" {
  name                  = "${var.name_prefix}-actions-home"
  port_name             = "http"
  protocol              = "HTTP"
  timeout_sec           = 10
  health_checks         = [google_compute_health_check.actions.id]
  load_balancing_scheme = "EXTERNAL"
}

resource "google_compute_health_check" "actions" {
  name = "${var.name_prefix}-actions-health-check"
  http_health_check { port = 80 }
}

resource "google_compute_global_forwarding_rule" "forwarding" {
  name                  = "${var.name_prefix}-functions-https-lb-rule"
  target                = google_compute_target_https_proxy.lb_proxy.self_link
  port_range            = "443"
  ip_address            = google_compute_global_address.functions.address
  load_balancing_scheme = "EXTERNAL"
  lifecycle { replace_triggered_by = [google_compute_target_https_proxy.lb_proxy] }
}

data "google_dns_managed_zone" "env_dns_zone" {
  name = replace("${local.fqdn}", ".", "-")
}

resource "google_dns_record_set" "actions" {
  name         = "actions.${local.fqdn}."
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.env_dns_zone.name
  rrdatas      = [google_compute_global_address.functions.address]
}
