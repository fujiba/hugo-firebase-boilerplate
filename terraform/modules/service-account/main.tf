
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_service_account" "service_account" {
  project      = var.project_id
  account_id   = "deploy"
  display_name = "Deploy user"
}

resource "google_project_iam_member" "service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "apikeys_viewer" {
  project = var.project_id
  role    = "roles/serviceusage.apiKeysViewer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "firebaserules_system" {
  project = var.project_id
  role    = "roles/firebaserules.system"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "firebasehosting_admin" {
  project = var.project_id
  role    = "roles/firebasehosting.admin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "cloudfunctions_developer" {
  count = var.enable_functions ? 1 : 0
  project = var.project_id
  role    = "roles/cloudfunctions.developer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "secretmanager_viewer" {
  count = var.enable_functions ? 1 : 0
  project = var.project_id
  role    = "roles/secretmanager.viewer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_service_account_key" "deployuser-key" {
  service_account_id = google_service_account.service_account.name
}

resource "local_file" "deployuser-key" {
  filename             = "./output/secrets/deployuser-key"
  content              = google_service_account_key.deployuser-key.private_key
  file_permission      = "0600"
  directory_permission = "0755"
}
