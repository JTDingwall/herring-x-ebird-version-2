#!/usr/bin/env Rscript
# Read-only summariser for the block-aware run. Prints the quantities that
# BLOCKAWARE_REPORT.md quotes so the report is transcribed from computed
# values rather than by hand. Writes nothing.

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
root <- file.path("outputs", "post_stage4a_blockaware_v1")
read <- function(name) {
  utils::read.csv(file.path(root, name), stringsAsFactors = FALSE)
}
estimates <- read("blockaware_estimates_49x2.csv")
comparison <- read("blockaware_vs_stage2.csv")
variances <- read("blockaware_slope_variance.csv")
changes <- read("blockaware_bh_changes.csv")
tallies <- read("blockaware_tallies.csv")

rule <- function(text) cat("\n\n===== ", text, " =====\n", sep = "")
fmt <- function(x, digits = 4) formatC(x, digits = digits, format = "g")

rule("TALLIES")
print(t(tallies), quote = FALSE)

rule("INTERVAL METHOD MIX")
print(table(estimates$outcome, estimates$primary_interval_method))
print(table(estimates$outcome, estimates$kenward_roger_status))

rule("KENWARD-ROGER VERSUS SATTERTHWAITE ON THE COMMON SUBSET")
both <- estimates[
  estimates$outcome == "conditional_positive_numeric_count" &
    estimates$kenward_roger_status %in%
      c("completed", "completed_with_warning") &
    is.finite(estimates$satterthwaite_df),
]
cat("species with both:", nrow(both), "\n")
if (nrow(both)) {
  cat("KR df: median", fmt(median(both$kenward_roger_df)),
      " range", fmt(min(both$kenward_roger_df)), "to",
      fmt(max(both$kenward_roger_df)), "\n")
  cat("Satterthwaite df: median", fmt(median(both$satterthwaite_df)),
      " range", fmt(min(both$satterthwaite_df)), "to",
      fmt(max(both$satterthwaite_df)), "\n")
  ratio <- both$kenward_roger_standard_error / both$wald_standard_error
  cat("KR SE / Wald SE: median", fmt(median(ratio)),
      " range", fmt(min(ratio)), "to", fmt(max(ratio)), "\n")
  disagree <- (both$kenward_roger_p_value < 0.05) !=
    (both$satterthwaite_p_value < 0.05)
  cat("nominal 0.05 disagreements between KR and Satterthwaite:",
      sum(disagree), "\n")
  if (any(disagree)) print(both[disagree, c("species", "kenward_roger_p_value",
                                            "satterthwaite_p_value")])
}

rule("BH CHANGES")
if (nrow(changes)) {
  print(changes[, c(
    "species", "outcome", "bh_change", "stage2_estimate",
    "blockaware_estimate", "percent_shift_in_log_effect",
    "interval_width_ratio", "mechanism"
  )], row.names = FALSE)
} else {
  cat("no species entered or left\n")
}
cat("\nmechanism counts by outcome:\n")
print(table(changes$outcome, changes$mechanism))

rule("INTERVAL WIDTH RATIO")
for (outcome in unique(comparison$outcome)) {
  d <- comparison[
    comparison$outcome == outcome &
      is.finite(comparison$interval_width_ratio),
  ]
  cat(outcome, ": n=", nrow(d),
      " median ", fmt(median(d$interval_width_ratio)),
      " range ", fmt(min(d$interval_width_ratio)), " to ",
      fmt(max(d$interval_width_ratio)),
      " quartiles ", fmt(quantile(d$interval_width_ratio, 0.25)), " / ",
      fmt(quantile(d$interval_width_ratio, 0.75)), "\n", sep = "")
  cat("  wider than Stage 2: ", sum(d$interval_width_ratio > 1), " of ",
      nrow(d), "\n", sep = "")
}

rule("POINT ESTIMATE MOVEMENT")
for (outcome in unique(comparison$outcome)) {
  d <- comparison[
    comparison$outcome == outcome & is.finite(comparison$estimate_shift),
  ]
  cat(outcome, ": median absolute shift ",
      fmt(median(abs(d$estimate_shift))),
      " median absolute percent ",
      fmt(median(abs(d$percent_shift_in_log_effect))),
      " max absolute percent ",
      fmt(max(abs(d$percent_shift_in_log_effect))), "\n", sep = "")
  worst <- d[order(-abs(d$percent_shift_in_log_effect)), ][seq_len(min(5, nrow(d))), ]
  print(worst[, c("species", "stage2_estimate", "blockaware_estimate",
                  "percent_shift_in_log_effect")], row.names = FALSE)
}

rule("SLOPE VARIANCE DISTRIBUTION")
for (outcome in unique(variances$outcome)) {
  d <- variances[
    variances$outcome == outcome &
      is.finite(variances$event_block_slope_variance),
  ]
  cat("\n", outcome, ": n=", nrow(d), "\n", sep = "")
  print(quantile(
    d$event_block_slope_variance, c(0, .25, .5, .75, 1), names = TRUE
  ))
  cat("slope SD quantiles:\n")
  print(quantile(d$event_block_slope_sd, c(0, .25, .5, .75, 1)))
  cat("at or below the frozen near-zero point threshold 0.0025: ",
      sum(d$event_block_slope_variance <= 0.0025), " of ", nrow(d), "\n",
      sep = "")
  cat("intercept-slope correlation quantiles:\n")
  print(quantile(
    d$event_block_intercept_slope_correlation, c(0, .25, .5, .75, 1),
    na.rm = TRUE
  ))
  top <- d[order(-d$event_block_slope_variance), ][seq_len(min(5, nrow(d))), ]
  cat("largest slope SDs:\n")
  print(top[, c("species", "event_block_slope_sd",
                "slope_sd_multiplicative_spread_low",
                "slope_sd_multiplicative_spread_high")], row.names = FALSE)
}

rule("FIT PROBLEMS RETAINED NOT DROPPED")
problems <- estimates[
  estimates$status != "completed" |
    estimates$converged %in% FALSE |
    estimates$singular_fit %in% TRUE,
]
cat("rows with any fit problem:", nrow(problems), "of", nrow(estimates), "\n")
print(table(estimates$outcome, estimates$status))
if (nrow(problems)) {
  print(problems[, c("species", "outcome", "status", "converged",
                     "singular_fit", "significant_bh_fixed49")],
        row.names = FALSE)
}

rule("SURVIVING SPECIES BY OUTCOME")
for (outcome in unique(estimates$outcome)) {
  d <- estimates[
    estimates$outcome == outcome & estimates$significant_bh_fixed49,
  ]
  d <- d[order(-abs(d$estimate)), ]
  cat("\n", outcome, ": ", nrow(d), "\n", sep = "")
  print(d[, c("species", "direction", "estimate", "ratio",
              "ratio_conf_low", "ratio_conf_high", "q_value_bh_fixed49",
              "primary_interval_method")], row.names = FALSE)
}
