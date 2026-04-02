output "buckets_configmap" {
  value = data.template_file.buckets_configmap.rendered
}
