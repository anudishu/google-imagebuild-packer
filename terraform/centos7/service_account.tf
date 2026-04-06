resource "google_service_account" "centos7_vm" {
  account_id   = "${local.name_prefix}-sa"
  display_name = "CentOS 7 httpd demo (${local.name_prefix})"
  description  = "centos7 packer golden image test box"
  project      = var.project_id
}

resource "google_project_iam_member" "centos7_vm_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.centos7_vm.email}"
}

resource "google_project_iam_member" "centos7_vm_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.centos7_vm.email}"
}
