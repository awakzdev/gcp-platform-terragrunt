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

# data "http" "myip" {
#   url = "http://ipv4.icanhazip.com"
# }
#  "${chomp(data.http.myip.body)}/32"

# resource "google_compute_instance" "mgmt_vm" {
#   name         = "${var.name_prefix}-mgmt-vm"
#   machine_type = "e2-medium"
#   zone         = var.gcp_availability_zone

#   tags = ["mgmt"]

#   boot_disk {
#     initialize_params {
#       image = "ubuntu-os-cloud/ubuntu-2204-lts"
#       labels = {
#         application = "mgmt"
#       }
#     }
#   }

#   network_interface {
#     network    = data.google_compute_network.default.name
#     subnetwork = data.google_compute_subnetwork.default.name
#     access_config {
#     }
#   }

#   service_account {
#     # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
#     email  = google_service_account.mgmt_vm_sa.email
#     scopes = ["cloud-platform"]
#   }

#   lifecycle {
#     ignore_changes = [
#       metadata["ssh-keys"],
#     ]
#   }
# }