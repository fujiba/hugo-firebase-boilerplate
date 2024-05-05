terraform {
  required_providers {
    google-beta = {
      source                = "hashicorp/google-beta"
      configuration_aliases = [google-beta, google-beta.no_user_project_override]
      version               = "~> 4.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

module "project" {
  source          = "../../modules/firebase-project"
  project_id      = var.project_id
  project_name    = var.project_name
  billing_account = var.billing_account
  providers = {
    google-beta                          = google-beta
    google-beta.no_user_project_override = google-beta.no_user_project_override
  }
}

module "hosting" {
  source       = "../../modules/firebase-hosting"
  project_id   = var.project_id
  use_dev      = false
  display_name = "${var.project_id} development site"
  providers = {
    google-beta = google-beta
  }
  depends_on = [module.project]
}

module "service_account" {
  source     = "../../modules/service-account"
  project_id = var.project_id
  enable_functions = false
  providers = {
    google = google
  }
}
