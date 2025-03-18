resource "google_compute_image" "default" {
  name                   = "debian-11-image-template-uiuuiuiiu"
  project                =  "qwiklabs-gcp-00-fd1b34daa3bd"
  family                 = "debian-11"
  raw_disk {
    source = "https://storage.googleapis.com/gce-uefi-images/debian-11/debian-11.tar.gz"
  }
}

