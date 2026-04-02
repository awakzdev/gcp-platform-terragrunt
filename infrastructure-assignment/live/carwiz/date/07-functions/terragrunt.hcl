dependency "networking" {
  config_path  = "../01-networking"
  skip_outputs = true
}

dependency "pubsub" {
  config_path  = "../06-pubsub"
  skip_outputs = true
}

include "root" {
  path = find_in_parent_folders()
}
