# Test VM from rhel7 packer image (name in data source = packer image_name).

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  zone    = var.zone
}

variable "project_id" {
  description = "gcp project"
  type        = string
}

variable "zone" {
  description = "zone for the vm"
  type        = string
  default     = "us-central1-a"
}

data "google_compute_image" "rhel7_httpd" {
  name    = "rhel7-httpd-golden"
  project = var.project_id
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-rhel7-httpd"
  network = "default"
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server-rhel7"]
}

resource "google_compute_instance" "rhel7_httpd" {
  name         = "rhel7-httpd-instance"
  machine_type = "e2-small"
  zone         = var.zone

  boot_disk {
    device_name = "rhel7-httpd-boot-disk"
    initialize_params {
      image = data.google_compute_image.rhel7_httpd.self_link
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }

  tags   = ["http-server-rhel7"]
  labels = local.standard_labels

  service_account {
    email = google_service_account.rhel7_vm.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/logging.write",
    ]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }
}

output "rhel7_instance_ip" {
  value = google_compute_instance.rhel7_httpd.network_interface[0].access_config[0].nat_ip
}

output "rhel7_instance_url" {
  value = "http://${google_compute_instance.rhel7_httpd.network_interface[0].access_config[0].nat_ip}"
}
