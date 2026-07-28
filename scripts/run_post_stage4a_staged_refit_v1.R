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

if (mode == "fixture") {
  lookup <- data.frame(
    herring_source_token = c("source_0", "source_1", "source_2", "source_3"),
    event_year = rep(2020L, 4L),
    anchor_shift_days = 0:3,
    used_end_date_fallback = c(FALSE, FALSE, FALSE, TRUE),
    stringsAsFactors = FALSE
  )
  attr(lookup, "raw_rows") <- 4L
  attr(lookup, "raw_start_missing") <- 1L
  attr(lookup, "raw_end_missing") <- 0L
  attr(lookup, "valid_source_records_1988_2025") <- 4L
  attr(lookup, "valid_source_records_using_fallback") <- 1L

  links <- data.frame(
    analysis_event_token = paste0("event_", 0:3),
    herring_source_token = lookup$herring_source_token,
    region = "SoG",
    checklist_year = 2020L,
    event_year = 2020L,
    event_day = c(-15L, -1L, 13L, 29L),
    distance_km = c(1, 6, 2, 8),
    stringsAsFactors = FALSE
  )
  anchored <- staged_refit_reanchor_links_v1(links, lookup)
  stopifnot(
    nrow(anchored) == nrow(links),
    identical(anchored$event_day, c(-15L, 0L, 15L, 32L)),
    identical(
      anchored$event_day - anchored$event_day_parent__,
      lookup$anchor_shift_days
    )
  )

  events <- data.frame(
    analysis_event_token = links$analysis_event_token,
    event_block_token = paste0("block_", 0:3),
    stringsAsFactors = FALSE
  )
  audit <- staged_refit_anchor_audit_v1(
    events, links, anchored, lookup
  )
  requested <- audit$anchor_audit[
    audit$anchor_audit$audit_section == "anchor_shift_requested_bins",
    ,
    drop = FALSE
  ]
  stopifnot(
    identical(
      requested$category,
      c("negative_reversed_interval", "0", "1", "2", "3+")
    ),
    identical(as.integer(requested$value), c(0L, rep(1L, 4L))),
    sum(audit$migration$changed_period) >= 2L
  )

  weights <- staged_refit_s1_contrast_weights_v1()
  primary <- weights$active_minus_pre14
  timing <- weights$spawn_start_minus_early_egg
  stopifnot(
    isTRUE(all.equal(primary[["es_near_spawn_start"]], 4 / 15)),
    isTRUE(all.equal(primary[["es_near_early_egg"]], 11 / 15)),
    isTRUE(all.equal(primary[["es_near_early_pre"]], -0.5)),
    isTRUE(all.equal(primary[["es_near_immediate_pre"]], -0.5)),
    isTRUE(all.equal(
      unname(timing[["es_near_spawn_start"]]), 1
    )),
    isTRUE(all.equal(
      unname(timing[["es_near_early_egg"]]), -1
    ))
  )
  beta_names <- unique(names(primary))
  beta <- stats::setNames(seq_along(beta_names) / 100, beta_names)
  covariance <- diag(seq_along(beta_names) / 1000)
  dimnames(covariance) <- list(beta_names, beta_names)
  wald <- staged_refit_wald_v1(beta, covariance, primary)
  vector <- .post_stage4a_contrast_vector_v1(beta_names, primary)
  stopifnot(
    isTRUE(all.equal(
      unname(wald[["estimate"]]), sum(vector * beta)
    )),
    isTRUE(all.equal(
      unname(wald[["standard_error"]]),
      sqrt(drop(t(vector) %*% covariance %*% vector))
    ))
  )

  formula_text <- paste(deparse(
    post_stage4a_formula_v1("model_response"), width.cutoff = 500L
  ), collapse = " ")
  stopifnot(
    grepl("(1 | event_block_token)", formula_text, fixed = TRUE),
    grepl("(1 | observer_cluster_token)", formula_text, fixed = TRUE),
    grepl("(1 | location_cluster_token)", formula_text, fixed = TRUE),
    length(post_stage4a_exposure_terms_v1()) == 12L,
    nrow(post_stage4a_period_spec_v1()) == 6L
  )

  message("POST_STAGE4A_STAGED_REFIT_S1_FIXTURE=PASS")
  quit(status = 0L)
}

code_files <- c(
  "R/post_stage4a_staged_refit_v1.R",
  "scripts/run_post_stage4a_staged_refit_v1.R",
  "scripts/run_post_stage4a_staged_refit_v1.ps1",
  "scripts/correct_post_stage4a_staged_refit_s1_audit_v1.R",
  "metadata/post_stage4a_staged_refit_spec_v1.yml",
  "metadata/post_stage4a_staged_refit_authorization_v1.yml",
  "tests/testthat/test-post-stage4a-staged-refit-v1.R"
)
dirty <- system2(
  "git",
  c("status", "--porcelain", "--untracked-files=all", "--", code_files),
  stdout = TRUE,
  stderr = TRUE
)
if (length(dirty) && any(nzchar(dirty))) {
  stop(
    "Production is blocked until the staged-refit code and records are committed",
    call. = FALSE
  )
}
execution_code_commit <- system2(
  "git", c("rev-parse", "HEAD"), stdout = TRUE
)
if (length(execution_code_commit) != 1L ||
    !grepl("^[0-9a-f]{40}$", execution_code_commit)) {
  stop("Unable to resolve committed staged-refit execution code",
       call. = FALSE)
}
run_post_stage4a_staged_refit_s1_v1(
  execution_code_commit = execution_code_commit
)
