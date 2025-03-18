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