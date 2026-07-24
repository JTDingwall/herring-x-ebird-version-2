#!/usr/bin/env Rscript

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
library_path <- Sys.getenv("EDITORIAL_R_LIBRARY", "")
if (nzchar(library_path)) .libPaths(c(library_path, .libPaths()))

source(file.path("R", "stage4a_core.R"), local = FALSE)
source(file.path("R", "stage4a_production.R"), local = FALSE)
source(file.path("R", "post_stage4a_sog_event_study_v1.R"), local = FALSE)
source(file.path("R", "editorial_requested_analysis_v1.R"), local = FALSE)
source(file.path("R", "editorial_sensitivity_v1.R"), local = FALSE)

protected_root <- Sys.getenv("EDITORIAL_PROTECTED_ROOT", "")
if (!nzchar(protected_root)) {
  stop("EDITORIAL_PROTECTED_ROOT must point to the frozen data/derived root",
       call. = FALSE)
}
requested <- Sys.getenv(
  "EDITORIAL_SENSITIVITY_IDS",
  paste(editorial_sensitivity_ids_v1(), collapse = ",")
)
sensitivity_ids <- trimws(strsplit(requested, ",", fixed = TRUE)[[1L]])
run_editorial_sensitivities_v1(
  protected_root = protected_root,
  sensitivity_ids = sensitivity_ids,
  code_commit = Sys.getenv("EDITORIAL_CODE_COMMIT", NA_character_)
)
