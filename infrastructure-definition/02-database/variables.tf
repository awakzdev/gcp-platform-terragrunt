
variable "gcp_availability_zone" {
  description = "GCP availability zone"
  type        = string
}

variable "name_prefix" {
  description = "naming prefix for resources"
  type        = string
}

variable "gcp_project" {
  description = "project id"
  type        = string
}

variable "gcp_region" {
  description = "region"
  type        = string
}

## DATABASE VARIABLES

variable "db_version" {
  type        = string
  description = "Postgres version to deploy. Options are: 'POSTGRES_9_6', 'POSTGRES_10', 'POSTGRES_12', 'POSTGRES_13', 'POSTGRES_14'"
}

variable "db_size_tier" {
  description = "The tier (machine size) of the DB instance. See here for options - https://cloud.google.com/sql/docs/postgres/instance-settings#machine-type-2ndgen"
  default     = "db-f1-micro"
  type        = string
}

variable "db_availability_type" {
  description = "The availability type of the DB instance for HA purposes. Can be \"ZONAL\" or \"REGIONAL\"."
  default     = "ZONAL"
  type        = string
}

variable "db_user_name" {
  description = "user name for GCP Cloud-SQL"
  default     = "postgres"
  type        = string
}

variable "db_user_password" {
  type        = string
  description = "User password for GCP Cloud-SQL. If not set, will be generated on instance creation and exported to secret (recommended)"
  default     = ""
}

variable "db_authenticator_username" {
  type        = string
  default     = "authenticator"
  description = "Authenticator user password for non-admin application db access"
}

variable "db_authenticator_password" {
  type        = string
  description = "Authenticator user password for non-admin application db access"
}

variable "db_autorized_networks" {
  type        = list(map(string))
  description = "List of authorized networks for DB access. Format is [{name = \"networkname\", value = \"cidr\"}]"
  default = [
    { name = "fivetran", value = "10.0.0.0/16" },
    { name = "fivetran-2", value = "10.0.0.0/16" },
    { name = "fivetran-3", value = "10.0.0.0/16" }
  ]
}

variable "db_flags" {
  type        = list(map(string))
  description = "List of flags to configure on the db"
  default = [
    { name = "max_connections", value = "500" },
    { name = "cloudsql.logical_decoding", value = "on" },
    { name = "log_min_messages", value = "info" },
    { name = "log_min_error_statement", value = "info" },
    { name = "temp_file_limit", value = "2147483647" },
    { name = "log_statement", value = "mod" },
    { name = "work_mem", value = "1310720" }
  ]
}

variable "db_replica" {
  type        = map(string)
  description = "DB Read replica configuration"

}

variable "labels" {
  type        = map(string)
  description = "The labels to attach to the secrets exported by this db creation (passwords, connection strings, etc). Used by GKE external secrets manager to map secrets to GKE namespaces"
  default = {
    environment = "demo"
  }
}