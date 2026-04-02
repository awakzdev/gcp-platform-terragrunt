#######################
##
## DNS Zone
##
#######################

resource "google_dns_managed_zone" "dns_zone" {
  name        = replace("${local.fqdn}", ".", "-")
  dns_name    = "${local.fqdn}." # a '.' has to bee added at the end
  description = "DNS Zone for ${var.name_prefix} environment"
  labels = {
    environment = var.name_prefix
  }
}

data "google_dns_managed_zone" "base_domain_dns_zone" {
  name = replace(var.base_domain, ".", "-")

  project = var.base_domain_project
}

# Create the NS records in the parent zone
resource "google_dns_record_set" "ns" {
  provider     = google
  name         = google_dns_managed_zone.dns_zone.dns_name
  type         = "NS"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.base_domain_dns_zone.name
  rrdatas      = google_dns_managed_zone.dns_zone.name_servers

  project = var.base_domain_project
}

resource "google_dns_managed_zone" "additional_dns_zones" {
  for_each    = local.additional_subdomains
  name        = replace("${each.key}", ".", "-")
  dns_name    = "${each.key}." # a '.' has to bee added at the end
  description = "DNS Zone for domain ${each.key} attached to ${var.name_prefix} environment"
  labels = {
    environment = var.name_prefix
  }
}

resource "google_dns_record_set" "additonal_subdomain_ns_records" {
  for_each     = local.additional_subdomains
  provider     = google
  name         = google_dns_managed_zone.additional_dns_zones[each.key].dns_name
  type         = "NS"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.base_domain_dns_zone.name
  rrdatas      = google_dns_managed_zone.additional_dns_zones[each.key].name_servers

  project = var.base_domain_project
}