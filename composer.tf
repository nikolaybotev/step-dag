# Google Cloud Composer Environment
resource "google_composer_environment" "composer_env" {
  name   = "${var.project_name}-${var.environment}-composer"
  region = var.gcp_region
  
  config {
    software_config {
      image_version = var.composer_image_version
      
      # Airflow configuration overrides for Composer 3
      airflow_config_overrides = {
        core-dags_are_paused_at_creation = "True"
      }
      
      # Environment variables
      env_variables = {
        ENVIRONMENT = var.environment
        PROJECT_NAME = var.project_name
      }
      
      # Python dependencies (optional)
      # pypi_packages = {
      #   "pandas" = "==2.0.3"
      #   "numpy"  = "==1.24.3"
      # }
    }
    
    node_config {
      network    = google_compute_network.composer_network.id
      subnetwork = google_compute_subnetwork.composer_subnet.id
      
      # Service account for Composer
      service_account = google_service_account.composer_sa.email
    }
    
    # Worker configuration for Composer 3
    workloads_config {
      scheduler {
        cpu        = 0.5
        memory_gb  = 2.0
        storage_gb = 1
      }
      
      web_server {
        cpu        = 0.5
        memory_gb  = 2.0
        storage_gb = 1
      }
      
      worker {
        cpu        = 1
        memory_gb  = 4.0
        storage_gb = 10
        min_count  = 1
        max_count  = 3
      }
    }
  }
}

# Network for Composer
resource "google_compute_network" "composer_network" {
  name                    = "${var.project_name}-${var.environment}-composer-network"
  auto_create_subnetworks = false
}

# Subnetwork for Composer
resource "google_compute_subnetwork" "composer_subnet" {
  name          = "${var.project_name}-${var.environment}-composer-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.gcp_region
  network       = google_compute_network.composer_network.id
  
  # Enable flow logs for monitoring
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling       = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }
}

# Service Account for Composer
resource "google_service_account" "composer_sa" {
  account_id   = "${var.project_name}-${var.environment}-composer-sa"
  display_name = "Service Account for Composer Environment"
}

# IAM roles for Composer service account
resource "google_project_iam_member" "composer_worker" {
  project = var.gcp_project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.composer_sa.email}"
}

resource "google_project_iam_member" "composer_admin" {
  project = var.gcp_project_id
  role    = "roles/composer.admin"
  member  = "serviceAccount:${google_service_account.composer_sa.email}"
}

# Additional IAM roles for Composer 3
resource "google_project_iam_member" "composer_service_agent" {
  project = var.gcp_project_id
  role    = "roles/composer.serviceAgent"
  member  = "serviceAccount:${google_service_account.composer_sa.email}"
}

resource "google_project_iam_member" "storage_object_viewer" {
  project = var.gcp_project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.composer_sa.email}"
}

# Cloud Storage bucket for DAGs
resource "google_storage_bucket" "dags_bucket" {
  name          = "${var.project_name}-${var.environment}-dags"
  location      = var.gcp_region
  force_destroy = true
  
  versioning {
    enabled = true
  }
  
  labels = {
    environment = var.environment
    project     = var.project_name
    purpose     = "airflow-dags"
  }
}

# Upload the DAG file to the DAGs bucket
resource "google_storage_bucket_object" "hello_world_dag" {
  name   = "dags/hello_world_dag.py"
  bucket = google_storage_bucket.dags_bucket.name
  source = "${path.module}/dags/hello_world_dag.py"
  
  # Trigger upload when DAG file changes
  depends_on = [google_storage_bucket.dags_bucket]
}
