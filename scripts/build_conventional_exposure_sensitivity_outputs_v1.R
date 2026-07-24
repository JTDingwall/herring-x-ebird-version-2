#!/usr/bin/env Rscript

# Build the minimal privacy-safe comparison and component-status tables from
# the selected nearest-event sensitivity. No model is fitted here.

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
library_path <- Sys.getenv("EDITORIAL_R_LIBRARY", "")
if (nzchar(library_path)) .libPaths(c(library_path, .libPaths()))

source(file.path("R", "editorial_requested_analysis_v1.R"), local = FALSE)

output_dir <- "outputs/conventional_exposure_sensitivity_v1"
selection <- utils::read.csv(
  file.path(output_dir, "design_selection.csv"),
  stringsAsFactors = FALSE
)
selected <- selection[selection$selected, , drop = FALSE]
if (nrow(selected) != 1L ||
    selected$candidate[[1L]] != "nearest_event" ||
    selected$models_fitted_during_selection[[1L]] != 0L) {
  stop("CONVENTIONAL_REPORT_SELECTION_GATE: invalid prerecord",
       call. = FALSE)
}

comparisons <- utils::read.csv(
  file.path(output_dir, "sensitivity_comparisons.csv"),
  stringsAsFactors = FALSE
)
sensitivity_diagnostics <- utils::read.csv(
  file.path(output_dir, "sensitivity_diagnostics.csv"),
  stringsAsFactors = FALSE
)
primary_diagnostics <- utils::read.csv(
  file.path(
    "outputs", "editorial_requested_analysis_v1", "model_diagnostics.csv"
  ),
  stringsAsFactors = FALSE
)

if (nrow(comparisons) != 196L ||
    nrow(sensitivity_diagnostics) != 98L ||
    nrow(primary_diagnostics) != 147L) {
  stop("CONVENTIONAL_REPORT_ROW_GATE: unexpected input row count",
       call. = FALSE)
}
if (!all(comparisons$sensitivity_id == "nearest_event") ||
    !all(sensitivity_diagnostics$sensitivity_id == "nearest_event")) {
  stop("CONVENTIONAL_REPORT_DESIGN_GATE: nonselected sensitivity present",
       call. = FALSE)
}
comparison_key_all <- paste(
  comparisons$analysis_taxon_id,
  comparisons$outcome,
  comparisons$comparison,
  sep = "|"
)
sensitivity_diagnostic_key <- paste(
  sensitivity_diagnostics$analysis_taxon_id,
  sensitivity_diagnostics$outcome,
  sep = "|"
)
primary_diagnostic_key <- paste(
  primary_diagnostics$analysis_taxon_id,
  primary_diagnostics$outcome,
  sep = "|"
)
comparison_component_key <- unique(paste(
  comparisons$analysis_taxon_id,
  comparisons$outcome,
  sep = "|"
))
if (anyDuplicated(comparison_key_all) ||
    anyDuplicated(sensitivity_diagnostic_key) ||
    anyDuplicated(primary_diagnostic_key) ||
    !setequal(comparison_component_key, sensitivity_diagnostic_key) ||
    !all(sensitivity_diagnostic_key %in% primary_diagnostic_key)) {
  stop(
    paste0(
      "CONVENTIONAL_JOIN_CARDINALITY_GATE: comparisons-to-sensitivity ",
      "diagnostics must be many-to-one across contrasts and one-to-one ",
      "after collapsing to species-outcome; sensitivity diagnostics must ",
      "map many-to-one into the primary diagnostic family"
    ),
    call. = FALSE
  )
}

results <- comparisons[
  comparisons$comparison == "active_minus_pre14",
  , drop = FALSE
]
result_key <- paste(results$analysis_taxon_id, results$outcome, sep = "|")
if (nrow(results) != 98L || anyDuplicated(result_key)) {
  stop("CONVENTIONAL_RESULT_KEY_GATE: expected 49 x 2 A14 rows",
       call. = FALSE)
}

direction <- function(x) {
  ifelse(
    !is.finite(x), NA_character_,
    ifelse(x > 0, "positive", ifelse(x < 0, "negative", "zero"))
  )
}
excludes_zero <- function(low, high) {
  is.finite(low) & is.finite(high) & (low > 0 | high < 0)
}
interval_overlap <- function(low1, high1, low2, high2) {
  ifelse(
    is.finite(low1) & is.finite(high1) &
      is.finite(low2) & is.finite(high2),
    pmax(low1, low2) <= pmin(high1, high2),
    NA
  )
}

results$primary_direction <- direction(results$primary_estimate)
results$sensitivity_direction <- direction(results$estimate)
results$sign_agreement <- ifelse(
  is.finite(results$primary_estimate) & is.finite(results$estimate),
  sign(results$primary_estimate) == sign(results$estimate),
  NA
)
results$primary_interval_excludes_zero <- excludes_zero(
  results$primary_conf_low, results$primary_conf_high
)
results$sensitivity_interval_excludes_zero <- excludes_zero(
  results$conf_low, results$conf_high
)
results$confidence_intervals_overlap <- interval_overlap(
  results$primary_conf_low, results$primary_conf_high,
  results$conf_low, results$conf_high
)
results$bh_threshold_crossing <- ifelse(
  is.finite(results$primary_q_value) &
    is.finite(results$sensitivity_q_value),
  (results$primary_q_value < 0.05) !=
    (results$sensitivity_q_value < 0.05),
  NA
)

assessment <- rep("same_direction__compatible_magnitude", nrow(results))
not_assessable <- !is.finite(results$primary_estimate) |
  !is.finite(results$estimate)
reversal <- !not_assessable & !results$sign_agreement
reversal_directional <- reversal &
  (results$primary_interval_excludes_zero |
     results$sensitivity_interval_excludes_zero)
reversal_uncertain <- reversal & !reversal_directional
same_direction_nonoverlap <- !not_assessable &
  results$sign_agreement &
  !is.na(results$confidence_intervals_overlap) &
  !results$confidence_intervals_overlap
assessment[not_assessable] <- "not_assessable__failed_or_unsupported_component"
assessment[reversal_uncertain] <-
  "direction_reversal__both_intervals_include_zero"
assessment[reversal_directional] <-
  "material_direction_reversal__at_least_one_interval_excludes_zero"
assessment[same_direction_nonoverlap] <-
  paste0(
    "same_direction__nonoverlapping_intervals__",
    "encoding_scales_not_directly_comparable"
  )
results$interpretation_change_class <- assessment
results$interpretation_changes_materially <-
  assessment ==
    "material_direction_reversal__at_least_one_interval_excludes_zero"
results$interpretation_rule <- paste0(
  "BH threshold crossing or same-direction interval nonoverlap alone is not ",
  "material because exposure units differ; material means a sign reversal ",
  "with at least one 95% interval excluding zero"
)

keep <- c(
  "analysis_taxon_id", "species", "outcome", "comparison",
  "primary_estimate", "primary_standard_error",
  "primary_conf_low", "primary_conf_high", "primary_ratio",
  "primary_ratio_conf_low", "primary_ratio_conf_high", "primary_q_value",
  "primary_status", "primary_direction",
  "estimate", "standard_error", "conf_low", "conf_high", "ratio",
  "ratio_conf_low", "ratio_conf_high", "sensitivity_q_value", "status",
  "sensitivity_direction", "sign_agreement",
  "estimate_difference_from_primary",
  "primary_interval_excludes_zero",
  "sensitivity_interval_excludes_zero",
  "confidence_intervals_overlap", "bh_threshold_crossing",
  "interpretation_change_class", "interpretation_changes_materially",
  "interpretation_rule", "model_n", "model_event_blocks",
  "model_observer_clusters", "model_generalized_locations",
  "retained_checklists", "retained_fraction", "changed_component"
)
results <- results[, keep, drop = FALSE]
names(results)[names(results) == "estimate"] <- "sensitivity_estimate"
names(results)[names(results) == "standard_error"] <-
  "sensitivity_standard_error"
names(results)[names(results) == "conf_low"] <- "sensitivity_conf_low"
names(results)[names(results) == "conf_high"] <- "sensitivity_conf_high"
names(results)[names(results) == "ratio"] <- "sensitivity_ratio"
names(results)[names(results) == "ratio_conf_low"] <-
  "sensitivity_ratio_conf_low"
names(results)[names(results) == "ratio_conf_high"] <-
  "sensitivity_ratio_conf_high"
names(results)[names(results) == "status"] <- "sensitivity_status"

result_path <- file.path(
  output_dir, "conventional_exposure_sensitivity_results.csv"
)
editorial_write_csv_v1(results, result_path)

model_formula <- function(outcome) {
  response_label <- ifelse(
    outcome == "checklist_reporting",
    "checklist-reporting indicator",
    ifelse(
      outcome == "conditional_positive_numeric_count",
      "log(positive numeric reported count)",
      "finite numeric (1) versus X (0)"
    )
  )
  exposure_terms <- c(
    "es_near_baseline", "es_reference_baseline",
    "es_near_early_pre", "es_reference_early_pre",
    "es_near_immediate_pre", "es_reference_immediate_pre",
    "es_near_spawn_start", "es_reference_spawn_start",
    "es_near_early_egg", "es_reference_early_egg",
    "es_near_late_egg", "es_reference_late_egg"
  )
  paste0(
    response_label, " [model_response] ~ ",
    paste(exposure_terms, collapse = " + "),
    " + factor(checklist_year) + protocol + log_duration + ",
    "log_effort_distance + observer_count + (1|event_block_token) + ",
    "(1|observer_cluster_token) + (1|location_cluster_token)"
  )
}

prepare_status <- function(x, analysis, exposure_encoding) {
  out <- x
  out$analysis <- analysis
  out$exposure_encoding <- exposure_encoding
  out$model_formula <- model_formula(out$outcome)
  out$valid_biological_result <- grepl("^completed", out$status)
  out$failure_reason <- ifelse(
    grepl("^failed", out$status),
    ifelse(
      !is.na(out$convergence_message) & nzchar(out$convergence_message),
      out$convergence_message,
      out$status
    ),
    ""
  )
  out
}

primary_status <- prepare_status(
  primary_diagnostics,
  "primary_additive_link_and_finite_vs_x",
  "all concurrent event links retained additively"
)
sensitivity_status <- prepare_status(
  sensitivity_diagnostics,
  "nearest_event_sensitivity",
  paste0(
    "one minimum-distance modeled-window event retained per checklist; ",
    "deterministic source-token tie break"
  )
)
status_core <- c(
  "analysis", "analysis_taxon_id", "species", "outcome",
  "exposure_encoding", "engine", "model_formula", "n", "event_blocks",
  "observer_clusters", "generalized_locations", "status", "converged",
  "singular_fit", "rank_deficient", "optimizer_code",
  "convergence_message", "maximum_absolute_gradient",
  "event_block_variance", "observer_variance", "location_variance",
  "residual_variance", "valid_biological_result", "failure_reason"
)
component_status <- rbind(
  primary_status[, status_core, drop = FALSE],
  sensitivity_status[, status_core, drop = FALSE]
)
component_status$previously_identified_failure_species <-
  component_status$species %in% c(
    "Surfbird", "Rhinoceros Auklet", "Glaucous Gull",
    "Red-throated Loon", "Western Gull", "Common Goldeneye",
    "Marbled Murrelet", "Western Grebe"
  )
component_status$failed_component_is_not_null_result <-
  grepl("^failed", component_status$status)

status_keep <- c(
  status_core,
  "previously_identified_failure_species",
  "failed_component_is_not_null_result"
)
component_status <- component_status[, status_keep, drop = FALSE]
status_key <- paste(
  component_status$analysis,
  component_status$analysis_taxon_id,
  component_status$outcome,
  sep = "|"
)
if (nrow(component_status) != 245L || anyDuplicated(status_key)) {
  stop("CONVENTIONAL_COMPONENT_STATUS_KEY_GATE: failed", call. = FALSE)
}

status_path <- file.path(output_dir, "component_status.csv")
editorial_write_csv_v1(component_status, status_path)
editorial_privacy_column_gate_v1(c(result_path, status_path))
message(
  "CONVENTIONAL_RELEASE_TABLES=PASS; results=", nrow(results),
  "; component_status=", nrow(component_status)
)
