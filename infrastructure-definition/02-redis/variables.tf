variable "name_prefix" {
  description = "naming prefix for resources"
}

variable "gcp_project" {
  description = "project id"
}

variable "gcp_region" {
  description = "region"
}

variable "redis_version" {
  description = "redis version"
}

variable "redis_size" {
  description = "redis memory in gb"
}

variable "labels" {
  type        = map(string)
  description = "The labels to attach to the secrets exported by this db creation (passwords, connection strings, etc). Used by GKE external secrets manager to map secrets to GKE namespaces"
  default = {
    environment = "demo"
  }
}