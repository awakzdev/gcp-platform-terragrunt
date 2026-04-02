variable "name_prefix" {
  description = "naming prefix for resources"
}

variable "gcp_project" {
  description = "project id"
}

variable "gcp_region" {
  description = "region"
}

variable "base_domain" {
  description = "Base domain to reference for subdomain creation"
}

variable "base_domain_project" {
  description = "The project id if the project where the base_domain dns zone is hosted"
}