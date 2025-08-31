# GCP Pub/Sub resources for Airflow DAG triggering
# This file creates the topic and subscription needed for the pubsub_trigger_dag

# Create a Pub/Sub topic for triggering the hello_world_dag
resource "google_pubsub_topic" "hello_world_trigger_topic" {
  name = "hello-world-dag-trigger"

  # Optional: Add labels for better organization
  labels = {
    environment = var.environment
    purpose     = "airflow-dag-trigger"
    project     = "step-dag"
  }

  # Optional: Enable message retention policies
  message_storage_policy {
    allowed_persistence_regions = [var.gcp_region]
  }
}

# Create a Pub/Sub subscription for the trigger topic
resource "google_pubsub_subscription" "hello_world_trigger_subscription" {
  name  = "hello-world-dag-trigger-subscription"
  topic = google_pubsub_topic.hello_world_trigger_topic.name

  # Message retention and acknowledgment settings
  message_retention_duration = "3600s" # 60 minutes
  ack_deadline_seconds       = 60

  # Enable exactly once delivery for reliability
  enable_exactly_once_delivery = true

  # Optional: Add labels for better organization
  labels = {
    environment = var.environment
    purpose     = "airflow-dag-trigger"
    project     = "step-dag"
  }
}

# Grant the Composer service account access to the subscription
resource "google_pubsub_subscription_iam_member" "subscriber" {
  subscription = google_pubsub_subscription.hello_world_trigger_subscription.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.composer_sa.email}"
}
