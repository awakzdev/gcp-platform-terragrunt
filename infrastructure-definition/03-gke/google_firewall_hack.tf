# Ugly hack to enable port 8443 in gcloud firewall rule for GKE master nodes, to allow admission webhook on non-default ports such as nginx-ingress to work.
# More documentation can be found here - https://kubernetes.github.io/ingress-nginx/deploy/#gce-gke
# And here - https://github.com/kubernetes/kubernetes/issues/79739
# And here - https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters#add_firewall_rules

resource "null_resource" "fix_firewall_config" {
  provisioner "local-exec" {
    command = "gcloud compute firewall-rules update $(gcloud compute firewall-rules list --project=${var.gcp_project} --filter='name ~ gke-${var.name_prefix}-gke-cluster AND name ~ master' --format='value(name)') --project=${var.gcp_project} --allow tcp:10250,tcp:443,tcp:8443"
  }

  depends_on = [google_container_cluster.primary]
}
