provider "google-beta" {
  user_project_override = true
  region                = "asia-northeast1"
}

provider "google-beta" {
  alias                 = "no_user_project_override"
  user_project_override = false
}
