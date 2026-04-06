output "centos7_vm_service_account_email" {
  description = "SA email attached to the centos7 instance"
  value       = google_service_account.centos7_vm.email
}

output "centos7_vm_service_account_id" {
  description = "short account id"
  value       = google_service_account.centos7_vm.account_id
}
