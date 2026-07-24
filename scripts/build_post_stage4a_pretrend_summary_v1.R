#!/usr/bin/env Rscript

## Pre-onset (pre-trend) summary for the post-Stage 4A SoG event study.
##
## The two pre-onset difference-in-differences contrasts, did_early_pre
## (days -14 to -8) and did_immediate_pre (days -7 to -1), are already
## estimated for every species and both outcomes in the frozen v1 release.
## This script therefore needs no protected inputs and no refitting: it reads
## the released estimates, verifies them against their recorded hash, and
## summarises how far the near and reference zones had already diverged
## before spawn onset.
##
## It writes only to a new versioned directory and never touches the frozen
## release.
##
## Usage: Rscript scripts/build_post_stage4a_pretrend_summary_v1.R

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
source(file.path("R", "post_stage4a_sog_event_study_v1.R"), local = FALSE)

release_dir <- .post_stage4a_frozen_release_dir_v1
output_dir <- "outputs/post_stage4a_sog_event_study_pretrend_v1"
effects_path <- file.path(release_dir, "effect_estimates_v1.csv")
manifest_path <- file.path(release_dir, "output_hash_manifest_v1.csv")
.post_stage4a_guard_frozen_outputs_v1(output_dir)

manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE)
expected <- manifest$sha256[
  gsub("\\\\", "/", manifest$file) == gsub("\\\\", "/", effects_path)
]
observed <- .post_stage4a_sha256_v1(effects_path)
if (length(expected) != 1L || !identical(observed, expected)) {
  stop("POST_STAGE4A_PRETREND_BASELINE_GATE: ",
       "effect_estimates_v1.csv does not match its recorded hash",
       call. = FALSE)
}
effects <- utils::read.csv(effects_path, stringsAsFactors = FALSE)

windows <- data.frame(
  contrast = c("did_early_pre", "did_immediate_pre", "did_pre_14_day"),
  window_days = c("-14 to -8", "-7 to -1", "-14 to -1"),
  window_role = c("pre_onset", "pre_onset", "pre_onset_combined"),
  stringsAsFactors = FALSE
)
outcomes <- c("detection", "positive_numeric_count_given_detection")
outcome_labels <- c(detection = "reporting",
                    positive_numeric_count_given_detection = "reported number")

species <- effects[
  effects$analysis_role == "core_species" &
    effects$outcome %in% outcomes &
    effects$contrast %in% windows$contrast, , drop = FALSE
]
species$window_days <- windows$window_days[match(species$contrast,
                                                 windows$contrast)]
species$window_role <- windows$window_role[match(species$contrast,
                                                 windows$contrast)]
species$outcome_label <- unname(outcome_labels[species$outcome])
species$estimable <- is.finite(species$p_value) & is.finite(species$q_value)
species$adjusted_significant <- species$estimable & species$q_value < 0.05
species$direction <- ifelse(
  !species$estimable, NA_character_,
  ifelse(species$estimate > 0, "positive", "negative")
)
species <- species[order(species$outcome, species$contrast,
                         species$unit_label), , drop = FALSE]
keep <- c("analysis_taxon_id", "unit_label", "outcome", "outcome_label",
          "contrast", "window_days", "window_role", "estimate",
          "standard_error", "ratio", "ratio_conf_low", "ratio_conf_high",
          "p_value", "q_value", "estimable", "adjusted_significant",
          "direction", "status")
species_out <- species[, keep, drop = FALSE]

rows <- list()
for (outcome in outcomes) {
  for (i in seq_len(nrow(windows))) {
    contrast <- windows$contrast[[i]]
    block <- species[species$outcome == outcome &
                       species$contrast == contrast, , drop = FALSE]
    ok <- block[block$estimable, , drop = FALSE]
    ratios <- ok$ratio
    quartiles <- if (length(ratios)) {
      stats::quantile(ratios, c(0.25, 0.75), names = FALSE, type = 7)
    } else {
      c(NA_real_, NA_real_)
    }
    rows[[length(rows) + 1L]] <- data.frame(
      outcome = outcome,
      outcome_label = unname(outcome_labels[[outcome]]),
      contrast = contrast,
      window_days = windows$window_days[[i]],
      window_role = windows$window_role[[i]],
      species_in_family = nrow(block),
      species_estimable = nrow(ok),
      median_ratio = if (length(ratios)) stats::median(ratios) else NA_real_,
      ratio_q25 = quartiles[[1L]],
      ratio_q75 = quartiles[[2L]],
      ratio_min = if (length(ratios)) min(ratios) else NA_real_,
      ratio_max = if (length(ratios)) max(ratios) else NA_real_,
      species_ratio_above_one = sum(ratios > 1),
      adjusted_significant = sum(ok$adjusted_significant),
      adjusted_significant_positive = sum(ok$adjusted_significant &
                                            ok$direction == "positive"),
      adjusted_significant_negative = sum(ok$adjusted_significant &
                                            ok$direction == "negative"),
      min_q_value = if (nrow(ok)) min(ok$q_value) else NA_real_,
      stringsAsFactors = FALSE
    )
  }
}
summary_out <- do.call(rbind, rows)

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
.post_stage4a_write_csv_v1(
  summary_out, file.path(output_dir, "pretrend_summary_v1.csv")
)
.post_stage4a_write_csv_v1(
  species_out, file.path(output_dir, "pretrend_species_estimates_v1.csv")
)
flagged <- species_out[species_out$adjusted_significant, , drop = FALSE]
.post_stage4a_write_csv_v1(
  flagged, file.path(output_dir, "pretrend_flagged_species_v1.csv")
)

execution_record <- list(
  execution_version = "post_stage4a_sog_event_study_pretrend_v1",
  executed_at_utc = format(
    as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"
  ),
  analysis_status = "derived_from_frozen_release_no_refit",
  refitting_performed = FALSE,
  protected_inputs_read = 0L,
  source_release = gsub("\\\\", "/", effects_path),
  source_release_sha256 = observed,
  outcomes = as.list(outcomes),
  pre_onset_contrasts = as.list(windows$contrast),
  final_gate = "PASS_PENDING_HUMAN_POST_STAGE4A_EVENT_STUDY_REVIEW"
)
.post_stage4a_write_yaml_v1(
  execution_record, file.path(output_dir, "execution_record_v1.yml")
)
output_files <- file.path(output_dir, c(
  "pretrend_summary_v1.csv",
  "pretrend_species_estimates_v1.csv",
  "pretrend_flagged_species_v1.csv",
  "execution_record_v1.yml"
))
.post_stage4a_write_csv_v1(
  data.frame(
    file = gsub("\\\\", "/", output_files),
    sha256 = vapply(output_files, .post_stage4a_sha256_v1, character(1L)),
    stringsAsFactors = FALSE
  ),
  file.path(output_dir, "output_hash_manifest_v1.csv")
)

cat("\nPre-onset summary (core species, frozen v1 release)\n")
cat(strrep("-", 78), "\n")
for (i in seq_len(nrow(summary_out))) {
  r <- summary_out[i, ]
  cat(sprintf(
    "%-15s %-18s (%s)  n=%2d  median ratio %.4f [IQR %.4f-%.4f]  q<0.05: %d (+%d/-%d)\n",
    r$outcome_label, r$contrast, r$window_days, r$species_estimable,
    r$median_ratio, r$ratio_q25, r$ratio_q75, r$adjusted_significant,
    r$adjusted_significant_positive, r$adjusted_significant_negative
  ))
}
if (nrow(flagged)) {
  cat("\nSpecies clearing q < 0.05 before spawn onset:\n")
  for (i in seq_len(nrow(flagged))) {
    r <- flagged[i, ]
    cat(sprintf("  %-14s %-18s %-22s ratio %.4f [%.4f, %.4f]  q = %.4f\n",
                r$outcome_label, r$contrast, r$unit_label, r$ratio,
                r$ratio_conf_low, r$ratio_conf_high, r$q_value))
  }
} else {
  cat("\nNo species cleared q < 0.05 in any pre-onset window.\n")
}
cat("\nWritten to ", output_dir, "\n", sep = "")
message("POST_STAGE4A_PRETREND_SUMMARY_GATE=PASS")
