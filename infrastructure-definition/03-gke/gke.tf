##################################################################################
##
## GKE Cluster and nodes, gke nodes service accounts and permissions
##
##################################################################################

data "google_compute_network" "default" {
  name = "${var.name_prefix}-vpc"
}

data "google_compute_subnetwork" "default" {
  name   = "${var.name_prefix}-main-subnet"
  region = var.gcp_region
}

# Reserved for Workload identity namespace (IAM)
data "google_project" "project" {
}

data "google_container_engine_versions" "gke_version" {
  location = var.gcp_availability_zone
}

locals {
  sa_permissions = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/secretmanager.admin",
    "roles/iam.serviceAccountAdmin"
  ]
}

# Granting various roles for GKE default SA
resource "google_project_iam_member" "project" {
  for_each = toset(local.sa_permissions)

  project = var.gcp_project
  role    = each.key

  member = google_service_account.default.member
}

# GKE nodes service account
# Additional permissions through the policy above.

resource "google_service_account" "default" {
  account_id   = "${var.name_prefix}-gke-sa"
  display_name = "Kubernetes nodes default Service Account"
}

# Kubernetes engine
resource "google_container_cluster" "primary" {
  provider = google-beta
  project  = var.gcp_project
  name     = "${var.name_prefix}-gke-cluster"
  location = var.gcp_availability_zone

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  maintenance_policy {
    recurring_window {
      start_time = "1970-01-01T22:00:00Z" # RFC3339; date is ignored, time matters
      end_time   = "1970-01-02T02:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU"
    }
  }

  # Configures workload identity
  workload_identity_config {
    workload_pool = "${data.google_project.project.project_id}.svc.id.goog"
  }

  gateway_api_config {
    channel = "CHANNEL_DISABLED"
  }

  # The settings below are copied from mycompany's Kubernetes environment.
  enable_shielded_nodes = false
  networking_mode       = "VPC_NATIVE"
  # Swap below resources to data sources
  network    = data.google_compute_network.default.self_link
  subnetwork = data.google_compute_subnetwork.default.self_link

  private_cluster_config {
    enable_private_nodes   = true
    master_ipv4_cidr_block = "10.0.0.0/16"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "${var.name_prefix}-ip-range-pods"
    services_secondary_range_name = "${var.name_prefix}-ip-range-services"
  }

  release_channel {
    channel = "REGULAR"
  }
  # min_master_version = data.google_container_engine_versions.gke_version.release_channel_latest_version["REGULAR"]

  master_auth {
    client_certificate_config {
      issue_client_certificate = true
    }
  }

  addons_config {
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    config_connector_config {
      enabled = true
    }
  }

  #   lifecycle {
  #   ignore_changes = [
  #     min_master_version
  #   ]
  # }
}

# Kubernetes nodes
resource "google_container_node_pool" "application_nodes" {
  name               = "${var.name_prefix}-application-node-pool"
  location           = var.gcp_availability_zone
  cluster            = google_container_cluster.primary.name
  initial_node_count = 4

  autoscaling {
    min_node_count = 0
    max_node_count = 8
  }

  network_config {
    enable_private_nodes = true # Whether nodes should have an internal IP addresses only
    pod_range            = "${var.name_prefix}-ip-range-pods"
  }

  node_config {
    preemptible  = false
    machine_type = "e2-standard-2"
    disk_type    = "pd-ssd"
    disk_size_gb = 30

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = {
      workload = "application"
    }

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  lifecycle {
    ignore_changes = [
      initial_node_count,
      autoscaling["max_node_conut"],
      # node_config
    ]
  }
}

resource "google_container_node_pool" "build_pool" {
  name               = "${var.name_prefix}-build-node-pool"
  location           = var.gcp_availability_zone
  cluster            = google_container_cluster.primary.name
  initial_node_count = var.build_pool_initial_node_count

  network_config {
    enable_private_nodes = true # Whether nodes should have an internal IP addresses only
    pod_range            = "${var.name_prefix}-ip-range-pods"
  }
  autoscaling {
    min_node_count = 0
    max_node_count = 2
  }
  node_config {
    machine_type = "e2-standard-4"
    disk_type    = "pd-ssd"
    disk_size_gb = 30

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    labels = {
      workload = "builder"
    }
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  lifecycle {
    ignore_changes = [
      initial_node_count,
      autoscaling["max_node_conut"],
    ]
  }
}

resource "google_container_node_pool" "infra_node_pool" {
  name       = "${var.name_prefix}-infra-node-pool"
  location   = var.gcp_availability_zone
  cluster    = google_container_cluster.primary.name
  node_count = 3

  network_config {
    enable_private_nodes = true # Whether nodes should have an internal IP addresses only
    pod_range            = "${var.name_prefix}-ip-range-pods"
  }

  node_config {
    preemptible  = true
    machine_type = "e2-medium"
    disk_type    = "pd-ssd"
    disk_size_gb = 30

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = {
      workload = "infra"
    }

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}
