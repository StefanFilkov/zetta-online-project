resource "google_service_account" "gke_nodes" {
  account_id   = "${var.cluster_name}-nodes"
  display_name = "GKE node service account"
}

resource "google_project_iam_member" "gke_nodes_logwriter" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_metricwriter" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitorviewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_resourcemetadata" {
  project = var.project_id
  role    = "roles/stackdriver.resourceMetadata.writer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_artifactregistry" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_service_account" "cloudsql_client" {
  account_id   = "${var.cluster_name}-cloudsql"
  display_name = "Workload Identity: Cloud SQL Client"
}

resource "google_project_iam_member" "cloudsql_client_role" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudsql_client.email}"
}

resource "google_container_cluster" "cluster" {
  name     = var.cluster_name
  location = var.region

    gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }
  
  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "REGULAR"
  }

  # VPC-native/IP aliasing
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }


  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }

  depends_on = [
    google_project_service.apis,
    google_compute_router_nat.nat
  ]
}

resource "google_project_service" "certificatemanager" {
  project            = var.project_id
  service            = "certificatemanager.googleapis.com"
  disable_on_destroy = false
}


resource "google_container_node_pool" "primary" {
  name       = "apps"
  location   = var.region
  cluster    = google_container_cluster.cluster.name
  node_count = var.node_count

  autoscaling {
    min_node_count = var.node_pool_min
    max_node_count = var.node_pool_max
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type    = var.node_machine_type
    disk_size_gb    = var.node_disk_size_gb
    service_account = google_service_account.gke_nodes.email

    tags = ["gke-app-nodes"]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  depends_on = [
    google_project_iam_member.gke_nodes_logwriter,
    google_project_iam_member.gke_nodes_metricwriter,
    google_project_iam_member.gke_nodes_monitorviewer,
    google_project_iam_member.gke_nodes_resourcemetadata,
    #    google_project_iam_member.gke_nodes_artifactregistry
  ]
}
