data "google_dns_managed_zone" "base_domain_dns_zone" {
  name = replace(var.base_domain, ".", "-")

  project = var.base_domain_project
}

resource "google_dns_managed_zone" "staging" {
  name        = "staging-mycompany-co-il"
  dns_name    = "example.com."
  description = "DNS zone for example.com"
}
# Create the NS records in the parent zone
resource "google_dns_record_set" "staging_ns" {
  provider     = google
  name         = google_dns_managed_zone.staging.dns_name
  type         = "NS"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.base_domain_dns_zone.name
  rrdatas      = google_dns_managed_zone.staging.name_servers

  project = var.base_domain_project
}