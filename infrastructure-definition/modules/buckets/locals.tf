locals {
  dynamic_cors = [
    "https://pro.${var.name_prefix}.example.com",
    "https://pro-gke.${var.name_prefix}.example.com",
    "https://admin-gke.${var.name_prefix}.example.com",
    "https://admin.${var.name_prefix}.example.com",
    "https://ui.${var.name_prefix}.example.com",
    "https://api.${var.name_prefix}.example.com"
  ]

  static_cors = [
    "https://example.com",
    "https://example.com",
    "https://example.com",
    "https://example.com",
    "https://example.com",
    "https://example.com",
    "https://example.com",
    "https://example.com",
  ]
  all_cors = concat(local.dynamic_cors, local.static_cors)
}