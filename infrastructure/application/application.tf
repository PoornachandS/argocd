resource "google_pubsub_topic" "flask" {
  name = "poornachand-sounderrajan-flask"
  project = var.project_id
  message_retention_duration = "86600s"
}

resource "google_pubsub_subscription" "flask" {
  project = var.project_id
  name    = "poornachand-sounderrajan-pubsub-subscription"
  topic   = google_pubsub_topic.flask.name
}

/*
resource "google_firestore_database" "datastore_mode_database" {
  provider = "google-beta"
  project = var.project_id
  name    = "(default)"
  location_id = "nam5"
  type        = "FIRESTORE_NATIVE"
}
*/