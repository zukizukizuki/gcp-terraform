# ---------------------------------
# CloudFunctions for gce_start_stop.
# ---------------------------------
resource "google_service_account" "gce_start_stop" {
  project      = var.project
  account_id   = "gce_start_stop"
  display_name = "gce_start_stop"
  description  = "VM定期起動停止用サービスアカウント"
}

data "archive_file" "archive_gce_start_stop" {
  type        = "zip"
  source_dir  = "../module/function/gce_start_stop/src"
  output_path = "../module/function/gce_start_stop/deploy/functions.zip"
}

resource "google_storage_bucket_object" "gce_start_stop_src" {
  # hashを使う理由はterraformでソースの変更を検知するため
  name   = "gce_start_stop/functions-${data.archive_file.archive_gce_start_stop.output_md5}.zip"
  bucket = google_storage_bucket.bucket_for_cloud_functions.name
  source = data.archive_file.archive_gce_start_stop.output_path
}

resource "google_cloudfunctions2_function" "gce_start_stop_function" {
  name        = "gce_start_stop-function"
  description = "指定のGCEインスタンスを起動/停止する"
  project     = var.project
  location    = "asia-northeast1"

  build_config {
    runtime     = "python310"
    entry_point = "main"
    source {
      storage_source {
        bucket = google_storage_bucket.bucket_for_cloud_functions.name
        object = google_storage_bucket_object.gce_start_stop_src.name
      }
    }
  }

  service_config {
    timeout_seconds       = 540
    available_memory      = "256M"
    max_instance_count    = 1
    service_account_email = google_service_account.gce_start_stop.email
    environment_variables = {
      EXCLUDE_INSTANCES_LIST       = google_storage_bucket_object.exclude_instances_config.name
      PROJECT_LIST                 = google_storage_bucket_object.project_list_config.name
      GCE_START_STOP_CONFIG_BUCKET = google_storage_bucket.gce_start_stop_config.name
    }
  }

  event_trigger {
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.gce_start_stop.id
    service_account_email = google_service_account.gce_start_stop.email
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
    trigger_region        = "asia-northeast1"
  }
}

# terraform側のバグが発生しているためコメントアウト
# https://github.com/hashicorp/terraform-provider-google/issues/12562
# resource "google_cloudfunctions2_function_iam_member" "invoking" {
#   project        = var.project
#   location       = "asia-northeast1"
#   cloud_function = google_cloudfunctions2_function.gce_start_stop_function.name
#   role           = "roles/run.invoker"
#   member         = "serviceAccount:${google_service_account.gce_start_stop.email}"
# }