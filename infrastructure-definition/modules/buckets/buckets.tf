# CDN Bucket
resource "google_storage_bucket" "bucket" {
  name          = var.bucket
  location      = "EU"
  storage_class = "STANDARD"
  force_destroy = true


  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  cors {
    origin = local.all_cors
    method = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    response_header = [
      "Content-Type",
      "Authorization",
      "Content-Length",
      "User-Agent",
      "x-goog-resumable",
      "Access-Control-Allow-Origin"
    ]
    max_age_seconds = 3600
  }
}

# Generate permissions to view CDN content
resource "google_storage_bucket_iam_binding" "public_viewer_for_cdn_permission" {

  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectViewer"

  members = [
    "allUsers"
  ]
}

# Creating a backend bucket
resource "google_compute_backend_bucket" "backend_bucket" {
  name        = google_storage_bucket.bucket.name
  description = "Enabling CDN for ${var.bucket} bucket"
  bucket_name = google_storage_bucket.bucket.name
  enable_cdn  = true
}

