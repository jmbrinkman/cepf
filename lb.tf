resource "google_compute_global_forwarding_rule" "default" {
  name                  = "cepf-infra-lb"
  target                = google_compute_target_http_proxy.default.id
  port_range            = "80"
  project               = "qwiklabs-gcp-00-fd1b34daa3bd"
}

resource "google_compute_target_http_proxy" "default" {
  name                  = "cepf-infra-lb-proxy"
  url_map               = google_compute_url_map.default.id
  project               = "qwiklabs-gcp-00-fd1b34daa3bd"
}

resource "google_compute_url_map" "default" {
  name                  = "cepf-infra-lb-url-map"
  description           = "a description"
  project               = "qwiklabs-gcp-00-fd1b34daa3bd"
  default_service       = google_compute_backend_service.default.id

  host_rule {
    hosts               = ["*"]
    path_matcher        = "allpaths"
  }

  path_matcher {
    name                  = "allpaths"
    default_service       = google_compute_backend_service.default.id
  }
}

resource "google_compute_backend_service" "default" {
  name        = "cepf-infra-lb-backend-default"
  port_name   = "http"
  protocol    = "HTTP"
  project     = "qwiklabs-gcp-00-fd1b34daa3bd"
  timeout_sec = 10
  session_affinity = "GENERATED_COOKIE"

  backend {
    group           = google_compute_instance_group.default.id
  }
}

resource "google_compute_instance_group" "default" {
  name = "cepf-infra-lb-instance-group"
  zone = "europe-west4"
  project = "qwiklabs-gcp-00-fd1b34daa3bd"
}
