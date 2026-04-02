#data "gitlab_project" "cluster_infra" {
#  path_with_namespace = "mycompany/iac/cluster-infra"
#}
#
#resource "gitlab_repository_file" "pubsub_values" {
#  project        = data.gitlab_project.cluster_infra.id
#  file_path      = "environments/apple/mycompany/pubsub-values.yaml"
#  branch         = "dev"
#  content        = base64encode(data.template_file.pubsub_configmap.rendered)
#  author_email   = "user@example.com"
#  author_name    = "gitlab-service-bot"
#  commit_message = "Terraform update: ${var.name_prefix} environment pubsub topics updated"
#}
