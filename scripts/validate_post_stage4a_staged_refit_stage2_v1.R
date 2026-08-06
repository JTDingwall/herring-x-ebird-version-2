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
source(
  file.path("R", "post_stage4a_staged_refit_stage2_v1.R"),
  local = FALSE
)

root <- "outputs/post_stage4a_staged_refit_stage2_v1"
stage <- file.path(root, "s2_detectability")
required <- c(
  "coverage_start_time.csv",
  "estimates_49x2.csv",
  "delta_vs_s1.csv",
  "guild_timing.csv",
  "distance_bands_3species.csv",
  "terrestrial_displacement_by_species.csv",
  "pooled_terrestrial_displacement.csv",
  "effort_negative_control_outcomes.csv",
  "placebo_p90_estimates_49x2.csv",
  "placebo_p90_tallies.csv",
  "placebo_p90_delta_vs_s1.csv",
  "required_four_results_summary.csv",
  "model_diagnostics.csv",
  "terrestrial_diagnostics.csv",
  "effort_diagnostics.csv",
  "pooled_terrestrial_diagnostics.csv",
  "distance_diagnostics.csv"
)
paths <- file.path(stage, required)
stopifnot(
  all(file.exists(paths)),
  file.exists(file.path(root, "execution_record_v1.yml")),
  file.exists(file.path(root, "output_hash_manifest_v1.csv"))
)
staged_refit_s2_gate_v1()
staged_refit_s2_verify_manifest_v1(root)
staged_refit_s2_verify_manifest_v1(
  "outputs/post_stage4a_staged_refit_v1"
)
staged_refit_s2_verify_manifest_v1(
  "outputs/post_stage4a_staged_refit_amendment_v1"
)
staged_refit_privacy_column_gate_v1(paths)

coverage <- utils::read.csv(paths[[1L]], stringsAsFactors = FALSE)
primary <- utils::read.csv(paths[[2L]], stringsAsFactors = FALSE)
delta <- utils::read.csv(paths[[3L]], stringsAsFactors = FALSE)
guild <- utils::read.csv(paths[[4L]], stringsAsFactors = FALSE)
distance <- utils::read.csv(paths[[5L]], stringsAsFactors = FALSE)
terrestrial <- utils::read.csv(paths[[6L]], stringsAsFactors = FALSE)
pool <- utils::read.csv(paths[[7L]], stringsAsFactors = FALSE)
effort <- utils::read.csv(paths[[8L]], stringsAsFactors = FALSE)
placebo <- utils::read.csv(paths[[9L]], stringsAsFactors = FALSE)
tallies <- utils::read.csv(paths[[10L]], stringsAsFactors = FALSE)
placebo_delta <- utils::read.csv(paths[[11L]], stringsAsFactors = FALSE)
summary <- utils::read.csv(paths[[12L]], stringsAsFactors = FALSE)
execution <- yaml::read_yaml(file.path(root, "execution_record_v1.yml"))

complete_n <- coverage$n[
  coverage$metric == "stage2_covariates_complete" &
    coverage$category == "overall"
]
total_n <- coverage$n[
  coverage$metric == "eligible_checklists" &
    coverage$category == "overall"
]
stopifnot(
  length(total_n) == 1L,
  length(complete_n) == 1L,
  total_n == 217200L,
  complete_n > 0L,
  complete_n <= total_n,
  nrow(primary) == 98L,
  nrow(delta) == 98L,
  nrow(guild) == 14L,
  nrow(distance) == 3L * 2L * 13L * 6L,
  nrow(terrestrial) == 4L,
  nrow(pool) == 1L,
  nrow(effort) == 3L,
  nrow(placebo) == 98L,
  nrow(tallies) == 2L,
  nrow(placebo_delta) == 98L,
  nrow(summary) == 6L,
  !anyDuplicated(paste(
    primary$analysis_taxon_id, primary$outcome, sep = "\r"
  )),
  !anyDuplicated(paste(
    placebo$analysis_taxon_id, placebo$outcome, sep = "\r"
  )),
  !anyDuplicated(summary$requested_result)
)

for (outcome in unique(primary$outcome)) {
  index <- which(
    primary$outcome == outcome & is.finite(primary$p_value)
  )
  stopifnot(isTRUE(all.equal(
    primary$q_value[index],
    stats::p.adjust(primary$p_value[index], method = "BH"),
    tolerance = 1e-12
  )))
  pindex <- which(
    placebo$outcome == outcome & is.finite(placebo$p_value)
  )
  stopifnot(isTRUE(all.equal(
    placebo$q_value[pindex],
    stats::p.adjust(placebo$p_value[pindex], method = "BH"),
    tolerance = 1e-12
  )))
}

finite_primary <- is.finite(primary$estimate)
finite_placebo <- is.finite(placebo$estimate)
stopifnot(
  isTRUE(all.equal(
    primary$ratio[finite_primary],
    exp(primary$estimate[finite_primary]),
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    placebo$ratio[finite_placebo],
    exp(placebo$estimate[finite_placebo]),
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    effort$multiplicative_effect[
      effort$effect_scale == "log_ratio"
    ],
    exp(effort$estimate[effort$effect_scale == "log_ratio"]),
    tolerance = 1e-12
  ))
)

recomputed_tallies <- staged_refit_amendment_tally_v1(
  placebo, 90L, real_reporting = 14L, real_count = 19L
)
recomputed_tallies <- recomputed_tallies[
  match(tallies$outcome, recomputed_tallies$outcome), , drop = FALSE
]
stopifnot(
  identical(
    as.integer(tallies$positive_bh_q_lt_0_05),
    as.integer(recomputed_tallies$positive_bh_q_lt_0_05)
  ),
  identical(
    as.integer(tallies$negative_bh_q_lt_0_05),
    as.integer(recomputed_tallies$negative_bh_q_lt_0_05)
  )
)

expected_summary <- c(
  "terrestrial_displacement_american_robin",
  "terrestrial_displacement_chestnut-backed_chickadee",
  "terrestrial_displacement_pooled",
  "reporting_guild_timing_omnibus",
  "duration_negative_control",
  "placebo_p90_positive_reporting_hit"
)
stopifnot(
  setequal(summary$requested_result, expected_summary),
  all(summary$change_classification %in%
      c("weakens", "holds", "strengthens", "not_classifiable")),
  all(summary$leading_alternative_explanation ==
      "unmodelled_seasonal_reporting_trend"),
  identical(execution$stage3_started, FALSE),
  identical(
    execution$gate,
    "PASS_PENDING_HUMAN_STAGE2_REVIEW_STOP_BEFORE_STAGE3"
  ),
  execution$population$records_2026_plus_read == 0L,
  execution$population$stage1_eligible_checklists == 217200L,
  execution$population$stage2_complete_checklists == complete_n,
  execution$historical_stage1_outputs_modified == FALSE,
  execution$historical_amendment_outputs_modified == FALSE,
  execution$historical_parent_outputs_modified == FALSE,
  execution$privacy_column_gate == "PASS"
)

cat("POST_STAGE4A_STAGED_REFIT_STAGE2_VALIDATION=PASS\n")
