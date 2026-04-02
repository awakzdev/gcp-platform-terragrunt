### CDN BUCKETS ###

# Create buckets with permissions / CDN ready
module "cdn_buckets" {
  source   = "../modules/buckets"
  for_each = local.cdn_buckets

  bucket      = each.key
  name_prefix = var.name_prefix
}

# # Upload an image to each bucket under never-fetch/three-cats.jpg
# resource "null_resource" "upload_image" {
#   provisioner "local-exec" {
#     command = "gsutil cp gs://gcp-external-http-lb-with-bucket/three-cats.jpg gs://${each.key}/never-fetch/"
#   }

#   for_each = var.bucket_upload == true ? local.cdn_buckets : {}
# }

# Forces buckets to become public
resource "google_storage_bucket_iam_binding" "public_read" {
  for_each = zipmap(local.public_buckets, local.public_buckets)

  bucket = "${var.name_prefix}-${each.key}"
  role   = "roles/storage.objectViewer"

  members = [
    "allUsers",
  ]
}

# Backups bucket
resource "google_storage_bucket" "carwiz_bq_backups" {
  name          = "${var.name_prefix}-mycompany-bq-backups"
  location      = "EU"
  storage_class = "COLDLINE"
  force_destroy = true

  uniform_bucket_level_access = false       # false by default
  public_access_prevention    = "inherited" # enforced / inherited

  lifecycle_rule {
    condition {
      age = 3
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }
}

# Catalog bucket
resource "google_storage_bucket" "catalog" {
  name          = "${var.name_prefix}-carwiz_catalog"
  location      = "EU"
  storage_class = "STANDARD"
  force_destroy = true

  uniform_bucket_level_access = true        # false by default
  public_access_prevention    = "inherited" # enforced / inherited
}

# Secure store bucket
resource "google_storage_bucket" "secured" {
  name          = "${var.name_prefix}-carwiz_secured"
  location      = "EU"
  storage_class = "STANDARD"
  force_destroy = true

  uniform_bucket_level_access = false      # false by default
  public_access_prevention    = "enforced" # enforced / inherited

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      with_state         = "ARCHIVED"
      num_newer_versions = 1
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      days_since_noncurrent_time = 7
    }
    action {
      type = "Delete"
    }
  }
}

# Smthn bucket
resource "google_storage_bucket" "carwiz_co_il" {
  name          = "${var.name_prefix}-mycompany-co-il"
  location      = "EU"
  storage_class = "STANDARD"
  force_destroy = true

  uniform_bucket_level_access = false # default - false
  public_access_prevention    = "inherited"
}

data "template_file" "buckets_configmap" {
  template = file("buckets_configmap.yaml.tpl")
  vars = {
    gcp_project = var.gcp_project
    name_prefix = var.name_prefix
  }
}
