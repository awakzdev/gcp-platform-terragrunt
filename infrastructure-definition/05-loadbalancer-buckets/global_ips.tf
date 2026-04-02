# Global addresses for GKE Ingress load balancers
resource "google_compute_global_address" "ingress" {
  name = "${var.name_prefix}-ingress-lb-address"
}

#resource "google_compute_global_address" "ui" {
#  name = "${var.name_prefix}-ui-lb-address"
#}

# resource "google_compute_global_address" "api" {
#   name = "${var.name_prefix}-backend-lb-address"
# }

# resource "google_compute_global_address" "gateway" {
#   name = "${var.name_prefix}-gateway-lb-address"
# }

# resource "google_compute_global_address" "argocd" {
#   name = "${var.name_prefix}-argocd-lb-address"
# }
