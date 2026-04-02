#####################################################################
##
## Generating a load balancer and CDN
## This functionality will serving static content
##
#####################################################################

# Issues a TLS Policy stating 'version - TLS 1.2 =>'
resource "google_compute_ssl_policy" "ssl_policy" {
  name            = "${var.name_prefix}-ssl-policy"
  profile         = "RESTRICTED"
  min_tls_version = "TLS_1_2"
}

resource "random_id" "certificate" {
  byte_length = 4

  keepers = {
    domains = join(",", tolist([local.fqdn]), var.additional_base_domains)
  }
}

# Issue a certificate
resource "google_compute_managed_ssl_certificate" "default" {
  for_each = local.backends_by_environment
  name     = "${var.name_prefix}-static-certificate-${random_id.certificate.hex}"

  managed {
    domains = concat(["${each.key}.${local.fqdn}."], [for base_domain in var.additional_base_domains : format("%s.%s", each.key, base_domain)])
  }
  lifecycle {
    create_before_destroy = true
  }
}

# URL Map (Load balancer settings)
resource "google_compute_url_map" "default" {
  name            = replace("static.${local.fqdn}", ".", "-")
  default_service = module.cdn_buckets["${var.name_prefix}-mycompany"].backend_bucket_id

  dynamic "host_rule" {
    for_each = local.backends_by_environment
    content {
      hosts        = concat(["${host_rule.key}.${local.fqdn}."], [for base_domain in var.additional_base_domains : format("%s.%s", host_rule.key, base_domain)])
      path_matcher = host_rule.key
    }
  }
  dynamic "path_matcher" {
    for_each = local.backends_by_environment
    content {
      name            = path_matcher.key
      default_service = path_matcher.value
      route_rules {
        priority = 1
        match_rules {
          prefix_match = "/"
          header_matches {
            header_name = "header"
            exact_match = "A"
          }
        }
        url_redirect {
          path_redirect          = "never-fetch/three-cats.jpg"
          redirect_response_code = "TEMPORARY_REDIRECT"
        }
      }
    }
  }
}

# Target HTTPS proxy
resource "google_compute_target_https_proxy" "lb_proxy" {
  name             = "${var.name_prefix}-lb-proxy"
  url_map          = google_compute_url_map.default.self_link
  ssl_certificates = [for k, v in google_compute_managed_ssl_certificate.default : v.self_link]
  ssl_policy       = google_compute_ssl_policy.ssl_policy.name
}

# Forwarding rule
resource "google_compute_global_forwarding_rule" "lb_rule" {
  name       = "${var.name_prefix}-lb-rule"
  ip_address = google_compute_global_address.default.address
  port_range = "443"
  target     = google_compute_target_https_proxy.lb_proxy.self_link
}
