variable "gcp_region" {
  description = "region"
}

variable "gcp_project" {
  description = "project id"
}

variable "name_prefix" {
  description = "naming prefix for resources"
}

variable "base_domain" {
  description = "Base domain to reference for subdomain creation"

}

variable "bucket_upload" {
  type        = bool
  description = "Whether to upload files or not to CDN Buckets via local-exec"
  default     = false
}

variable "base_domain_project" {
  description = "The project id if the project where the base_domain dns zone is hosted"
}

variable "additional_base_domains" {
  description = "A list of additional base domains to generate DNS records and certificates for"
  default     = []
  type        = list(any)
}
