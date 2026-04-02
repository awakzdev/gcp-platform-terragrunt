# GKE ACCOUNTS WORKLOAD IDENTITY USER ROLE BINDING
resource "google_project_iam_member" "external_dns_gke_sa_bind" {
  for_each = toset([
    "external-dns/external-dns",
    "external-secrets/external-secrets",
    "cnrm-system/cnrm-controller-manager-mycompany",
    "gitlab-runner/gitlab-runner",
    "cert-manager/cert-manager",
    "argocd/argocd-dex-server",
    "nginx-ingress/oauth2-proxy",
    "mycompany/${var.name_prefix}-backend",
    "mycompany/${var.name_prefix}-ui",
  ])

  project    = var.gcp_project
  role       = "roles/iam.workloadIdentityUser"
  member     = "serviceAccount:${var.gcp_project}.svc.id.goog[${each.value}]"
  depends_on = [google_container_cluster.primary]
}
