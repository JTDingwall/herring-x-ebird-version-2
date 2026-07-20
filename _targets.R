library(targets)

tar_option_set(packages = c("data.table", "digest", "jsonlite", "yaml"), format = "rds", error = "stop")

source("R/assert.R")
source("R/config.R")
source("R/species_registry.R")
source("R/model_registry.R")

list(
  tar_target(config, read_project_config()),
  tar_target(outcome_gate, {
    stopifnot(identical(config$project$outcome_gate, "metadata_design_only"))
    config$project$outcome_gate
  }),
  tar_target(species_registry, read_species_registry()),
  tar_target(guild_registry, read_guild_registry()),
  tar_target(species_guild_validation, validate_species_guilds(species_registry, guild_registry)),
  tar_target(estimand_registry, read_estimand_registry()),
  tar_target(model_registry, read_model_registry()),
  tar_target(module_registry, read_analysis_module_registry()),
  tar_target(model_foreign_keys,
             validate_model_foreign_keys(model_registry, estimand_registry, module_registry)),
  tar_target(registry_counts, validate_registry_bundle())
)
