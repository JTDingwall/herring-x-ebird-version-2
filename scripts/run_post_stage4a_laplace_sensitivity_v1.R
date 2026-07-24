#!/usr/bin/env Rscript

## Laplace (nAGQ = 1) reporting sensitivity runner.
##
## Usage:
##   Rscript scripts/run_post_stage4a_laplace_sensitivity_v1.R fixture
##   Rscript scripts/run_post_stage4a_laplace_sensitivity_v1.R production [scope]
##
## scope is "all_core" (default, 49 core species) or "adjusted_significant"
## (only the reporting species whose primary active-window contrast survives
## BH adjustment). Prefer all_core: a reduced scope shrinks the BH families,
## so its q-values are not comparable with the 49-species primary families.
##
## Production requires POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED to carry the
## exact acknowledgement, and the four protected inputs to be present and
## hash-matching. This script never writes to the frozen v1 release.

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[[1L]] else "fixture"
scope <- if (length(args) > 1L) args[[2L]] else "all_core"
if (!mode %in% c("fixture", "production")) {
  stop("mode must be fixture or production", call. = FALSE)
}
if (!scope %in% c("all_core", "adjusted_significant")) {
  stop("scope must be all_core or adjusted_significant", call. = FALSE)
}

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
source(file.path("R", "stage4a_core.R"), local = FALSE)
source(file.path("R", "stage4a_production.R"), local = FALSE)
source(file.path("R", "post_stage4a_sog_event_study_v1.R"), local = FALSE)
source(
  file.path("R", "post_stage4a_sog_event_study_laplace_sensitivity_v1.R"),
  local = FALSE
)

if (mode == "fixture") {
  ## The frozen release must never be a write target.
  stopifnot(
    inherits(try(
      .post_stage4a_guard_frozen_outputs_v1(
        "outputs/post_stage4a_sog_event_study_v1"
      ),
      silent = TRUE
    ), "try-error"),
    isTRUE(.post_stage4a_guard_frozen_outputs_v1(
      "outputs/post_stage4a_sog_event_study_laplace_v1"
    ))
  )
  ## lme4 cannot take three crossed random intercepts above Laplace.
  stopifnot(
    inherits(try(
      post_stage4a_fit_one_v1(
        data.frame(), "atx", "Bird", "core_species", "detection",
        tempfile(), "signature", NULL, nAGQ = 2L
      ),
      silent = TRUE
    ), "try-error")
  )
  ## The comparison baseline must still match its recorded hash.
  baseline <- try(.post_stage4a_laplace_frozen_effects_v1(), silent = TRUE)
  if (inherits(baseline, "try-error")) {
    stop("Frozen baseline unavailable or hash-mismatched: ",
         conditionMessage(attr(baseline, "condition")), call. = FALSE)
  }
  stopifnot(
    nrow(baseline) > 0L,
    "did_active_0_14_day" %in% baseline$contrast
  )
  message("POST_STAGE4A_LAPLACE_SENSITIVITY_FIXTURE=PASS")
  quit(status = 0L)
}

code_files <- c(
  "R/post_stage4a_sog_event_study_v1.R",
  "R/post_stage4a_sog_event_study_laplace_sensitivity_v1.R",
  "scripts/run_post_stage4a_sog_event_study_v1.R",
  "scripts/run_post_stage4a_laplace_sensitivity_v1.R",
  "metadata/post_stage4a_sog_event_study_spec_v1.yml",
  "metadata/post_stage4a_sog_event_study_species_roles_v1.csv"
)
dirty <- system2(
  "git",
  c("status", "--porcelain", "--untracked-files=all", "--", code_files),
  stdout = TRUE, stderr = TRUE
)
if (length(dirty) && any(nzchar(dirty))) {
  stop("Production is blocked until the sensitivity code is committed",
       call. = FALSE)
}
execution_code_commit <- system2("git", c("rev-parse", "HEAD"), stdout = TRUE)
if (length(execution_code_commit) != 1L ||
    !grepl("^[0-9a-f]{40}$", execution_code_commit)) {
  stop("Unable to resolve the committed execution code", call. = FALSE)
}

result <- run_post_stage4a_laplace_reporting_sensitivity_v1(
  execution_code_commit = execution_code_commit,
  scope = scope
)

if (nrow(result$overturned)) {
  message(
    "REVIEW REQUIRED: ", nrow(result$overturned),
    " headline reporting result(s) changed direction or adjusted-significance ",
    "under Laplace."
  )
} else {
  message(
    "All headline reporting results preserved direction and ",
    "adjusted-significance under Laplace."
  )
}
