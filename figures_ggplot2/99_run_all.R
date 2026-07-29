args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args) >= 1L) args[[1L]] else "."
source_root <- if (length(args) >= 2L) args[[2L]] else root
skip_prepare <- length(args) >= 3L && identical(args[[3L]], "skip-prepare")

options(
  mer.root = normalizePath(root, winslash = "/", mustWork = TRUE),
  mer.source_root = normalizePath(source_root, winslash = "/", mustWork = TRUE)
)
setwd(getOption("mer.root"))

scripts <- c(
  if (!skip_prepare) "00_prepare_stage2_inputs.R",
  "01_map_study_area.R",
  "02_study_design.R",
  "03_family_forest.R",
  "04_period_profiles.R",
  "05_supp_pretrend_and_tables.R",
  "06_distance_band_profiles.R"
)

if (skip_prepare) {
  committed_inputs <- file.path(
    getOption("mer.root"), "figures_out",
    c(
      "tableS_primary_contrast_49x2_stage2.csv",
      "tableS_period_profiles_49x2_stage2.csv",
      "tableS_distance_bands_3species_stage2.csv"
    )
  )
  if (any(!file.exists(committed_inputs))) {
    stop(
      "SKIP_PREPARE_GATE: one or more committed figure inputs are missing",
      call. = FALSE
    )
  }
  message("STAGE2_INPUT_PREPARATION=SKIPPED_USING_COMMITTED_AGGREGATES")
}

for (script in scripts) {
  message("SCRIPT_START=", script)
  source(file.path("figures_ggplot2", script), local = new.env(parent = globalenv()))
  message("SCRIPT_PASS=", script)
}

message("STAGE2_VECTOR_FIGURES=PASS")
