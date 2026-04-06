# project + network lookups

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
  region  = local.region
  status  = "UP"
}

locals {
  project_number           = data.google_project.this.number
  default_compute_sa_email = "${data.google_project.this.number}-compute@developer.gserviceaccount.com"
}

output "centos7_project_number" {
  description = "numeric project id"
  value       = local.project_number
}

output "centos7_default_network_self_link" {
  description = "default vpc self link"
  value       = data.google_compute_network.default.self_link
}

output "centos7_available_zones_in_region" {
  description = "zones UP in derived region"
  value       = data.google_compute_zones.available_in_region.names
}

output "centos7_gcp_region_in_use" {
  description = "region parsed from zone"
  value       = local.region
}
