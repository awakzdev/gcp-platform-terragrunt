terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.80.0"
    }
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "15.11.0"
    }
  }
  required_version = ">= 0.14"
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

provider "gitlab" {
  token = var.gitlab_token
}