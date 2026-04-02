data "google_dns_managed_zone" "env_dns_zone" {
  for_each = toset(concat([local.fqdn], var.additional_base_domains))
  name     = replace(each.key, ".", "-")
}


# Add the IP to the DNS
resource "google_dns_record_set" "website" {
  for_each     = { for rec in local.dns_records : "${rec.domain}.${rec.base_domain}" => rec }
  provider     = google
  name         = "${each.value.domain}.${each.value.base_domain}."
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.env_dns_zone[each.value.base_domain].name
  rrdatas      = [google_compute_global_address.default.address]
}

# Reserved IP address for loadbalancing
resource "google_compute_global_address" "default" {
  name = "${var.name_prefix}-forwarding-rule-reserved-static-ip"
}

