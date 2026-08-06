#!/usr/bin/env Rscript

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
library_path <- Sys.getenv("EDITORIAL_R_LIBRARY", "")
if (nzchar(library_path)) .libPaths(c(library_path, .libPaths()))

source(file.path("R", "stage4a_core.R"), local = FALSE)
source(file.path("R", "stage4a_production.R"), local = FALSE)
source(file.path("R", "post_stage4a_sog_event_study_v1.R"), local = FALSE)
source(file.path("R", "editorial_requested_analysis_v1.R"), local = FALSE)

protected_root <- Sys.getenv("EDITORIAL_PROTECTED_ROOT", "")
if (!nzchar(protected_root)) {
  stop("EDITORIAL_PROTECTED_ROOT must point to the frozen data/derived root",
       call. = FALSE)
}
code_commit <- Sys.getenv("EDITORIAL_CODE_COMMIT", NA_character_)
run_editorial_requested_analysis_v1(
  protected_root = protected_root,
  code_commit = code_commit
)
