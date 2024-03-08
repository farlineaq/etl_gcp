terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.75.0"
    }
  }
  backend "gcs" {
    bucket  = "#{tfstate_bucket}#"
    prefix  = "#{Build.Repository.Name}#-#{Build.SourceBranch}#"
    credentials = "#{serviceAccount}#"
  }
}

provider "google" {
    credentials = file("#{serviceAccount}#")
}