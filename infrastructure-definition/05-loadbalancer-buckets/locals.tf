locals {
  fqdn = "${var.name_prefix}.${var.base_domain}"

  backends_by_environment = {
    cdn = module.cdn_buckets[replace("${var.name_prefix}-mycompany", ".", "-")].backend_bucket_id
  }

  dns_records = flatten([
    for dom in ["cdn"] : [
      for base in concat([local.fqdn], var.additional_base_domains) : {
        domain      = dom
        base_domain = base
      }
    ]
  ])

  public_buckets = [
    "carwiz_catalog",
  ]

  cdn_buckets = {
    replace("${var.name_prefix}-mycompany", ".", "-") = {}
  }

}
