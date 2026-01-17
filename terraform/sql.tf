resource "google_compute_global_address" "private_service_range" {
  name          = "${var.network_name}-sql-peering"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]

  depends_on = [google_project_service.apis]
}

resource "random_password" "sql_password" {
  length  = 20
  special = true
}

resource "random_password" "sql_password2" {
  length  = 20
  special = true
}

locals {
  effective_sql_password  = var.sql_password != "" ? var.sql_password : random_password.sql_password.result
  effective_sql_password2 = var.sql_password2 != "" ? var.sql_password2 : random_password.sql_password2.result
}

resource "google_sql_database_instance" "postgres" {
  name             = var.sql_instance_name
  region           = var.region
  database_version = var.sql_postgres_version

  deletion_protection = var.deletion_protection

  settings {
    tier              = var.sql_tier
    availability_type = "REGIONAL" # HA


    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
      ssl_mode        = "ENCRYPTED_ONLY"
    }

    insights_config {
      query_insights_enabled = true
    }
  }

  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]
}

resource "google_sql_database" "appdb_inventory" {
  name     = var.sql_database_name_inventory
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_database" "appdb_order" {
  name     = var.sql_database_name_order
  instance = google_sql_database_instance.postgres.name
}


resource "google_sql_user" "appuser_inventory" {
  name     = var.sql_user_name_inventory
  instance = google_sql_database_instance.postgres.name
  password = local.effective_sql_password
}

resource "google_sql_user" "appuser_order" {
  name     = var.sql_user_name_order
  instance = google_sql_database_instance.postgres.name
  password = local.effective_sql_password
}