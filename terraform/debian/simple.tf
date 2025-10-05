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
  description = "GCP Project ID"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

# Get the specific image created by Packer
data "google_compute_image" "apache" {
  name    = "apache-simple-sumitk"
  project = var.project_id
}

# Create firewall rule
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# Create instance
resource "google_compute_instance" "apache" {
  name         = "apache-instance"
  machine_type = "e2-small"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.apache.self_link
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }

  tags = ["http-server"]

  metadata = {
    enable-oslogin = "TRUE"
  }
}

output "instance_ip" {
  value = google_compute_instance.apache.network_interface[0].access_config[0].nat_ip
}

output "instance_url" {
  value = "http://${google_compute_instance.apache.network_interface[0].access_config[0].nat_ip}"
}
      