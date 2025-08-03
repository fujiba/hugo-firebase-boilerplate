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

# Development Firebase Web App (conditional)
resource "google_firebase_web_app" "dev" {
  count        = var.use_dev ? 1 : 0
  provider     = google-beta
  project      = var.project_id
  display_name = "${var.display_name} Dev" # Or a more specific name like "Dev Web App"
}

# Default/Production Hosting Site
# This site will use the project_id as its site_id by default,
# which is typical for the primary hosting site.
resource "google_firebase_hosting_site" "default" {
  provider = google-beta
  project  = var.project_id
  site_id  = var.project_id # Assumes you want the default site ID to be your project ID
  app_id   = google_firebase_web_app.default.app_id
}

# Development Hosting Site (conditional)
resource "google_firebase_hosting_site" "dev" {
  count    = var.use_dev ? 1 : 0
  provider = google-beta
  project  = var.project_id
  site_id  = "dev-${var.project_id}"
  app_id   = google_firebase_web_app.dev[0].app_id
}
