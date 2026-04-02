variable "gcp_project" {
  description = "project id"
  type        = string
}

variable "gcp_region" {
  description = "region"
  type        = string
}

variable "name_prefix" {
  description = "Naming prefix for resources"
  type        = string
}

variable "base_domain" {
  description = "Base domain to reference for subdomain creation"
  type        = string
}

variable "base_domain_project" {
  description = "The project id if the project where the base_domain dns zone is hosted"
  type        = string
}

variable "additional_dns_zones" {
  description = "Additional DNS zones to create in this project. If a dns zone is a subdomain of example.com, it is connected to the base domain via NS records"
  default     = []
  type        = list(string)
}