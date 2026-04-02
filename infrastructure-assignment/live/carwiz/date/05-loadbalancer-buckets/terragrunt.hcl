dependency "networking" {
  config_path  = "../01-networking"
  skip_outputs = true
}

dependency "dns" {
  config_path  = "../01-dns"
  skip_outputs = true
}

include "root" {
  path = find_in_parent_folders()
}
