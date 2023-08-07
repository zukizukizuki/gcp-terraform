resource "google_pubsub_topic" "gce_start_stop" {
  name    = "gce_start_stop"
  project = var.project
}