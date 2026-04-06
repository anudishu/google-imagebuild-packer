# Read-only junk for the windows stack — mirrors debian file so both roots feel similar.

data "google_client_config" "current" {}

data "google_project" "this" {
  project_id = var.project_id
}

data "google_compute_network" "default" {
  name    = "default"
  project = var.project_id
}

data "google_compute_zones" "available_in_region" {
  project = var.project_id
  region  = var.region
  status  = "UP"
}

locals {
  project_number           = data.google_project.this.number
  default_compute_sa_email = "${data.google_project.this.number}-compute@developer.gserviceaccount.com"
}

output "windows_project_number" {
  description = "project number for this windows workload"
  value       = local.project_number
}

output "windows_default_network_self_link" {
  description = "default vpc — yeah we still use default in the sample, swap for shared vpc later"
  value       = data.google_compute_network.default.self_link
}

output "windows_available_zones" {
  description = "UP zones in var.region"
  value       = data.google_compute_zones.available_in_region.names
}

output "windows_image_self_link" {
  description = "resolved image from the data source in windows.tf"
  value       = data.google_compute_image.windows.self_link
}
