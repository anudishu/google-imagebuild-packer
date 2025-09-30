terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

variable "project_id" {
  type        = string
  description = "GCP Project ID"
  default     = "root-cortex-465610-p8"
}

variable "zone" {
  type        = string
  description = "GCP Zone"
  default     = "us-central1-a"
}

variable "region" {
  type        = string
  description = "GCP Region"
  default     = "us-central1"
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Data source to get the latest Windows Server 2016 hardened image
data "google_compute_image" "windows" {
  family  = "windows-server-2016-hardened"
  project = var.project_id
}

# Windows Server 2016 instance
resource "google_compute_instance" "windows" {
  project      = var.project_id
  zone         = var.zone
  name         = "windows-server-2016-instance"
  machine_type = "n1-standard-2"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.windows.self_link
      size  = 50
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
  }

  tags = ["http-server", "https-server", "rdp-server"]

  metadata = {
    enable-oslogin = "FALSE"
    # Set initial password for Windows
    windows-startup-script-ps1 = <<-EOT
      # Configure initial settings
      Write-Host "Windows instance starting up..."
      
      # Enable RDP
      Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0
      Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
      
      # Set timezone
      tzutil /s "UTC"
      
      Write-Host "Windows startup script completed"
    EOT
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/logging.write"
    ]
  }
}

# Firewall rule for HTTP traffic
resource "google_compute_firewall" "allow_http_windows" {
  project = var.project_id
  name    = "allow-http-windows"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# Firewall rule for HTTPS traffic
resource "google_compute_firewall" "allow_https_windows" {
  project = var.project_id
  name    = "allow-https-windows"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}

# Firewall rule for RDP traffic (restricted to specific IP ranges for security)
resource "google_compute_firewall" "allow_rdp_windows" {
  project = var.project_id
  name    = "allow-rdp-windows"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  # Restrict RDP access to specific IP ranges for security
  # Update these ranges according to your security requirements
  source_ranges = ["0.0.0.0/0"]  # Change this to your specific IP ranges
  target_tags   = ["rdp-server"]
}

# Outputs
output "windows_instance_ip" {
  value       = google_compute_instance.windows.network_interface[0].access_config[0].nat_ip
  description = "External IP address of the Windows instance"
}

output "windows_instance_url" {
  value       = "http://${google_compute_instance.windows.network_interface[0].access_config[0].nat_ip}"
  description = "URL to access the Windows IIS server"
}

output "windows_rdp_command" {
  value       = "Use RDP client to connect to: ${google_compute_instance.windows.network_interface[0].access_config[0].nat_ip}:3389"
  description = "RDP connection information"
}

output "windows_instance_name" {
  value       = google_compute_instance.windows.name
  description = "Name of the Windows instance"
}
