variable "gcp_project" {
  description = "project id"
}

variable "secret_name" {
  description = "The name of the secret to create"

}

variable "secret_value" {
  description = "The value to set to the secret version"
}

variable "labels" {
  type = map(string)
}