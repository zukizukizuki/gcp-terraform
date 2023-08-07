terraform {
  required_version = "~> 1.5.0"

  required_providers {
    gcp = {
      source  = "hashicorp/gcp"
      version = "~> 4.35.0"
    }
  }
}
