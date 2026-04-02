dependency "gke" {
  config_path  = "../03-gke"
  skip_outputs = true
}

include "root" {
  path = find_in_parent_folders()
}

skip = true