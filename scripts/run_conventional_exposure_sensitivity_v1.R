#!/usr/bin/env Rscript

# Run exactly the support-selected conventional exposure sensitivity. The
# design_selection.csv gate must already exist and must predate model results.

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
library_path <- Sys.getenv("EDITORIAL_R_LIBRARY", "")
if (nzchar(library_path)) .libPaths(c(library_path, .libPaths()))

source(file.path("R", "stage4a_core.R"), local = FALSE)
source(file.path("R", "stage4a_production.R"), local = FALSE)
source(file.path("R", "post_stage4a_sog_event_study_v1.R"), local = FALSE)
source(file.path("R", "editorial_requested_analysis_v1.R"), local = FALSE)
source(file.path("R", "editorial_sensitivity_v1.R"), local = FALSE)

output_dir <- "outputs/conventional_exposure_sensitivity_v1"
selection_path <- file.path(output_dir, "design_selection.csv")
if (!file.exists(selection_path)) {
  stop(
    "CONVENTIONAL_SELECTION_GATE: run the support-only selection first",
    call. = FALSE
  )
}
selection <- utils::read.csv(selection_path, stringsAsFactors = FALSE)
selected <- selection[selection$selected, , drop = FALSE]
if (nrow(selected) != 1L ||
    selected$candidate[[1L]] != "nearest_event" ||
    selected$selection_used_effect_estimates[[1L]] ||
    selected$models_fitted_during_selection[[1L]] != 0L) {
  stop("CONVENTIONAL_SELECTION_GATE: invalid prerecord", call. = FALSE)
}

result_path <- file.path(
  output_dir, "conventional_exposure_sensitivity_results.csv"
)
if (file.exists(result_path)) {
  stop(
    "CONVENTIONAL_NO_RERUN_GATE: final results already exist",
    call. = FALSE
  )
}

protected_root <- Sys.getenv("EDITORIAL_PROTECTED_ROOT", "")
if (!nzchar(protected_root)) {
  stop("EDITORIAL_PROTECTED_ROOT must point to the frozen data/derived root",
       call. = FALSE)
}
checkpoint_dir <- Sys.getenv(
  "CONVENTIONAL_SENSITIVITY_CHECKPOINT_DIR",
  file.path(
    protected_root, "conventional_exposure_sensitivity_v1", "checkpoints"
  )
)

run_editorial_sensitivities_v1(
  protected_root = protected_root,
  sensitivity_ids = selected$candidate[[1L]],
  output_dir = output_dir,
  checkpoint_dir = checkpoint_dir,
  primary_contrasts_path = file.path(
    "outputs", "editorial_requested_analysis_v1",
    "active_minus_pre_contrasts.csv"
  ),
  code_commit = Sys.getenv("EDITORIAL_CODE_COMMIT", NA_character_)
)
