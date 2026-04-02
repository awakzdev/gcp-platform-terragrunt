variable "gcp_project" {
  description = "project id"
}

variable "gcp_region" {
  description = "region"
}

variable "gcp_functions_region" {
  description = "Region to deploy the GCP functions. Some newer regions such as me-west1 don't support functions yet so it might be required to use a different region for the functions"
}

variable "name_prefix" {
  description = "naming prefix for resources"
}

variable "ip_cidr_range" {
  type        = string
  description = "IP cidr for main vpc for the project and non-gke resources, for example 10.0.0.0/24. This should preferrably come from an IPAM system and not overlap with other organizational IP subnets for easier peering and routing in the future"
}

variable "function_ip_cidr_range" {
  type        = string
  description = "IP cidr for the cloud functions subnet. Required in case main infra is deployed in a region where cloud functions and VPC connector are not available."
}

variable "pod_ip_range" {
  type        = string
  description = "IP cidr for GCP resources, for example 10.100.0.0/16. This should be at least a/16 range and a come from a private CIDR, otherwise routing issues can occur"
}

variable "services_ip_range" {
  type        = string
  description = "IP cidr for GCP resources, for example 10.101.0.0/16. This should be at least a /17 range, and a come from a private CIDR, otherwise routing issues can occur"
}

variable "ip_cidr_range_sql" {
  type        = string
  description = "IP address range for dedicated Cloud SQL peering"
  default     = "10.0.0.0/16"
}

variable "ip_cidr_range_redis" {
  type        = string
  description = "IP address range for dedicated Redis allocation"
  default     = "10.0.0.0/16"
}