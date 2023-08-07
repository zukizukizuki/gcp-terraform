resource "google_cloud_scheduler_job" "weekday_gce_start_job" {
  name        = "gce-start"
  description = "平日に稼働させる開発/検品環境のGCEインスタンスを起動するジョブ"
  schedule    = "55 8 * * 1-5"
  time_zone   = "Asia/Tokyo"
  region      = "asia-northeast1"
  project     = var.project

  pubsub_target {
    topic_name = google_pubsub_topic.gce_start_stop.id
    data       = base64encode("{\"server_status\":\"start\"}")
  }
}

resource "google_cloud_scheduler_job" "weekday_gce_stop_job" {
  name        = "gce-stop"
  description = "平日に稼働させる開発/検品環境のGCEインスタンスを停止するジョブ"
  schedule    = "20 23 * * 1-5"
  time_zone   = "Asia/Tokyo"
  region      = "asia-northeast1"
  project     = var.project

  pubsub_target {
    topic_name = google_pubsub_topic.gce_start_stop.id
    data       = base64encode("{\"server_status\":\"stop\"}")
  }
}