# Optional boot disk snapshots for the windows demo vm — off by default.

variable "windows_enable_disk_snapshot_schedule" {
  description = "true = attach snapshot schedule to C: disk via api"
  type        = bool
  default     = false
}

variable "windows_snapshot_retention_days" {
  description = "retention on auto snaps"
  type        = number
  default     = 7
}

resource "google_compute_resource_policy" "windows_disk_snapshots" {
  count   = var.windows_enable_disk_snapshot_schedule ? 1 : 0
  name    = "${local.name_prefix}-disk-snapshots"
  project = var.project_id
  region  = var.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "05:30" # offset from debian job so they don’t stomp the same minute
      }
    }

    retention_policy {
      max_retention_days    = var.windows_snapshot_retention_days
      on_source_disk_delete = "KEEP_AUTO_GENERATED_SNAPSHOTS"
    }

    snapshot_properties {
      labels = local.standard_labels
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "windows_boot_disk" {
  count = var.windows_enable_disk_snapshot_schedule ? 1 : 0
  name  = google_compute_resource_policy.windows_disk_snapshots[0].name
  disk  = google_compute_instance.windows.boot_disk[0].device_name
  zone  = var.zone
}
