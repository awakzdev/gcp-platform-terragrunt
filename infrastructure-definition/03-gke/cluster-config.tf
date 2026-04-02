# resource "helm_release" "argocd" {
#   name       = "cluster-argo-cd"
#   repository = "https://argoproj.github.io/argo-helm"
#   chart      = "argo-cd"
#   create_namespace = true
#   namespace = "argocd"
#   version = "5.43.4"
#   values = [
#     templatefile("${path.module}/argocd-values.yaml", {name_prefix = var.name_prefix, oauth_client_id = var.oauth_client_id, oauth_client_secret = var.oauth_client_secret})
#   ]
# }

# resource "helm_release" "cluster_infra" {
#   name       = "cluster-infra"
#   repository = "https://argoproj.github.io/argo-helm"
#   chart      = "argo-cd"
#   create_namespace = true
#   namespace = "argocd"
#   version = "5.43.4"
#   values = [
#     templatefile("${path.module}/argocd-values.yaml", {name_prefix = var.name_prefix, oauth_client_id = var.oauth_client_id, oauth_client_secret = var.oauth_client_secret})
#   ]
# }