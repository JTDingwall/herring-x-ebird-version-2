library(targets)

tar_option_set(
  packages = c("data.table", "digest", "jsonlite", "yaml"),
  format = "rds",
  error = "stop"
)

source("R/assert.R")
source("R/config.R")
source("R/metadata_audit.R")
source("R/species_registry.R")
source("R/model_registry.R")

list(
  tar_target(config, read_project_config()),
  tar_target(input_paths, resolve_input_paths(config)),
  tar_target(species_registry, read_species_registry()),
  tar_target(guild_registry, read_guild_registry()),
  tar_target(species_guild_validation, validate_species_guilds(species_registry, guild_registry)),
  tar_target(model_registry, read_model_registry()),
  tar_target(input_audit, audit_inputs(input_paths, checksum = TRUE), cue = tar_cue(mode = "always")),
  tar_target(metadata_audit_json, write_metadata_audit_json(input_audit), format = "file")
)
