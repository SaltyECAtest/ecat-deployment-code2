variable "project_id" {}
variable "role_bindings" {}
variable "project_name" {}
variable "org_id" {}
variable "folder_id" {}
variable "billing_id" {}
variable "skip_delete" {}
variable "gcs_bucket" {}
variable "gcs_prefix" {}

terraform {
  backend "gcs" {
    bucket  = var.gcs_bucket
    prefix  = var.gcs_prefix
  }
}

resource "google_project" "project" {
 name            = var.project_name
 project_id      = var.project_id
 billing_account = var.billing_id
 folder_id       = var.folder_id
 skip_delete     = var.skip_delete
}

resource "google_project_service" "project" {
  project = google_project.project.project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

output "project_id" {
 value = google_project.project.project_id
}

resource "null_resource" "delay" {
  provisioner "local-exec" {
    command = "sleep 180"
  }
  triggers = {
    "project" = "${google_project.project.project_id}"
  }
}

resource "google_compute_network" "vpc_network" {
  depends_on = ["null_resource.delay"]
  name = "salty-test"
  auto_create_subnetworks = true
  project = google_project.project.project_id
}

resource "google_compute_instance" "vm_instance" {
  name         = "salty-test-terraform-instance"
  project = google_project.project.project_id
  machine_type = "f1-micro"
  zone = "europe-west2-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
}
