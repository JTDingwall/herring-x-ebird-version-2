#!/usr/bin/env Rscript

# Specification-only builder. It reads identity fields plus the two invalid v1
# columns solely to identify the authoritative 6,562-row scope. It never reads or
# calculates estimates, standard errors, intervals, p-values, or q-values.
source(file.path("R", "assert.R"))
source(file.path("R", "stage4a_pooling_repair_spec_v2.R"))

registries <- stage4a_pooling_v2_build_registries(
  effect_file = file.path("outputs", "stage4a_results", "effect_estimates.csv"),
  species_file = file.path("metadata", "canonical_species_registry.csv"),
  guild_file = file.path("metadata", "canonical_guild_registry.csv"),
  region_file = file.path("metadata", "stage4a_region_registry_v2.csv")
)
stage4a_pooling_v2_write_registries(registries, "metadata")
message("Stage 4A pooling repair v2 specification registries written; no repaired values produced.")
