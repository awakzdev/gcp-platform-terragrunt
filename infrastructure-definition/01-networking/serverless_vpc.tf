###########################
##
## Serverless VPC connector
##
###########################

# Serverless VPC Connector for VPC to connect cloud functions to main VPC network
# ***This resources needs a subnet mask of /28***
resource "google_vpc_access_connector" "serverless_vpc" {
  name    = "${var.name_prefix}-vpc-connector"
  region  = var.gcp_functions_region
  project = var.gcp_project
  # ip_cidr_range = var.ip_cidr_range_serverless
  # network       = google_compute_network.default.name

  subnet {
    name       = google_compute_subnetwork.cloud_function_subnet.name
    project_id = var.gcp_project
  }

  lifecycle {
    ignore_changes = [
      machine_type,
      max_throughput,
      min_throughput
    ]
  }
}