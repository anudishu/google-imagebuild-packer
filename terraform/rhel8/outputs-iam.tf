output "rhel8_vm_service_account_email" {
  description = "SA email attached to the rhel8 instance"
  value       = google_service_account.rhel8_vm.email
}

output "rhel8_vm_service_account_id" {
  description = "short account id"
  value       = google_service_account.rhel8_vm.account_id
}
