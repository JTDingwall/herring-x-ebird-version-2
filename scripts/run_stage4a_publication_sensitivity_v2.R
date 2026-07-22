#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[[1L]] else "fixture"
if (!mode %in% c("fixture", "production")) stop("mode must be fixture or production")
pre_execution_spec_commit <- "d44a4a334b3461152557db54c147078e80901de7"
code_files <- c("R/stage4a_publication_sensitivity_v2.R",
                "scripts/run_stage4a_publication_sensitivity_v2.R")
execution_code_commit <- if (mode == "fixture") "UNCOMMITTED_FIXTURE" else {
  system2("git", c("log", "-1", "--format=%H", "--", code_files), stdout = TRUE)
}
if (mode == "production" &&
    (length(execution_code_commit) != 1L || !nzchar(execution_code_commit))) {
  stop("Unable to resolve committed sensitivity execution code")
}
source(file.path("R", "stage4a_core.R"), local = FALSE)
source(file.path("R", "stage4a_production.R"), local = FALSE)
source(file.path("R", "stage4a_publication_sensitivity_v2.R"), local = FALSE)

if (mode == "fixture") {
  n <- 80L
  events <- data.frame(
    analysis_event_token = sprintf("fixture_event_%03d", seq_len(n)),
    location_cluster_token = sprintf("fixture_location_%02d", rep(1:20, each = 4L)),
    region = rep(c("SoG", "WCVI"), each = n / 2L),
    checklist_year = rep(c(2020L, 2021L), each = n / 2L),
    active_reference_class = rep(c("active", "reference", "other", "other"), n / 4L),
    concurrent_links = 1L, stringsAsFactors = FALSE
  )
  events$active_near <- as.integer(events$active_reference_class == "active")
  events$contemporaneous_reference <- as.integer(events$active_reference_class == "reference")
  time_fields <- c("time_early_pre", "time_immediate_pre", "time_spawn_start",
                   "time_early_egg", "time_late_egg", "time_post")
  distance_fields <- c("distance_ring_0_0p5", "distance_ring_0p5_1",
    "distance_ring_1_2", "distance_ring_2_3", "distance_ring_3_4",
    "distance_ring_4_5", "distance_ring_5_10", "distance_ring_10_20")
  for (field in time_fields) events[[field]] <- 0L
  for (field in distance_fields) events[[field]] <- 0L
  events$time_spawn_start <- rep(c(1L, 0L), n / 2L)
  events$distance_ring_0_0p5 <- 1L
  for (model in c("M27_v2", "M28_v2")) {
    transformed <- stage4a_sensitivity_transform_bundle_v2(events, model)
    stopifnot(nrow(transformed$events) == n, transformed$audit$response_fields_read == 0L,
              transformed$audit$bundle_integrity_pass,
              transformed$audit$regional_temporal_support_pass)
  }
  message("STAGE4A_PUBLICATION_SENSITIVITY_FIXTURE=PASS")
  quit(status = 0L)
}

run_stage4a_publication_sensitivity_v2(
  pre_execution_spec_commit = pre_execution_spec_commit,
  execution_code_commit = execution_code_commit
)
message("STAGE4A_PUBLICATION_SENSITIVITY_V2=PASS")
