resource "google_certificate_manager_dns_authorization" "store_domashno_party_auth" {
  name        = "store-domashno-party-auth"
  domain      = "store.domashno.party"
  location    = "global"
  project     = "907024360443"

  description = "DNS Authorization for store.domashno.party"
}

output "store_dns_auth_cname" {
  description = "CNAME record to add to your DNS provider for validation"
  value       = google_certificate_manager_dns_authorization.store_domashno_party_auth.dns_resource_record
}


resource "google_certificate_manager_certificate" "store_domashno_party_cert" {
  name        = "store-domashno-party-cert"
  description = "Wildcard or specific cert for store.domashno.party"
  location    = "global"
  project     = "907024360443"

  managed {
    domains = [
      # References the domain from the authorization resource
      google_certificate_manager_dns_authorization.store_domashno_party_auth.domain
    ]
    dns_authorizations = [
      # Links the certificate to the authorization you just created
      google_certificate_manager_dns_authorization.store_domashno_party_auth.id
    ]
  }
}

resource "google_certificate_manager_certificate_map" "default" {
  name        = "domashno-party-map"
  description = "Certificate map for domashno.party domains"
  project     = var.project_id  
}

resource "google_certificate_manager_certificate_map_entry" "store_entry" {
  name        = "store-domashno-party-entry"
  description = "Entry for store.domashno.party"
  map         = google_certificate_manager_certificate_map.default.name
  
  certificates = [google_certificate_manager_certificate.store_domashno_party_cert.id]
  hostname     = "store.domashno.party"
  
  project  = var.project_id
}