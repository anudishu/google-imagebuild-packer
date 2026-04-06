# Disk snapshot schedule — default off because it costs money and our lab didn’t need it.
# Flip enable_disk_snapshot_schedule when you actually want daily snaps of the boot disk.

variable "enable_disk_snapshot_schedule" {
  description = "true = create schedule + attach to apache boot disk"
  type        = bool
  default     = false
}

variable "snapshot_retention_days" {
  description = "how long GCP keeps auto snapshots — 7 is fine for dev, prod people pick bigger numbers"
  type        = number
  default     = 7
}

resource "google_compute_resource_policy" "apache_disk_snapshots" {
  count   = var.enable_disk_snapshot_schedule ? 1 : 0
  name    = "${local.name_prefix}-disk-snapshots"
  project = var.project_id
  region  = local.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "04:00" # quiet hours US-ish — change if your team is elsewhere
      }
    }

    retention_policy {
      max_retention_days    = var.snapshot_retention_days
      on_source_disk_delete = "KEEP_AUTO_GENERATED_SNAPSHOTS"
    }

    snapshot_properties {
      labels = local.standard_labels
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "apache_boot_disk" {
  count = var.enable_disk_snapshot_schedule ? 1 : 0
  name  = google_compute_resource_policy.apache_disk_snapshots[0].name
  disk  = google_compute_instance.apache.boot_disk[0].device_name
  zone  = var.zone
}
