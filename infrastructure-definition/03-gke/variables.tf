variable "gcp_project" {
  description = "project id"
  type        = string
}

variable "gcp_region" {
  description = "region"
  type        = string
}

variable "name_prefix" {
  description = "naming prefix for resources"
  type        = string
}

variable "gcp_availability_zone" {
  description = "GCP availability zone"
  type        = string
}

variable "charts" {
  description = "Helm charts boolean creation"
  type        = map(bool)
  default = {
    "cert-manager"              = false
    "external-secrets-operator" = true
    "nginx-ingress"             = false
  }
}

variable "build_pool_initial_node_count" {
  description = "The number of nodes to deploy for initial build pool setup. Should be set to 0 for clusters that don't run builders"
  default     = 0
  type        = number
}