# VPC
resource "google_compute_network" "default" {
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "default" {
  name                     = "${var.name_prefix}-main-subnet"
  region                   = var.gcp_region
  network                  = google_compute_network.default.name
  ip_cidr_range            = var.ip_cidr_range
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "${var.name_prefix}-ip-range-pods"
    ip_cidr_range = var.pod_ip_range
  }
  secondary_ip_range {
    range_name    = "${var.name_prefix}-ip-range-services"
    ip_cidr_range = var.services_ip_range
  }
}

# Secondary Subnet - Resereved for cloud functions
resource "google_compute_subnetwork" "cloud_function_subnet" {
  name                     = "${var.name_prefix}-cloud-function-subnet"
  region                   = var.gcp_functions_region
  network                  = google_compute_network.default.name
  ip_cidr_range            = var.function_ip_cidr_range
  private_ip_google_access = true
}

resource "google_compute_global_address" "private_ip_address" {
  project = var.gcp_project

  name          = "${var.name_prefix}-cloud-sql-private-ip-address-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = google_compute_network.default.id
  address       = var.ip_cidr_range_sql
}

resource "google_compute_global_address" "private_ip_address_redis" {
  project = var.gcp_project

  name          = "${var.name_prefix}-cloud-redis-private-ip-address-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = google_compute_network.default.id
  address       = var.ip_cidr_range_redis
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.default.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name, google_compute_global_address.private_ip_address_redis.name]
}

resource "google_compute_router" "vpc_router" {
  name    = "${var.name_prefix}-vpc-router"
  network = google_compute_network.default.self_link
  region  = google_compute_subnetwork.default.region
}

resource "google_compute_router" "vpc_router_cloudfunctions" {
  name    = "${var.name_prefix}-vpc-router-cloudfunctions"
  network = google_compute_network.default.self_link
  region  = google_compute_subnetwork.cloud_function_subnet.region
}

resource "google_compute_address" "nat_outbound_ip" {
  name   = "${var.name_prefix}-nat-outbound-ip"
  region = google_compute_subnetwork.default.region
}

resource "google_compute_address" "nat_outbound_ip_cloudfunction" {
  name   = "${var.name_prefix}-nat-outbound-ip-cloudfunctions"
  region = google_compute_subnetwork.cloud_function_subnet.region
}

resource "google_compute_router_nat" "vpc_router_nat" {
  name                   = "${var.name_prefix}-vpc-router-nat"
  router                 = google_compute_router.vpc_router.name
  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.nat_outbound_ip.self_link]

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.default.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  lifecycle {
    ignore_changes = [
      log_config,
      min_ports_per_vm
    ]
  }
}

resource "google_compute_router_nat" "vpc_router_nat_cloudfunction" {
  name                   = "${var.name_prefix}-vpc-router-nat-cloudfunctions"
  router                 = google_compute_router.vpc_router_cloudfunctions.name
  nat_ip_allocate_option = "MANUAL_ONLY"
  min_ports_per_vm       = "4096"
  nat_ips                = [google_compute_address.nat_outbound_ip_cloudfunction.self_link]
  region                 = google_compute_subnetwork.cloud_function_subnet.region

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.cloud_function_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }


  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  lifecycle {
    ignore_changes = [
      min_ports_per_vm
    ]
  }
}

resource "google_compute_firewall" "iap_ssh_whitelist" {
  name    = "${var.name_prefix}-iap-ssh-whitelist"
  network = google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["10.0.0.0/16"]

  description = "Allow SSH connections from GCP's IAP"
}