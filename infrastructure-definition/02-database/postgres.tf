##################################################################################
##
## Issuing Cloud-SQL Postgres Database
## Multiple components are included in this module, full list can be found at : 
## https://registry.terraform.io/modules/GoogleCloudPlatform/sql-db/google/latest
##
##################################################################################

data "google_compute_network" "default" {
  name = "${var.name_prefix}-vpc"
}

# Generates a Postgresql database
module "sql_db_postgresql" {
  source              = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version             = "18.1.0"
  database_version    = var.db_version # 'POSTGRES_9_6', 'POSTGRES_10', 'POSTGRES_12', 'POSTGRES_13', 'POSTGRES_14'
  name                = "${var.name_prefix}-cloudsql-postgresql"
  project_id          = var.gcp_project
  region              = var.gcp_region
  zone                = var.gcp_availability_zone
  deletion_protection = true

  tier              = var.db_size_tier
  edition           = "ENTERPRISE"
  availability_type = var.db_availability_type
  disk_size         = 25
  disk_autoresize   = true
  disk_type         = "PD_SSD"

  enable_default_db              = false
  enable_default_user            = true
  enable_random_password_special = false
  user_name                      = var.db_user_name
  user_password                  = var.db_user_password == "" ? "" : var.db_user_password
  user_deletion_policy           = "ABANDON"

  # Prevents resource from changing when database is imported to statefile

  insights_config = {
    query_string_length     = 4500
    record_application_tags = false
    record_client_address   = false
  }

  backup_configuration = {
    enabled                        = true
    start_time                     = "21:55"
    location                       = null
    point_in_time_recovery_enabled = false
    transaction_log_retention_days = null
    retained_backups               = 14
    retention_unit                 = "COUNT"
  }

  read_replicas = [
    {
      name                  = ""
      name_override         = try(var.db_replica.name_override, false) ? var.db_replica.name_override : null
      tier                  = var.db_replica.tier
      edition               = "ENTERPRISE"
      availability_type     = var.db_availability_type
      zone                  = var.gcp_availability_zone
      disk_type             = "PD_SSD"
      disk_autoresize       = true
      disk_autoresize_limit = 0
      disk_size             = 25
      user_labels           = { environment = var.name_prefix }
      database_flags        = var.db_flags
      ip_configuration = {
        "allocated_ip_range" : null,
        "authorized_networks" : var.db_autorized_networks,
        "ipv4_enabled" : true,
        "private_network" : data.google_compute_network.default.id,
        "require_ssl" : null
      }
      encryption_key_name = null
    }
  ]
  ip_configuration = {
    "allocated_ip_range" : null,
    "authorized_networks" : var.db_autorized_networks,
    "ipv4_enabled" : true,
    "private_network" : data.google_compute_network.default.id,
    "require_ssl" : null
  }
  database_flags = var.db_flags
  additional_users = [
    {
      name            = var.db_authenticator_username
      password        = var.db_authenticator_password
      random_password = false
    }
  ]

  user_labels = {
    environment = var.name_prefix
  }

  create_timeout = "30m"

}

locals {
  replica_private_ip = try([for k in flatten(module.sql_db_postgresql.replicas_instance_first_ip_addresses) : k if lookup(k, "type", "") == "PRIVATE"][0].ip_address, module.sql_db_postgresql.private_ip_address)
  db_secrets = {
    "db_admin_url" : "postgres://${var.db_user_name}:${var.db_user_password == "" ? module.sql_db_postgresql.generated_user_password : var.db_user_password}@${module.sql_db_postgresql.private_ip_address}/postgres"
    "db_url" : "postgres://${var.db_authenticator_username}:${var.db_authenticator_password == "" ? module.sql_db_postgresql.generated_user_password : var.db_authenticator_password}@${module.sql_db_postgresql.private_ip_address}/postgres"
    "db_read_only_url" : "postgres://${var.db_authenticator_username}:${var.db_authenticator_password == "" ? module.sql_db_postgresql.generated_user_password : var.db_authenticator_password}@${local.replica_private_ip}/postgres"
    "db_name" : "postgres"
    "db_user" : var.db_authenticator_username
    "db_password" : var.db_authenticator_password == "" ? module.sql_db_postgresql.generated_user_password : var.db_authenticator_password
    "pg_connection_string" : "postgres://${var.db_user_name}:${var.db_user_password == "" ? module.sql_db_postgresql.generated_user_password : var.db_user_password}@${module.sql_db_postgresql.private_ip_address}/postgres"
  }
}

module "pg_db_secret" {
  source = "../modules/gcp_secret"

  for_each = local.db_secrets

  secret_name  = "${upper(var.name_prefix)}_${upper(each.key)}"
  secret_value = each.value
  gcp_project  = var.gcp_project
  labels = merge(
    { component = "db" }
  , var.labels)
}
