#!/usr/bin/env Rscript

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

root <- file.path(
  "outputs", "post_stage4a_staged_refit_amendment_v1"
)
output_dir <- file.path(root, "s1_anchor_amendment")
read_output <- function(name) {
  utils::read.csv(
    file.path(output_dir, paste0(name, ".csv")),
    stringsAsFactors = FALSE
  )
}

manifest <- utils::read.csv(
  file.path(root, "output_hash_manifest_v1.csv"),
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(manifest) == 17L,
  !anyDuplicated(manifest$file),
  all(file.exists(manifest$file)),
  identical(
    unname(vapply(
      manifest$file, .post_stage4a_sha256_v1, character(1L)
    )),
    unname(manifest$sha256)
  )
)
staged_refit_privacy_column_gate_v1(manifest$file)
staged_refit_amendment_verify_stage1_manifest_v1()

execution <- yaml::read_yaml(
  file.path(root, "execution_record_v1.yml")
)
stopifnot(
  identical(
    execution$execution_code_commit,
    "98d979cc1ebb3484b412df415d80bc75a040c97b"
  ),
  identical(execution$stage2_started, FALSE),
  identical(execution$historical_stage1_outputs_modified, FALSE),
  identical(execution$historical_parent_outputs_modified, FALSE),
  identical(execution$privacy_column_gate, "PASS")
)
historical_hashes <- unlist(
  execution$historical_stage1_output_hashes
)
current_hashes <- staged_refit_amendment_snapshot_v1()
stopifnot(
  setequal(names(historical_hashes), names(current_hashes)),
  identical(
    unname(historical_hashes[names(current_hashes)]),
    unname(current_hashes)
  )
)

effort <- read_output("effort_negative_control_outcomes")
stopifnot(
  nrow(effort) == 3L,
  setequal(
    effort$outcome,
    staged_refit_amendment_effort_spec_v1()$outcome
  ),
  isTRUE(all.equal(
    effort$q_value_bh_3_outcomes,
    stats::p.adjust(effort$p_value, method = "BH")
  ))
)

placebo <- read_output("placebo_estimates_49x2")
placebo_diagnostics <- read_output("placebo_diagnostics")
placebo_tallies <- read_output("placebo_tallies")
placebo_support <- read_output("placebo_support")
stopifnot(
  nrow(placebo) == 392L,
  nrow(placebo_diagnostics) == 392L,
  nrow(placebo_tallies) == 8L,
  nrow(placebo_support) == 4L,
  setequal(placebo$offset_days, c(-180L, -90L, 90L, 180L)),
  all(table(placebo$offset_days) == 98L),
  all(table(placebo_diagnostics$offset_days) == 98L),
  all(placebo_support$model_rows == 217200L)
)
for (offset in unique(placebo$offset_days)) {
  for (outcome in unique(placebo$outcome)) {
    z <- placebo[
      placebo$offset_days == offset &
        placebo$outcome == outcome,
      ,
      drop = FALSE
    ]
    index <- is.finite(z$p_value)
    stopifnot(
      sum(index) <= 49L,
      isTRUE(all.equal(
        z$q_value[index],
        stats::p.adjust(z$p_value[index], method = "BH")
      ))
    )
  }
}
recomputed_tallies <- do.call(rbind, lapply(
  split(
    placebo,
    list(placebo$offset_days, placebo$outcome),
    drop = TRUE
  ),
  function(z) {
    data.frame(
      offset_days = z$offset_days[[1L]],
      outcome = z$outcome[[1L]],
      positive = sum(
        z$estimate > 0 & z$q_value < 0.05, na.rm = TRUE
      ),
      negative = sum(
        z$estimate < 0 & z$q_value < 0.05, na.rm = TRUE
      ),
      estimable = sum(
        is.finite(z$estimate) &
          is.finite(z$standard_error)
      ),
      stringsAsFactors = FALSE
    )
  }
))
tally_index <- match(
  paste(placebo_tallies$offset_days, placebo_tallies$outcome),
  paste(
    recomputed_tallies$offset_days,
    recomputed_tallies$outcome
  )
)
stopifnot(
  !anyNA(tally_index),
  identical(
    as.integer(placebo_tallies$positive_bh_q_lt_0_05),
    as.integer(recomputed_tallies$positive[tally_index])
  ),
  identical(
    as.integer(placebo_tallies$negative_bh_q_lt_0_05),
    as.integer(recomputed_tallies$negative[tally_index])
  ),
  identical(
    as.integer(placebo_tallies$estimable_species),
    as.integer(recomputed_tallies$estimable[tally_index])
  )
)

exclusion <- read_output(
  "long_span_exclusion_estimates_49x2"
)
exclusion_delta <- read_output("long_span_exclusion_delta")
stopifnot(
  nrow(exclusion) == 98L,
  nrow(exclusion_delta) == 98L,
  !anyDuplicated(paste(
    exclusion$analysis_taxon_id,
    exclusion$outcome,
    sep = "\r"
  )),
  sum(exclusion_delta$changed_direction, na.rm = TRUE) == 0L,
  sum(
    exclusion_delta$changed_bh_significance,
    na.rm = TRUE
  ) == 0L
)

terrestrial <- read_output(
  "terrestrial_displacement_by_anchor"
)
historical <- utils::read.csv(
  file.path(
    "outputs", "post_stage4a_staged_refit_v1",
    "negative_controls_all_stages.csv"
  ),
  stringsAsFactors = FALSE
)
historical <- historical[
  historical$comparison == "active_minus_pre14",
  ,
  drop = FALSE
]
copied <- terrestrial[
  terrestrial$analysis_variant == "real_start_anchor",
  ,
  drop = FALSE
]
comparison_columns <- c(
  "species", "outcome", "comparison", "estimate",
  "standard_error", "conf_low", "conf_high", "ratio",
  "ratio_conf_low", "ratio_conf_high", "p_value", "q_value",
  "n", "status"
)
historical <- historical[
  order(historical$species, historical$outcome),
  comparison_columns,
  drop = FALSE
]
copied <- copied[
  order(copied$species, copied$outcome),
  comparison_columns,
  drop = FALSE
]
rownames(historical) <- NULL
rownames(copied) <- NULL
stopifnot(
  identical(historical, copied),
  nrow(terrestrial) == 12L,
  all(
    terrestrial$analysis_role ==
      "terrestrial_attention_displacement"
  )
)

pool <- read_output("pooled_terrestrial_displacement")
stopifnot(
  nrow(pool) == 3L,
  all(pool$outcome == "checklist_reporting"),
  all(pool$status == "completed")
)

long_event <- read_output("long_span_event_audit")
stopifnot(
  nrow(long_event) == 1L,
  long_event$recorded_span_days == 72L,
  long_event$anchor_shift_days == 36L,
  long_event$primary_20km_link_count == 118L,
  long_event$start_anchor_window_link_count == 45L
)

wide <- read_output("widened_link_reconciliation")
stopifnot(
  wide$overlap_one_to_one_reconciliation == "PASS",
  wide$archived_rows == wide$overlap_rows
)

message("AMENDED_STAGE1_INDEPENDENT_QA=PASS")
