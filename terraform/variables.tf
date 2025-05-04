variable "project_id_prefix" {
  type        = string
  description = "Prefix for the Google Cloud project ID. A random suffix will be appended."
}

variable "project_name" {
  type        = string
  description = "The human-readable name for the Google Cloud project (4-30 chars)."
}

variable "billing_account" {
  type        = string
  description = "The ID of the billing account to associate the project with. Leave empty if not required."
}

variable "enable_dev_environment" {
  type        = bool
  description = "Set to true to create the development hosting site and enable related features (e.g., Cloud Functions for Basic Auth)."
  default     = false # Or read from config.yaml in init script
}