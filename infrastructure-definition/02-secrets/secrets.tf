# This manifest defines the shared secrets for the environment
# Used to populate cloud function variables, GKE external secrets operator and external services

# GCP Secret to hold graphile license

locals {

  secret_values = fileexists("${path.module}/secret_values.secret") ? jsondecode(file("${path.module}/secret_values.secret")) : {}
  secrets       = fileexists("${path.module}/secrets.json") ? jsondecode(file("${path.module}/secrets.json")) : {}
}

module "secrets" {
  source   = "../modules/gcp_secret"
  for_each = local.secrets

  secret_name  = "${upper(var.name_prefix)}_${upper(each.key)}"
  secret_value = lookup(lookup(local.secret_values, each.key, { "value" : "BLANK" }), "value", "BLANK")
  gcp_project  = var.gcp_project

  labels = merge(
    lookup(each.value, "labels", {}),
    var.labels
  )
}