output "cluster_name" {
  value = google_container_cluster.cluster.name
}

output "cluster_location" {
  value = google_container_cluster.cluster.location
}

output "cluster_endpoint" {
  value = google_container_cluster.cluster.endpoint
}

output "ingress_static_ip_name" {
  description = "Name of the reserved global static IP to reference in the Kubernetes Ingress"
  value       = google_compute_global_address.ingress_ip.name
}

output "ingress_static_ip_address" {
  value = google_compute_global_address.ingress_ip.address
}

output "artifact_registry_repo" {
  value = google_artifact_registry_repository.docker.id
}

output "cloudsql_instance_connection_name" {
  value = google_sql_database_instance.postgres.connection_name
}

output "cloudsql_private_ip" {
  # Provider versions differ: prefer the explicit attribute when present, else derive from ip_address blocks.
  value = try(
    google_sql_database_instance.postgres.private_ip_address,
    one([for a in google_sql_database_instance.postgres.ip_address : a.ip_address if a.type == "PRIVATE"])
  )
}

output "db_name_inventory" {
  value = google_sql_database.appdb_inventory.name
}

output "db_user_inventory" {
  value = google_sql_user.appuser_inventory.name
}

output "db_name_order" {
  value = google_sql_database.appdb_order.name
}

output "db_user_order" {
  value = google_sql_user.appuser_order.name
}

output "db_password" {
  value     = local.effective_sql_password
  sensitive = true
}

output "workload_identity_cloudsql_gsa" {
  description = "Google service account to bind to a Kubernetes service account for Cloud SQL access"
  value       = google_service_account.cloudsql_client.email
}

output "get_credentials_command" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.cluster.name} --region ${var.region} --project ${var.project_id}"
}

output "github_workload_identity_provider" {
  description = "Workload Identity Provider ID for GitHub Actions (use this in GCP_WORKLOAD_IDENTITY_PROVIDER secret)"
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "github_service_account_email" {
  description = "Service account email for GitHub Actions (use this in GCP_SERVICE_ACCOUNT secret)"
  value       = google_service_account.github_actions.email
}

