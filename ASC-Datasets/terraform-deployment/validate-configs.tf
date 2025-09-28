# Software (software, scripts or sample code) is licensed under the Apache License, Version 2.0.
# Author: AWS Professional Services

locals {
  allowed_input_keys = [
    "schema",
    "name",
    "description",
    "namespace",
    "instanceName",
    "instanceId",
    "tags",
    "partitionSpec"
  ]

  # collect all invalid keys (not in allowed list)
  all_keys = flatten([
    for cfg_key, cfg_val in local.asc_datasets_config : [
      for key in keys(cfg_val.input) : {
        full_key = "${cfg_key}.${key}"
        valid    = contains(local.allowed_input_keys, key)
      }
    ]
  ])

  all_invalid_keys = [
    for entry in local.all_keys : entry.full_key if !entry.valid
  ]

  # generate name::namespace::instanceId list to check for duplicates
  name_namespace_instance_id_pairs = [
    for cfg in values(local.asc_datasets_config) :
    "${cfg.input.name}::${cfg.input.namespace}::${cfg.input.instanceId}"
  ]

  duplicate_name_namespace_instance_id_pairs = distinct([
    for pair in local.name_namespace_instance_id_pairs :
    pair if length([
      for p in local.name_namespace_instance_id_pairs : p if p == pair
    ]) > 1
  ])

  has_duplicate_name_namespace_instance_id = length(local.duplicate_name_namespace_instance_id_pairs) > 0
}

resource "null_resource" "validate_configs" {
  triggers = {
    always = "run"
  }

  lifecycle {
    precondition {
      condition     = length(local.all_invalid_keys) == 0
      error_message = "Invalid keys found in ASC dataset config inputs: ${join(", ", local.all_invalid_keys)}"
    }

    precondition {
      condition     = !local.has_duplicate_name_namespace_instance_id
      error_message = "Duplicate (name, namespace) pair found in ASC Dataset configs: Please use uniue name/namespace configs for each key - ${join(", ", local.duplicate_name_namespace_instance_id_pairs)}"
    }
  }
}