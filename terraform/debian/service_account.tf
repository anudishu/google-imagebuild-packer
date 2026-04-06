resource "google_service_account" "apache_vm" {
  account_id   = "${local.name_prefix}-sa"
  display_name = "Apache demo VM (${local.name_prefix})"
  description  = "apache packer image test instance"
  project      = var.project_id
}

resource "google_project_iam_member" "apache_vm_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.apache_vm.email}"
}

resource "google_project_iam_member" "apache_vm_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.apache_vm.email}"
}
