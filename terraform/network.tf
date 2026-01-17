resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  depends_on = [google_project_service.apis]
}

resource "google_compute_subnetwork" "subnet" {
  name                     = var.subnet_name
  region                   = var.region
  network                  = google_compute_network.vpc.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_range_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_range_cidr
  }
}

# Cloud NAT for private nodes to reach the internet (e.g., OS/package updates)
resource "google_compute_router" "router" {
  name    = "${var.cluster_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.cluster_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Allow GCLB health checks to reach NodePorts created by GKE Ingress
resource "google_compute_firewall" "allow_lb_health_checks" {
  name    = "${var.cluster_name}-allow-lb-hc"
  network = google_compute_network.vpc.name

  direction = "INGRESS"
  priority  = 1000

  source_ranges = [
    "130.211.0.0/22", #Google Cloud Load Balancer health check / proxy source
    "35.191.0.0/16",
  ]

  target_tags = ["gke-app-nodes"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "30000-32767"]
  }
}
