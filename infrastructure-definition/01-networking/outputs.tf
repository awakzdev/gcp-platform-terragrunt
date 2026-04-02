output "vpc_gke_egress_ip" {
  description = "The egress ip used for GKE applications egress"
  value       = google_compute_address.nat_outbound_ip.address
}

output "vpc_functions_egress_ip" {
  description = "The egress ip used for cloud functions egress"
  value       = google_compute_address.nat_outbound_ip_cloudfunction.address
}