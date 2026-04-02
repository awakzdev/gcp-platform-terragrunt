# ###########################################
# ##
# ## Creating Pub/Sub topics from locals.tf
# ##
# ###########################################

locals {
  pubsub_topics = jsondecode(file("${path.module}/pubsub_topics.json"))
}

resource "google_pubsub_topic" "pub_sub" {
  for_each = toset(local.pubsub_topics)

  # If a var.name_prefix is added to the name field in the following fashion: "${var.name_prefix}-${each.key}" 
  # Please edit the 'event_type.resource' field in functions.tf to include var.name_prefix aswell.
  # "project/${var.gcp_project}/topics/${each.value.eventTrigger.resource}" > "project/${var.gcp_project}/topics/${var.name_prefix}-${each.value.eventTrigger.resource}"

  name = "${var.name_prefix}-${each.key}"

  labels = {
    topic       = each.key
    environment = var.name_prefix
  }

  message_retention_duration = "86600s"
}

data "template_file" "pubsub_configmap" {
  template = file("pubsub_configmap.yaml.tpl")
  vars = {
    gcp_project = var.gcp_project
    name_prefix = var.name_prefix
  }
}