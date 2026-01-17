# Reserve a global static IP for the GKE Ingress (HTTP(S) Load Balancer)
# Reference this in your Ingress manifest:
#   kubernetes.io/ingress.global-static-ip-name: <name>
resource "google_compute_global_address" "ingress_ip" {
  name = "${var.cluster_name}-ingress-ip"

  depends_on = [google_project_service.apis]
}
