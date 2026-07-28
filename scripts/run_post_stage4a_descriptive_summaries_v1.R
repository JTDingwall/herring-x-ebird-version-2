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
source(file.path("R", "post_stage4a_staged_refit_v1.R"), local = FALSE)
source(
  file.path("R", "post_stage4a_descriptive_summaries_v1.R"),
  local = FALSE
)

if (mode == "fixture") {
  post_stage4a_descriptive_fixture_v1()
  quit(status = 0L)
}

authorization <- staged_refit_authorization_gate_v1()
expected_acknowledgement <-
  authorization$environment_acknowledgement$value
if (!identical(
    Sys.getenv("POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED"),
    expected_acknowledgement
)) {
  stop(
    "Production requires the exact author-set current-shell acknowledgement",
    call. = FALSE
  )
}

code_files <- c(
  "R/post_stage4a_descriptive_summaries_v1.R",
  "scripts/run_post_stage4a_descriptive_summaries_v1.R",
  "scripts/run_post_stage4a_descriptive_summaries_v1.ps1",
  "scripts/validate_post_stage4a_descriptive_summaries_v1.R",
  "metadata/post_stage4a_descriptive_summaries_spec_v1.yml"
)
dirty <- system2(
  "git",
  c("status", "--porcelain", "--untracked-files=all", "--", code_files),
  stdout = TRUE,
  stderr = TRUE
)
if (length(dirty) && any(nzchar(dirty))) {
  stop(
    "Production is blocked until descriptive code and specification are committed",
    call. = FALSE
  )
}
execution_code_commit <- system2(
  "git", c("rev-parse", "HEAD"), stdout = TRUE
)
if (length(execution_code_commit) != 1L ||
    !grepl("^[0-9a-f]{40}$", execution_code_commit)) {
  stop("Unable to resolve committed descriptive execution code",
       call. = FALSE)
}

run_post_stage4a_descriptive_summaries_v1(
  execution_code_commit = execution_code_commit
)
