generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  backend "gcs" {
     bucket = "my-tf-state-bucket"
    prefix = "terraform/state/mycompany/${basename(dirname(get_terragrunt_dir()))}/${local.dir_name}"
  }
}
EOF
}

locals {
  release_ref = "dev"
  dir_name = path_relative_to_include()
  common_vars = yamldecode(file("common_vars.yaml"))
  secret_vars = yamldecode(file("secret_vars.yaml"))
}

terraform {

  // before_hook "before_hook" {
  //   commands     = ["apply", "plan", "init"]
  //   execute      = ["gcloud", "auth", "application-default", "login","--no-launch-browser"]
  // }
  // source = "git::git@github.com:mycompany/my-gcp-project-id.git//${local.dir_name}?ref=${local.common_vars.release_tag}"
  // source = "git::git@example.com:mycompany/iac/infrastructure-definition.git//${local.dir_name}?ref=${local.release_ref}"
   source = "/home/vadim/Work/mycompany/iac/infrastructure-definition//${local.dir_name}"
}

inputs = {
  gcp_project              = "my-gcp-project-id"
  gcp_region               = "me-west1"
  gcp_availability_zone    = "me-west1-a"
  name_prefix              = basename(dirname(get_terragrunt_dir()))
  ip_cidr_range            = "10.0.0.0/16"
  pod_ip_range             = "10.0.0.0/16"
  services_ip_range        = "10.0.0.0/16"
  ip_cidr_range_sql        = "10.0.0.0/16"
  ip_cidr_range_serverless = "10.0.0.0/16"
  gcp_functions_region     = "us-central1"
  function_ip_cidr_range   = "10.0.0.0/16"
  base_domain              = "example.com"
  base_domain_project      = "my-gcp-project-id"
  db_version               = "POSTGRES_13"
  db_size_tier             = "db-f1-micro"
  db_availability_type     = "ZONAL"
  db_user_name             = "postgres"
  db_authorized_networks   = [{name = "vadim", value = "10.0.0.0/16"}]
  gcp_functions_region      = "us-central1"
  db_authenticator_password = local.secret_vars.db_authenticator_password
  db_autorized_networks    = [
    {name = "Vadim",value = "10.0.0.0/16"},
    {name = "mgmt_vm",value = "10.0.0.0/16"},
    {name = "Amit",value = "10.0.0.0/16"},
    {name = "Rami - home",value = "10.0.0.0/16"}
    ]
  db_replica               = {tier = "db-custom-2-8192"}
  db_backups_enabled       = true
  function_storage_location = "US"
  gitlab_token             = local.secret_vars.gitlab_token
  labels                   = { environment = basename(dirname(get_terragrunt_dir())) }
}