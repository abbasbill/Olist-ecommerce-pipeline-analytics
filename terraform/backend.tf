terraform {
  backend "gcs" {
     bucket  = "terraform-state-484923"
     prefix  = "terraform/state"
  }
}