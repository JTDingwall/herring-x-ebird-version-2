#!/usr/bin/env Rscript

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
library_paths <- c(
  Sys.getenv("EDITORIAL_GLMMTMB_LIBRARY", ""),
  Sys.getenv("EDITORIAL_R_LIBRARY", "")
)
library_paths <- library_paths[nzchar(library_paths)]
if (length(library_paths)) .libPaths(c(library_paths, .libPaths()))

source(file.path("R", "stage4a_core.R"), local = FALSE)
source(file.path("R", "stage4a_production.R"), local = FALSE)
source(file.path("R", "post_stage4a_sog_event_study_v1.R"), local = FALSE)
source(file.path("R", "editorial_requested_analysis_v1.R"), local = FALSE)
source(file.path("R", "editorial_engine_validation_v1.R"), local = FALSE)

protected_root <- Sys.getenv("EDITORIAL_PROTECTED_ROOT", "")
species <- Sys.getenv("EDITORIAL_VALIDATION_SPECIES", "")
outcome <- Sys.getenv("EDITORIAL_VALIDATION_OUTCOME", "")
if (!nzchar(protected_root) || !nzchar(species) || !nzchar(outcome)) {
  stop("Protected root, validation species, and validation outcome required",
       call. = FALSE)
}
run_editorial_engine_validation_component_v1(
  protected_root = protected_root,
  species = species,
  outcome = outcome,
  code_commit = Sys.getenv("EDITORIAL_CODE_COMMIT", NA_character_)
)
