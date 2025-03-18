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
