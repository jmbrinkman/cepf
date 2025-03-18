resource "local_file" "default" {
  file_permission = "0644"
  filename        = "backend.tf"

  # You can store the template in a file and use the templatefile function for
  # more modularity, if you prefer, instead of storing the template inline as
  # we do here.
  content = <<-EOT
  terraform {
    backend "gcs" {
      bucket = "qwiklabs-gcp-00-fd1b34daa3bd-bucket-tfstate"
    }
  }
  EOT
}

resource "google_sql_database_instance" "main" {
  name             = "cepf-instance"
  project         = "qwiklabs-gcp-00-fd1b34daa3bd"
  database_version = "POSTGRES_14"
  region           = "us-central1"
  settings {
    tier = "db-f1-micro"
  }
deletion_protection = false
}
resource "google_sql_database" "main" {
  name     = "cepf-db"
  project         = "qwiklabs-gcp-00-fd1b34daa3bd"
  instance = google_sql_database_instance.main.name
}
resource "random_password" "root_password" {
  length  = 16
  special = true
}

resource "google_sql_user" "users" {
  project  = "qwiklabs-gcp-00-fd1b34daa3bd"
  name = "root"
  instance = google_sql_database_instance.main.name
  password = "postgres"
}

resource "google_service_account" "default" {
  account_id   = "service-account-id"
  display_name = "Service Account"
}

resource "google_compute_instance_template" "default" {
  name        = "template"
  description = "This template is used to create app server instances."

  instance_description = "description assigned to instances"
  machine_type         = "e2-medium"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
 disk {
    // Instance Templates reference disks by name, not self link
    source      = google_compute_disk.foobar.name
    auto_delete = false
    boot        = false
  }

  network_interface {
    network = "default"
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.default.email
    scopes = ["cloud-platform"]
  }
}

data "google_compute_image" "my_image" {
  family  = "debian-11"
  project = "debian-cloud"
}

resource "google_compute_disk" "foobar" {
  name  = "existing-disk"
  image = data.google_compute_image.my_image.self_link
  size  = 10
  type  = "pd-ssd"
  zone  = "us-central1-a"
}

resource "google_compute_resource_policy" "daily_backup" {
  name   = "every-day-4am"
  region = "us-central1"
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "04:00"
      }
    }
  }
}

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
