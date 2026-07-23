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

if (mode == "fixture") {
  periods <- post_stage4a_period_spec_v1()
  stopifnot(
    identical(periods$minimum_day, c(-28L, -14L, -7L, 0L, 4L, 15L)),
    identical(periods$maximum_day, c(-15L, -8L, -1L, 3L, 14L, 28L))
  )
  events <- data.frame(
    analysis_event_token = sprintf("fixture_%02d", 1:12),
    event_block_token = sprintf("block_%02d", 1:12),
    observer_cluster_token = sprintf("observer_%02d", 1:12),
    location_cluster_token = sprintf("location_%02d", 1:12),
    region = "SoG",
    checklist_year = 2020L,
    concurrent_links = c(2L, rep(1L, 11L)),
    stringsAsFactors = FALSE
  )
  boundary_days <- c(
    -7L, 4L, -28L, -15L, -14L, -8L, -1L, 0L, 3L, 14L, 15L, 28L, 29L
  )
  boundary_distances <- c(
    4.9, 7, 4.9, 5, 4.9, 5, 4.9, 5, 4.9, 5, 4.9, 20, 4.9
  )
  links <- data.frame(
    analysis_event_token = c("fixture_01", "fixture_01",
                             sprintf("fixture_%02d", 2:12)),
    region = "SoG",
    checklist_year = 2020L,
    event_day = boundary_days,
    distance_km = boundary_distances,
    stringsAsFactors = FALSE
  )
  joint <- post_stage4a_add_joint_exposure_v1(events, links)
  stopifnot(
    nrow(joint$events) == nrow(events),
    !anyDuplicated(joint$events$analysis_event_token),
    joint$events$es_near_immediate_pre[[1L]] == 1L,
    joint$events$es_reference_early_egg[[1L]] == 1L,
    sum(joint$events[post_stage4a_exposure_terms_v1()]) == 12L
  )
  names_for_contrast <- c("(Intercept)", post_stage4a_exposure_terms_v1())
  definitions <- post_stage4a_contrast_definitions_v1(names_for_contrast)
  active <- definitions[
    vapply(definitions, function(x) x$contrast == "did_active_0_14_day",
           logical(1L))
  ][[1L]]
  pre14 <- definitions[
    vapply(definitions, function(x) x$contrast == "did_pre_14_day",
           logical(1L))
  ][[1L]]
  stopifnot(
    abs(sum(active$vector)) < 1e-12,
    abs(sum(pre14$vector)) < 1e-12,
    isTRUE(all.equal(
      active$vector[["es_near_spawn_start"]], 4 / 15
    )),
    isTRUE(all.equal(
      active$vector[["es_near_early_egg"]], 11 / 15
    )),
    isTRUE(all.equal(
      pre14$vector[["es_near_early_pre"]], 0.5
    )),
    isTRUE(all.equal(
      pre14$vector[["es_near_immediate_pre"]], 0.5
    ))
  )
  message("POST_STAGE4A_SOG_EVENT_STUDY_FIXTURE=PASS")
  quit(status = 0L)
}

code_files <- c(
  ".gitignore",
  "R/post_stage4a_sog_event_study_v1.R",
  "scripts/run_post_stage4a_sog_event_study_v1.R",
  "scripts/run_post_stage4a_sog_event_study_v1.ps1",
  "metadata/post_stage4a_sog_event_study_spec_v1.yml",
  "metadata/post_stage4a_sog_event_study_authorization_v1.yml",
  "metadata/post_stage4a_sog_event_study_species_roles_v1.csv",
  "docs/15_POST_STAGE4A_SOG_EVENT_STUDY.md",
  "tests/testthat/helper-load.R",
  "tests/testthat/test-post-stage4a-sog-event-study-v1.R"
)
dirty <- system2(
  "git",
  c("status", "--porcelain", "--untracked-files=all", "--", code_files),
  stdout = TRUE,
  stderr = TRUE
)
if (length(dirty) && any(nzchar(dirty))) {
  stop(
    "Production is blocked until the event-study code and specification are committed",
    call. = FALSE
  )
}
execution_code_commit <- system2(
  "git", c("rev-parse", "HEAD"), stdout = TRUE
)
if (length(execution_code_commit) != 1L ||
    !grepl("^[0-9a-f]{40}$", execution_code_commit)) {
  stop("Unable to resolve the committed execution code", call. = FALSE)
}
run_post_stage4a_sog_event_study_v1(
  execution_code_commit = execution_code_commit
)
