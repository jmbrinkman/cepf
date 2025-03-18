resource "google_compute_image" "default" {
  name                   = "debian-11-image-template-uiuuiuiiu"
  project                = var.gcp_project_id
  family                 = "debian-11"
  raw_disk {
    source = "https://storage.googleapis.com/gce-uefi-images/debian-11/debian-11.tar.gz"
  }
  source_disk_project    = "gce-uefi-images"
  storage_locations      = [var.gcp_region]
}
