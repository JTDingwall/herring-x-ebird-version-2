#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[[1L]] else "fixture"
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
if (!dir.exists(analysis_library)) {
  stop(
    "The versioned analysis library is unavailable. Install pbkrtest and ",
    "lmerTest into ", analysis_library,
    " only; never into the frozen renv library.",
    call. = FALSE
  )
}
.libPaths(c(
  normalizePath(analysis_library, winslash = "/"),
  if (dir.exists(frozen_library)) {
    normalizePath(frozen_library, winslash = "/")
  } else {
    character()
  },
  .libPaths()
))

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
source(
  file.path("R", "post_stage4a_stage2_block_slope_diagnostic_v1.R"),
  local = FALSE
)
source(file.path("R", "post_stage4a_blockaware_v1.R"), local = FALSE)

if (mode == "fixture") {
  spec <- blockaware_spec_gate_v1()
  stopifnot(
    identical(spec$multiplicity$family_size, 49L),
    identical(spec$bootstrap$decision, "not_run")
  )
  manifest <- blockaware_library_gate_v1()
  stopifnot(
    "pbkrtest" %in% manifest$package,
    "lmerTest" %in% manifest$package,
    any(
      manifest$package == "pbkrtest" &
        manifest$library == "versioned_analysis_library"
    ),
    !any(
      manifest$package == "pbkrtest" &
        manifest$library == "frozen_renv_project_library"
    )
  )
  direction <- stage2_block_slope_direction_v1()
  stopifnot(abs(sum(direction$contrast * direction$direction) - 1) < 1e-12)
  formula <- stage2_block_slope_formula_v1("model_response")
  stopifnot(grepl(
    "block_active_minus_pre14 | event_block_token",
    paste(deparse(formula), collapse = " "),
    fixed = TRUE
  ))
  stage2 <- blockaware_stage2_baseline_v1()
  reporting <- stage2[stage2$outcome == "checklist_reporting", ]
  counts <- stage2[
    stage2$outcome == "conditional_positive_numeric_count",
  ]
  stopifnot(
    sum(reporting$significant_bh_fixed49 & reporting$estimate > 0) == 13L,
    sum(reporting$significant_bh_fixed49 & reporting$estimate < 0) == 2L,
    setequal(
      reporting$species[
        reporting$significant_bh_fixed49 & reporting$estimate < 0
      ],
      c("Bufflehead", "Common Raven")
    ),
    sum(counts$significant_bh_fixed49) == 19L
  )
  bootstrap <- blockaware_bootstrap_record_v1()
  stopifnot(
    identical(bootstrap$decision, "not_run"),
    bootstrap$observer_clusters_crossing_more_than_one_block == 2495,
    bootstrap$location_clusters_crossing_more_than_one_block == 4631
  )
  message("BLOCKAWARE_FIXTURE=PASS")
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

workers <- suppressWarnings(as.integer(Sys.getenv(
  "POST_STAGE4A_BLOCKAWARE_WORKERS", unset = ""
)))
if (length(workers) != 1L || is.na(workers) || workers < 1L) workers <- NULL
budget <- suppressWarnings(as.numeric(Sys.getenv(
  "POST_STAGE4A_BLOCKAWARE_KR_BUDGET_GB", unset = "12"
)))
if (length(budget) != 1L || !is.finite(budget) || budget <= 0) budget <- 12

run_post_stage4a_blockaware_v1(
  execution_code_commit = execution_code_commit,
  workers = workers,
  kenward_roger_budget_gb = budget
)
