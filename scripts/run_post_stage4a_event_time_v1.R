#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[[1L]] else "fixture"
species <- if (length(args) > 1L) args[[2L]] else "Bald Eagle"
if (!mode %in% c("fixture", "production")) {
  stop("mode must be fixture or production", call. = FALSE)
}

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
analysis_library <- file.path(
  ".analysis-library", "blockaware_v1", "R-4.5", "x86_64-w64-mingw32"
)
frozen_library <- file.path(
  "renv", "library", "windows", "R-4.5", "x86_64-w64-mingw32"
)
.libPaths(c(
  if (dir.exists(analysis_library)) {
    normalizePath(analysis_library, winslash = "/")
  } else {
    character()
  },
  if (dir.exists(frozen_library)) {
    normalizePath(frozen_library, winslash = "/")
  } else {
    character()
  },
  .libPaths()
))

for (f in c(
  "stage4a_core.R", "stage4a_production.R",
  "post_stage4a_sog_event_study_v1.R",
  "post_stage4a_distance_band_sensitivity_v2.R",
  "post_stage4a_staged_refit_v1.R",
  "post_stage4a_staged_refit_amendment_v1.R",
  "post_stage4a_staged_refit_stage2_v1.R",
  "post_stage4a_stage2_block_slope_diagnostic_v1.R",
  "post_stage4a_blockaware_v1.R",
  "post_stage4a_event_time_v1.R"
)) {
  source(file.path("R", f), local = FALSE)
}

if (mode == "fixture") {
  terms <- event_time_terms_v1()
  stopifnot(
    length(terms) == 32L,
    length(unique(terms)) == 32L,
    "et_near_d0" %in% terms,
    "et_near_dm5" %in% terms,
    "et_reference_baseline" %in% terms
  )
  # A day contrast must be a difference of differences that sums to zero and
  # reuses the registered baseline.
  for (day in event_time_window_v1()) {
    weights <- event_time_day_weights_v1(day)
    stopifnot(
      length(weights) == 4L,
      abs(sum(weights)) < 1e-12,
      "et_near_baseline" %in% names(weights),
      "et_reference_baseline" %in% names(weights),
      all(names(weights) %in% terms)
    )
  }
  formula <- event_time_formula_v1("model_response")
  labels <- attr(
    stats::terms(suppressWarnings(lme4::nobars(formula))), "term.labels"
  )
  stopifnot(
    all(terms %in% labels),
    all(staged_refit_s2_detectability_terms_v1() %in% labels),
    !any(post_stage4a_exposure_terms_v1() %in% labels)
  )
  # Day windows and the retained registered blocks must not overlap.
  spec <- event_time_block_spec_v1()
  window <- event_time_window_v1()
  for (block in names(spec)) {
    range <- spec[[block]]
    stopifnot(!any(window >= range[[1L]] & window <= range[[2L]]))
  }
  stopifnot(identical(spec$baseline, c(-28L, -15L)))
  message("EVENT_TIME_FIXTURE=PASS")
  quit(status = 0L)
}

authorization <- staged_refit_authorization_gate_v1()
if (!identical(
  Sys.getenv("POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED"),
  authorization$environment_acknowledgement$value
)) {
  stop(
    "Production requires the exact author-set current-shell acknowledgement",
    call. = FALSE
  )
}
execution_code_commit <- system2("git", c("rev-parse", "HEAD"), stdout = TRUE)
if (
  length(execution_code_commit) != 1L ||
    !grepl("^[0-9a-f]{40}$", execution_code_commit)
) {
  stop("Unable to resolve the execution commit", call. = FALSE)
}
run_post_stage4a_event_time_v1(
  execution_code_commit = execution_code_commit,
  species = species
)
