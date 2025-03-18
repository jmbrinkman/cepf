terraform
resource "google_sql_database_instance" "main" {
  name             = "cepf-instance"
  database_version = "POSTGRES_14"
  region           = "us-central1"
  settings {
    tier = "db-f1-micro"
  }
deletion_protection = false
}
resource "google_sql_database" "main" {
  name     = "cepf-db"
  instance = google_sql_database_instance.main.name
}
resource "random_password" "root_password" {
  length  = 16
  special = true
}

resource "google_sql_user" "users" {
  name = "root"
  instance = google_sql_database_instance.main.name
  password = "postgres"
}
