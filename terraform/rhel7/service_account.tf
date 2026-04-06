resource "google_service_account" "rhel7_vm" {
  account_id   = "${local.name_prefix}-sa"
  display_name = "RHEL 7 httpd demo (${local.name_prefix})"
  description  = "rhel7 packer golden image test box"
  project      = var.project_id
}

resource "google_project_iam_member" "rhel7_vm_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.rhel7_vm.email}"
}

resource "google_project_iam_member" "rhel7_vm_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.rhel7_vm.email}"
}
