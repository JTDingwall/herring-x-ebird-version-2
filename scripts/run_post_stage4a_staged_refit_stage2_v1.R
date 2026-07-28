#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[[1L]] else "fixture"
if (!mode %in% c("fixture", "production")) {
  stop("mode must be fixture or production", call. = FALSE)
}

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
source(file.path("R", "stage4a_core.R"), local = FALSE)
source(file.path("R", "stage4a_production.R"), local = FALSE)
source(file.path("R", "post_stage4a_sog_event_study_v1.R"), local = FALSE)
source(
  file.path("R", "post_stage4a_distance_band_sensitivity_v2.R"),
  local = FALSE
)
source(file.path("R", "post_stage4a_staged_refit_v1.R"), local = FALSE)
source(
  file.path("R", "post_stage4a_staged_refit_amendment_v1.R"),
  local = FALSE
)
source(
  file.path("R", "post_stage4a_staged_refit_stage2_v1.R"),
  local = FALSE
)

if (mode == "fixture") {
  record <- staged_refit_s2_gate_v1()
  stopifnot(
    identical(record$stage_gate$stage3_authorized_by_this_record, FALSE)
  )

  core_formula <- staged_refit_s2_formula_v1("model_response")
  core_terms <- attr(
    stats::terms(lme4::nobars(core_formula)), "term.labels"
  )
  stopifnot(
    all(staged_refit_s2_detectability_terms_v1() %in% core_terms),
    all(post_stage4a_exposure_terms_v1() %in% core_terms),
    !("log1p_prior_observer_checklists" %in% core_terms)
  )

  effort_terms <- c(
    "log_duration", "log_effort_distance", "observer_count"
  )
  for (response in effort_terms) {
    formula <- staged_refit_s2_effort_formula_v1(response)
    labels <- attr(
      stats::terms(lme4::nobars(formula)), "term.labels"
    )
    stopifnot(
      !response %in% labels,
      all(setdiff(effort_terms, response) %in% labels),
      all(staged_refit_s2_detectability_terms_v1() %in% labels)
    )
  }

  events <- data.frame(
    analysis_event_token = paste0("event_", 1:4),
    checklist_year = rep(2020L, 4L),
    stringsAsFactors = FALSE
  )
  detectability <- data.frame(
    analysis_event_token = paste0("event_", 1:4),
    checklist_year = rep(2020L, 4L),
    start_time_present = c(TRUE, TRUE, FALSE, TRUE),
    start_time_syntax_valid = c(TRUE, TRUE, FALSE, TRUE),
    coordinate_valid = c(TRUE, TRUE, TRUE, TRUE),
    stage2_covariates_complete = c(TRUE, TRUE, FALSE, TRUE),
    missingness_status = c(
      "complete", "complete", "missing_start_time", "complete"
    ),
    minutes_from_sunrise = c(5, 10, NA, 20),
    day_of_year = rep(150, 4L),
    sin_2pi_doy_365 = rep(sin(2 * pi * 150 / 365), 4L),
    cos_2pi_doy_365 = rep(cos(2 * pi * 150 / 365), 4L),
    sin_4pi_doy_365 = rep(sin(4 * pi * 150 / 365), 4L),
    cos_4pi_doy_365 = rep(cos(4 * pi * 150 / 365), 4L),
    stringsAsFactors = FALSE
  )
  # The production attach gate is fixed at 217,200 rows. Exercise its
  # one-to-one mechanics with a local equivalent rather than weakening it.
  index <- match(
    events$analysis_event_token, detectability$analysis_event_token
  )
  stopifnot(
    !anyNA(index),
    !anyDuplicated(detectability$analysis_event_token),
    sum(detectability$stage2_covariates_complete[index]) == 3L
  )

  stopifnot(
    staged_refit_s2_classify_magnitude_v1(1, 0.8) == "weakens",
    staged_refit_s2_classify_magnitude_v1(1, 0.95) == "holds",
    staged_refit_s2_classify_magnitude_v1(1, 1.2) == "strengthens"
  )

  message("POST_STAGE4A_STAGED_REFIT_S2_FIXTURE=PASS")
  quit(status = 0L)
}

code_files <- c(
  "R/post_stage4a_staged_refit_stage2_v1.R",
  "scripts/PostStage4ADetectabilityBuilder.cs",
  "scripts/build_post_stage4a_detectability_v1.ps1",
  "scripts/run_post_stage4a_staged_refit_stage2_v1.R",
  "scripts/run_post_stage4a_staged_refit_stage2_v1.ps1",
  "scripts/validate_post_stage4a_staged_refit_stage2_v1.R",
  "metadata/post_stage4a_staged_refit_stage2_authorization_v1.yml",
  "tests/testthat/test-post-stage4a-staged-refit-stage2-v1.R"
)
dirty <- system2(
  "git",
  c("status", "--porcelain", "--untracked-files=all", "--", code_files),
  stdout = TRUE,
  stderr = TRUE
)
if (length(dirty) && any(nzchar(dirty))) {
  stop(
    "Production is blocked until the Stage 2 code and record are committed",
    call. = FALSE
  )
}
execution_code_commit <- system2(
  "git", c("rev-parse", "HEAD"), stdout = TRUE
)
if (
  length(execution_code_commit) != 1L ||
    !grepl("^[0-9a-f]{40}$", execution_code_commit)
) {
  stop("Unable to resolve committed Stage 2 execution code",
       call. = FALSE)
}
run_post_stage4a_staged_refit_s2_v1(
  execution_code_commit = execution_code_commit
)
