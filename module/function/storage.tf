locals {
  config_src_dir = var.is_secure ? "sec" : "std"
}

data "google_iam_policy" "gcs_policy" {
  binding {
    role = "roles/storage.legacyBucketOwner"
    members = [
      "projectEditor:${var.project}",
      "projectOwner:${var.project}",
    ]
  }
  binding {
    role = "roles/storage.legacyObjectOwner"
    members = [
      "projectEditor:${var.project}",
      "projectOwner:${var.project}",
    ]
  }
  binding {
    role = "roles/storage.legacyBucketReader"
    members = [
      "serviceAccount:${google_service_account.gce_start_stop.email}",
    ]
  }
  binding {
    role = "roles/storage.objectViewer"
    members = [
      "serviceAccount:${google_service_account.gce_start_stop.email}",
    ]
  }
}

resource "google_storage_bucket" "bucket_for_cloud_functions" {
  name          = "${var.project}_bucket_for_cloud_functions"
  location      = "asia-northeast1"
  force_destroy = true
  project       = var.project
}

resource "google_storage_bucket" "gce_start_stop_config" {
  name          = "${var.project}_gce_start_stop_config"
  location      = "asia-northeast1"
  force_destroy = true
  project       = var.project
}

resource "google_storage_bucket_iam_policy" "gce_start_stop_config" {
  bucket      = google_storage_bucket.gce_start_stop_config.name
  policy_data = data.google_iam_policy.gcs_policy.policy_data
}

resource "google_storage_bucket_object" "exclude_instances_config" {
  name   = "exclude_instances.txt"
  bucket = google_storage_bucket.gce_start_stop_config.name
  source = "../module/function/gce-start-stop/gcs_file/${local.config_src_dir}/exclude_instances.txt"
}

resource "google_storage_bucket_object" "project_list_config" {
  name   = "project_list.txt"
  bucket = google_storage_bucket.gce_start_stop_config.name
  source = "../module/function/gce-start-stop/gcs_file/${local.config_src_dir}/project_list.txt"
}