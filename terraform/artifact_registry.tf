resource "google_artifact_registry_repository" "docker" {
  location      = var.region
  repository_id = "${var.cluster_name}-docker"
  description   = "Docker images for ${var.cluster_name}"
  format        = "DOCKER"

  depends_on = [google_project_service.apis]
}
