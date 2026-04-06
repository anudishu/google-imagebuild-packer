# Random reads — no resources created. Handy for outputs and copy-paste into tickets.

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

# default compute SA email pattern — we don’t always attach it but good to print in outputs sometimes
locals {
  project_number           = data.google_project.this.number
  default_compute_sa_email = "${data.google_project.this.number}-compute@developer.gserviceaccount.com"
}

output "project_number" {
  description = "numeric project id — shows up in default SA email and sink names"
  value       = local.project_number
}

output "default_network_self_link" {
  description = "default vpc self link (we’re lazy and use default network in the demo)"
  value       = data.google_compute_network.default.self_link
}

output "available_zones_in_region" {
  description = "zones that are UP in this region — paste into docs when someone asks capacity questions"
  value       = data.google_compute_zones.available_in_region.names
}

output "gcp_region_in_use" {
  description = "region parsed out of the zone variable"
  value       = local.region
}
