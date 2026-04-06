output "rhel9_vm_service_account_email" {
  description = "SA email attached to the rhel9 instance"
  value       = google_service_account.rhel9_vm.email
}

output "rhel9_vm_service_account_id" {
  description = "short account id"
  value       = google_service_account.rhel9_vm.account_id
}
