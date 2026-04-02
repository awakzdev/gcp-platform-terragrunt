output "pubsub_configmap" {
  value = data.template_file.pubsub_configmap.rendered
}
