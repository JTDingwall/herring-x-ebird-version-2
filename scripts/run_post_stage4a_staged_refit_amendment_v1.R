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

if (mode == "fixture") {
  amendment <- staged_refit_amendment_gate_v1()
  stopifnot(
    identical(
      amendment$decision,
      "REPLACE_SPECIES_NEGATIVE_CONTROLS_WITH_OUTCOME_AND_TIMING_CONTROLS"
    )
  )

  effort_terms <- c(
    "log_duration", "log_effort_distance", "observer_count"
  )
  for (response in effort_terms) {
    formula <- staged_refit_amendment_effort_formula_v1(response)
    fixed_labels <- attr(
      stats::terms(lme4::nobars(formula)), "term.labels"
    )
    stopifnot(
      !response %in% fixed_labels,
      all(setdiff(effort_terms, response) %in% fixed_labels),
      all(post_stage4a_exposure_terms_v1() %in% fixed_labels)
    )
  }

  lookup <- data.frame(
    herring_source_token = c("source_0", "source_1"),
    event_year = c(2020L, 2020L),
    anchor_shift_days = c(0L, 2L),
    used_end_date_fallback = c(FALSE, FALSE),
    stringsAsFactors = FALSE
  )
  links <- data.frame(
    analysis_event_token = c("event_0", "event_1"),
    herring_source_token = c("source_0", "source_1"),
    region = c("SoG", "SoG"),
    checklist_year = c(2020L, 2020L),
    event_year = c(2020L, 2020L),
    event_day = c(180L, 178L),
    distance_km = c(1, 2),
    stringsAsFactors = FALSE
  )
  events <- data.frame(
    analysis_event_token = c("event_0", "event_1"),
    event_block_token = c("block_0", "block_1"),
    region = c("SoG", "SoG"),
    checklist_year = c(2020L, 2020L),
    concurrent_links = c(0L, 0L),
    stringsAsFactors = FALSE
  )
  fake <- staged_refit_amendment_placebo_events_v1(
    events, links, lookup, 180L
  )
  stopifnot(
    fake$link_rows == 2L,
    fake$checklists_with_links == 2L,
    identical(fake$events$concurrent_links, c(1L, 1L)),
    identical(fake$events$es_near_spawn_start, c(1L, 1L))
  )

  pooled <- staged_refit_amendment_pool_detection_v1(
    c(1L, 0L, NA_integer_, NA_integer_),
    c(0L, 0L, 1L, NA_integer_)
  )
  stopifnot(identical(pooled, c(1L, 0L, 1L, NA_integer_)))

  archived <- links
  archived$event_day <- c(-90L, 120L)
  widened <- rbind(
    archived,
    transform(links[1, , drop = FALSE], event_day = -200L)
  )
  reconciliation <- staged_refit_amendment_reconcile_wide_links_v1(
    archived, widened
  )
  stopifnot(
    reconciliation$archived_rows == 2L,
    reconciliation$widened_rows == 3L,
    reconciliation$overlap_one_to_one_reconciliation == "PASS"
  )

  message("POST_STAGE4A_STAGED_REFIT_AMENDMENT_S1_FIXTURE=PASS")
  quit(status = 0L)
}

code_files <- c(
  "R/post_stage4a_staged_refit_amendment_v1.R",
  "scripts/build_post_stage4a_placebo_links_v1.ps1",
  "scripts/Stage3Phase2SupportAudit.cs",
  "scripts/run_post_stage4a_staged_refit_amendment_v1.R",
  "scripts/run_post_stage4a_staged_refit_amendment_v1.ps1",
  "metadata/post_stage4a_staged_refit_amendment_v1.yml",
  "metadata/post_stage4a_staged_refit_authorization_v1.yml",
  "tests/testthat/test-post-stage4a-staged-refit-amendment-v1.R"
)
dirty <- system2(
  "git",
  c("status", "--porcelain", "--untracked-files=all", "--", code_files),
  stdout = TRUE,
  stderr = TRUE
)
if (length(dirty) && any(nzchar(dirty))) {
  stop(
    paste0(
      "Production is blocked until the amended staged-refit code ",
      "and records are committed"
    ),
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
  stop("Unable to resolve committed amended execution code",
       call. = FALSE)
}
run_post_stage4a_staged_refit_amendment_s1_v1(
  execution_code_commit = execution_code_commit
)
