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

resource "google_compute_health_check" "autohealing" {
  name                = "autohealing-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10 # 50 seconds

  http_health_check {
    request_path = "/healthz"
    port         = "8080"
  }
}

resource "google_compute_region_instance_group_manager" "cepf-infra-lb-group1-mig" {
  name = "cepf-infra-lb-group1-mig"

  base_instance_name         = "app"
  region                     = "us-central1"
  distribution_policy_zones  = ["us-central1-a", "us-central1-f"]

  version {
    instance_template = google_compute_instance_template.cepf-infra-lb-group1-mig.self_link_unique
  }

  all_instances_config {
    metadata = {
      metadata_key = "metadata_value"
    }
    labels = {
      label_key = "label_value"
    }
  }

  target_pools = [google_compute_target_pool.cepf-infra-lb-group1-mig.id]
  target_size  = 2

  named_port {
    name = "custom"
    port = 8888
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }
}