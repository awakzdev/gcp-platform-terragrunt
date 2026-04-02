variable "gcp_availability_zone" {
  description = "GCP availability zone"
}

variable "name_prefix" {
  description = "naming prefix for resources"
}

variable "gcp_project" {
  description = "project id"
}

variable "gcp_region" {
  description = "region"
}

variable "labels" {
  type = map(string)
  default = {
    environment = "demo"
  }
}