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
source(
  file.path("R", "post_stage4a_stage2_block_slope_diagnostic_v1.R"),
  local = FALSE
)

if (mode == "fixture") {
  record <- stage2_block_slope_gate_v1()
  stopifnot(
    identical(
      record$authorized_scope$species_selection,
      "top_10_descending_active_minus_pre14_estimate"
    )
  )
  direction <- stage2_block_slope_direction_v1()
  stopifnot(
    abs(sum(direction$contrast * direction$direction) - 1) < 1e-12
  )
  formula <- stage2_block_slope_formula_v1()
  stopifnot(
    grepl(
      "block_active_minus_pre14 | event_block_token",
      paste(deparse(formula), collapse = " "),
      fixed = TRUE
    )
  )
  selected <- stage2_block_slope_select_top_ten_v1()
  stopifnot(
    nrow(selected) == 10L,
    identical(selected$effect_rank, seq_len(10L)),
    all(diff(selected$estimate) <= 0)
  )
  message("STAGE2_BLOCK_SLOPE_FIXTURE=PASS")
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
execution_code_commit <- system2(
  "git", c("rev-parse", "HEAD"), stdout = TRUE
)
if (
  length(execution_code_commit) != 1L ||
    !grepl("^[0-9a-f]{40}$", execution_code_commit)
) {
  stop("Unable to resolve the execution commit", call. = FALSE)
}
run_post_stage4a_stage2_block_slope_diagnostic_v1(
  execution_code_commit = execution_code_commit
)

