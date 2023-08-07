terraform {
  required_version = "~> 1.5"

  required_providers {
    gcp = {
      source  = "hashicorp/gcp"
      version = "~> 4.35.0"
    }
  }
}
