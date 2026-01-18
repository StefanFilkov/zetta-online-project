variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region (regional GKE + Cloud SQL)"
  type        = string
  default     = "europe-west3"
}

# Variables for GitHub repository configuration
variable "github_repository_owner" {
  description = "GitHub repository owner (organization or username)"
  type        = string
  default     = "StefanFilkov"
}

variable "github_repository_name" {
  description = "GitHub repository name"
  type        = string
  default     = "zetta-online-project" 
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "ha-gke"
}

variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "ha-vpc"
}

variable "subnet_name" {
  description = "Primary subnet name"
  type        = string
  default     = "ha-subnet"
}

variable "subnet_cidr" {
  description = "Primary subnet CIDR"
  type        = string
  default     = "10.10.0.0/16"
}

variable "pods_range_cidr" {
  description = "Secondary range for GKE Pods"
  type        = string
  default     = "10.20.0.0/16"
}

variable "services_range_cidr" {
  description = "Secondary range for GKE Services"
  type        = string
  default     = "10.30.0.0/20"
}

variable "master_ipv4_cidr_block" {
  description = "CIDR for GKE control plane /28 when using private cluster"
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_networks" {
  description = <<EOT
List of CIDR blocks allowed to access the Kubernetes API server public endpoint.
Example:
[
  { cidr_block = "203.0.113.10/32", display_name = "home" }
]
If empty, master authorized networks are not enabled.
EOT
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "node_machine_type" {
  description = "GKE node machine type"
  type        = string
  default     = "e2-standard-2"
}

variable "node_disk_size_gb" {
  description = "GKE node boot disk size (GB). Recommended 30-50."
  type        = number
  default     = 50
}

variable "node_count" {
  description = "Initial number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "node_pool_min" {
  description = "Minimum nodes for autoscaling"
  type        = number
  default     = 1
}

variable "node_pool_max" {
  description = "Maximum nodes for autoscaling"
  type        = number
  default     = 3
}

variable "sql_instance_name" {
  description = "Cloud SQL instance name"
  type        = string
  default     = "ha-postgres"
}

variable "sql_database_name_inventory" {
  description = "Application database name"
  type        = string
  default     = "inventory_service_db"
}

variable "sql_database_name_order" {
  description = "Application database name"
  type        = string
  default     = "order_service_db"
}

variable "sql_user_name_inventory" {
  description = "Database user"
  type        = string
  default     = "inventory_service_user"
}

variable "sql_user_name_order" {
  description = "Database user"
  type        = string
  default     = "order_service_user"
}

variable "sql_password" {
  description = "Database user password. If empty, a random password is generated."
  type        = string
  default     = ""
  sensitive   = true
}

variable "sql_password2" {
  description = "Database user password. If empty, a random password is generated."
  type        = string
  default     = ""
  sensitive   = true
}


variable "sql_tier" {
  description = "Cloud SQL machine tier"
  type        = string
  default     = "db-custom-2-8192"
}

variable "sql_postgres_version" {
  description = "Cloud SQL Postgres major version"
  type        = string
  default     = "POSTGRES_15"
}

variable "deletion_protection" {
  description = "Set true to prevent accidental terraform destroy"
  type        = bool
  default     = false
}
