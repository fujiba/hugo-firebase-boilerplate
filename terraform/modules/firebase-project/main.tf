terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.0"
    }
  }
}

resource "google_project" "default" {
  provider = google-beta.no_user_project_override

  project_id      = var.project_id
  name            = var.project_name
  billing_account = var.billing_account

  labels = {
    "firebase" = "enabled"
  }
}

locals {
  services4hostingonly = [
    "cloudresourcemanager.googleapis.com",
    "firebase.googleapis.com",
    # Enabling the ServiceUsage API allows the new project to be quota checked from now on.
    "serviceusage.googleapis.com",
  ]
  services4withfunctions = [
    "cloudbilling.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "firebase.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    # Enabling the ServiceUsage API allows the new project to be quota checked from now on.
    "serviceusage.googleapis.com",
  ]
}

resource "google_project_service" "default" {
  provider = google-beta.no_user_project_override
  project  = google_project.default.project_id
  for_each = toset(var.billing_account == "" ? local.services4hostingonly : local.services4withfunctions)
  service = each.key

  # Don't disable the service if the resource block is removed by accident.
  disable_on_destroy = false

  depends_on = [time_sleep.wait_60_seconds]
}

resource "google_firebase_project" "default" {
  provider = google-beta
  project  = google_project.default.project_id

  depends_on = [
    google_project_service.default,
  ]
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [google_project.default]

  create_duration = "60s"
}
