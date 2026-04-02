locals {
  fqdn = "${var.name_prefix}.${var.base_domain}"

  additional_subdomains = toset([for k in var.additional_dns_zones : k if endswith(k, ".example.com")])
}