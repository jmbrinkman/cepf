data "google_compute_image" "debian" {
  family  = "debian-11"
  project = "debian-cloud"
}

resource "google_compute_disk" "persistent" {
  name  = "example-disk"
  image = data.google_compute_image.debian.self_link
  size  = 10
  type  = "pd-ssd"
  zone  = "us-central1-a"
  project = "qwiklabs-gcp-00-fd1b34daa3bd"
}

resource "google_compute_image" "example" {
  name = "example-image"
  project = "qwiklabs-gcp-00-fd1b34daa3bd"
  source_disk = google_compute_disk.persistent.id
}