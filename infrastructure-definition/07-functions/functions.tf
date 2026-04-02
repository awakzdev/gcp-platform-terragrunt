locals {
  fqdn = "${var.name_prefix}.${var.base_domain}"

  function_files = fileset("${path.module}", "*.json")
  functions = { for file in local.function_files :
    trimsuffix(basename(file), ".json") =>
    jsondecode(file("${path.module}/${file}"))
  }

  http_trigger_functions_list = [for k, v in local.functions : k if lookup(v, "httpsTrigger", false) != false]
}

data "google_vpc_access_connector" "serverless_vpc" {
  name   = "${var.name_prefix}-vpc-connector"
  region = var.gcp_functions_region
}

resource "google_storage_bucket" "function_bucket" {
  name     = "${var.name_prefix}-catalog-sync-cloud-functions"
  location = var.function_storage_location
}

resource "google_storage_bucket_object" "bootstrap_nodejs_function" {
  name   = "bootstrap_nodejs_function.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = "./bootstrap_nodejs_function.zip"
}

resource "google_storage_bucket_object" "bootstrap_python_function" {
  name   = "bootstrap_python_function.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = "./bootstrap_python_function.zip"

  lifecycle {
    ignore_changes = [detect_md5hash]
  }
}

resource "google_cloudfunctions_function" "application_functions" {
  for_each = local.functions

  project     = var.gcp_project
  region      = var.gcp_functions_region
  name        = "${var.name_prefix}-${each.key}"
  description = "${each.key} Cloud Function"
  # runtime     = "nodejs16"     ## FIXME - need to get this from function json
  entry_point = "hello_http" ## FIXME - need to get this from function json

  vpc_connector                 = data.google_vpc_access_connector.serverless_vpc.id
  vpc_connector_egress_settings = "ALL_TRAFFIC"
  source_archive_bucket         = google_storage_bucket.function_bucket.name
  source_archive_object = var.bootstrap_function_object[
    each.value.runtime == "nodejs18" ? "nodejs18" :
    each.value.runtime == "nodejs20" ? "nodejs18" :
    each.value.runtime
  ]
  available_memory_mb           = each.value.availableMemoryMb
  timeout                       = each.value.timeout
  max_instances                 = 3000 # This prevents the instance from modification due to a bug
  min_instances                 = 0
  docker_registry               = "ARTIFACT_REGISTRY"

  // PRODUCTION ONLY
  runtime = each.value.runtime == "nodejs18" ? "nodejs20" : each.value.runtime
  # entry_point = each.value.entrypoint

  // Cloud Functions with secret must contains IAM permissions 'roles/secretmanager.secretAccessor' otherwise your function will fail.
  // Cloud Functions with event_trigger = 'Bucket' must contain additional permissions.
  // To view a list of required permissions / troubleshooting visit - https://cloud.google.com/functions/docs/troubleshooting#cloud-console_5
  service_account_email        = google_service_account.cloud_functions_sa.email
  https_trigger_security_level = lookup(each.value, "httpsTrigger", {}) == {} ? null : "SECURE_ALWAYS"
  trigger_http                 = lookup(each.value, "httpsTrigger", {}) == {} ? null : true

  dynamic "event_trigger" {
    for_each = contains(keys(each.value), "eventTrigger") ? [1] : []
    content {
      event_type = each.value.eventTrigger.eventType
      resource   = each.value.eventTrigger.eventType == "providers/cloud.pubsub/eventTypes/topic.publish" ? "projects/${var.gcp_project}/topics/${var.name_prefix}-${each.value.eventTrigger.resource}" : false || each.value.eventTrigger.eventType == "google.storage.object.finalize" ? "projects/${var.gcp_project}/buckets/${each.value.eventTrigger.resource}" : false

      dynamic "failure_policy" {
        for_each = contains(keys(each.value.eventTrigger), "failurePolicy") ? [1] : []
        content {
          retry = each.value.eventTrigger.failurePolicy.retry
        }
      }
    }
  }

  # Environment Variables
  environment_variables = lookup(each.value, "environmentVariables", null) != null ? {
    for key, value in each.value.environmentVariables :
    key => value
  } : null

  # Build Environment Variables
  build_environment_variables = lookup(each.value, "buildEnvironmentVariables", null) != null ? {
    for key, value in each.value.buildEnvironmentVariables :
    key => value
  } : null

  # Secrets Exposed as an environment variable
  dynamic "secret_environment_variables" {
    for_each = lookup(each.value, "secrets", []) != [] ? lookup(each.value.secrets, "secretEnvironmentVariables", []) : []
    content {
      key        = secret_environment_variables.value.key
      project_id = secret_environment_variables.value.projectId
      secret     = "${upper(var.name_prefix)}_${upper(secret_environment_variables.value.secret)}"
      version    = secret_environment_variables.value.version
    }
  }

  # Secrets Mounted as a volume
  dynamic "secret_volumes" {
    for_each = lookup(each.value, "secrets", []) != [] ? lookup(each.value.secrets, "secretVolumes", []) : []
    content {
      mount_path = secret_volumes.value.mountPath
      secret     = "${upper(var.name_prefix)}_${upper(secret_volumes.value.secret)}"
      project_id = secret_volumes.value.projectId

      dynamic "versions" {
        for_each = secret_volumes.value.versions
        content {
          path    = versions.value.path
          version = versions.value.version
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      entry_point, source_archive_bucket, source_archive_object, labels, event_trigger[0].event_type # runtime
    ]
  }
  depends_on = [google_storage_bucket_object.bootstrap_nodejs_function, google_storage_bucket_object.bootstrap_python_function]

  # Setting timeouts for resources
  # Default is 5 but terraform might time out before creation / update is complete.
  timeouts {
    create = "10m"
    update = "10m"
  }
}

# IAM entry for all users to invoke the function
resource "google_cloudfunctions_function_iam_member" "application_functions_invoker" {
  for_each = local.functions

  project        = google_cloudfunctions_function.application_functions[each.key].project
  region         = google_cloudfunctions_function.application_functions[each.key].region
  cloud_function = google_cloudfunctions_function.application_functions[each.key].name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

data "template_file" "functions_configmap" {
  template = file("functions_configmap.yaml.tpl")
  vars = {
    gcp_project          = var.gcp_project
    gcp_functions_region = var.gcp_functions_region
    name_prefix          = var.name_prefix
    function_domain      = "actions.${local.fqdn}"
    # func_url_list = [for function in local.http_trigger_functions_list : "https://actions.${local.fqdn}/${function}"]

  }
}