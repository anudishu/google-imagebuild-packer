output "rhel7_vm_service_account_email" {
  description = "SA email attached to the rhel7 instance"
  value       = google_service_account.rhel7_vm.email
}

output "rhel7_vm_service_account_id" {
  description = "short account id"
  value       = google_service_account.rhel7_vm.account_id
}
