terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
    }
  }
}

resource "google_firebase_web_app" "default" {
  provider     = google-beta
  project      = var.project_id
  display_name = var.display_name
}

resource "google_firebase_hosting_site" "full" {
  count    = var.use_dev ? 1 : 0
  provider = google-beta
  project  = var.project_id
  site_id  = "dev-${var.project_id}"
  app_id   = google_firebase_web_app.default.app_id
}
