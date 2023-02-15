resource "google_pubsub_topic" "flask" {
  name = "flask-pub-sub"
  project = var.project_id
  message_retention_duration = "86600s"
}

resource "google_pubsub_subscription" "flaskl" {
  project = var.project_id
  name    = "pubsub-subscription"
  topic   = google_pubsub_topic.flask.name
}

resource "google_firestore_database" "datastore_mode_database" {
  provider = "google-beta"
  project = var.project_id
  name = "(default)"
  location_id = "eur3"
  type        = "FIRESTORE_NATIVE"
}