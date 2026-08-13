output "frontend_record_fqdn" {
  value = module.dns_records.frontend_record_fqdn  
}

output "api_record_fqdn" {
  value = module.dns_records.api_record_fqdn  
}




output "api_hostname" {
    value = module.dns_records.api_hostname
}

output "frontend_hostname" {
    value = module.dns_records.frontend_hostname
}


# GitHub Actions wants those values to pass them to VITE (import.meta.env.VITE_API_BASE_URL) .

output "frontend_base_url" {
  value = "https://${module.dns_records.frontend_hostname}"
}

output "api_base_url" {
  value = "https://${module.dns_records.api_hostname}"
}