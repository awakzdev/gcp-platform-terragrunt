variable "name_prefix" {
  description = "naming prefix for resources"
}

variable "gcp_project" {
  description = "project id"
}

variable "gcp_region" {
  description = "region"
}

variable "gcp_functions_region" {
  description = "Region to deploy the GCP functions. Some newer regions such as me-west1 don't support functions yet so it might be required to use a different region for the functions"
}

variable "function_storage_location" {
  description = "Geo-location for cloud functions storage (can be EU or US)"
}

variable "bootstrap_function_object" {
  type        = map(string)
  description = "A map of which bootstrap zip archive to use depending on runtime to setup the function"
  default = {
    python38 = "bootstrap_python_function.zip"
    nodejs18 = "bootstrap_nodejs_function.zip"
    nodejs16 = "bootstrap_nodejs_function.zip"
    nodejs10 = "bootstrap_nodejs_function.zip"
    nodejs12 = "bootstrap_nodejs_function.zip"
  }
}

variable "base_domain" {
  description = "Base domain to reference for subdomain creation"
}