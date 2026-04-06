output "apache_vm_service_account_email" {
  description = "email of the SA wired into the apache instance — use this in IAM conditionals elsewhere"
  value       = google_service_account.apache_vm.email
}

output "apache_vm_service_account_id" {
  description = "short account_id part (before @)"
  value       = google_service_account.apache_vm.account_id
}
