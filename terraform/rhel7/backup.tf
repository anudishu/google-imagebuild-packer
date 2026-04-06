# optional boot disk snapshots — default off

variable "enable_disk_snapshot_schedule" {
  description = "true = attach snapshot schedule to rhel7 boot disk"
  type        = bool
  default     = false
}

variable "snapshot_retention_days" {
  description = "auto snapshot retention window"
  type        = number
  default     = 7
}

resource "google_compute_resource_policy" "rhel7_disk_snapshots" {
  count   = var.enable_disk_snapshot_schedule ? 1 : 0
  name    = "${local.name_prefix}-disk-snapshots"
  project = var.project_id
  region  = local.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "04:15"
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

resource "google_compute_disk_resource_policy_attachment" "rhel7_boot_disk" {
  count = var.enable_disk_snapshot_schedule ? 1 : 0
  name  = google_compute_resource_policy.rhel7_disk_snapshots[0].name
  disk  = google_compute_instance.rhel7_httpd.boot_disk[0].device_name
  zone  = var.zone
}
