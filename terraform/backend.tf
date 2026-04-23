terraform {
  backend "gcs" {
     bucket  = "terraform-state-4939"
     prefix  = "terraform/state"
  }
}