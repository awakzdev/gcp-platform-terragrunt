dependency "pubsub" {
  config_path = "../06-pubsub"
  skip_outputs = true
}

dependency "functions" {
  config_path = "../07-functions"
  skip_outputs = true
}

include "root" {
  path = find_in_parent_folders()
}