#!/usr/bin/env Rscript

# Recompute the two referee follow-up items from archived aggregate outputs.
# This script does not fit or refit a response model and does not read any
# record-level or prospective holdout input.

options(stringsAsFactors = FALSE)

output_dir <- file.path("outputs", "referee_reads_followup_v1")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

primary_path <- file.path(
  "outputs", "post_stage4a_sog_event_study_v1_1",
  "active_minus_pre_contrasts_v1.csv"
)
frozen_effects_path <- file.path(
  "outputs", "post_stage4a_sog_event_study_v1",
  "effect_estimates_v1.csv"
)
summary_dir <- file.path(
  "outputs", "post_stage4a_sog_event_study_model_summaries_v1"
)
old_dir <- file.path("outputs", "referee_reads_v1")
registry_path <- file.path("metadata", "canonical_species_registry.csv")

required_files <- c(
  primary_path,
  frozen_effects_path,
  registry_path,
  file.path(old_dir, "item8_paired_outcome_asymmetry.csv"),
  file.path(old_dir, "item10_species_timing_contrasts.csv"),
  file.path(old_dir, "item10_guild_means.csv"),
  file.path(old_dir, "item10_meta_regression_tests.csv")
)
if (!all(file.exists(required_files))) {
  stop(
    "FOLLOWUP_INPUT_GATE: missing required archived aggregate: ",
    paste(required_files[!file.exists(required_files)], collapse = ", "),
    call. = FALSE
  )
}
if (!dir.exists(summary_dir)) {
  stop("FOLLOWUP_INPUT_GATE: model-summary directory is absent", call. = FALSE)
}

is_completed <- function(x) {
  !is.na(x) & grepl("^completed", x)
}

write_output <- function(x, filename) {
  utils::write.csv(
    x, file.path(output_dir, filename),
    row.names = FALSE, na = ""
  )
}

exact_mcnemar <- function(count_only, reporting_only) {
  discordant <- count_only + reporting_only
  if (!discordant) return(1)
  stats::binom.test(
    min(count_only, reporting_only), discordant,
    p = 0.5, alternative = "two.sided"
  )$p.value
}

paired_sign_summary <- function(rows, contrast_label) {
  reporting <- rows[
    rows$outcome == "detection",
    c("analysis_taxon_id", "unit_label", "estimate"),
    drop = FALSE
  ]
  counts <- rows[
    rows$outcome == "positive_numeric_count_given_detection",
    c("analysis_taxon_id", "unit_label", "estimate"),
    drop = FALSE
  ]
  if (anyDuplicated(reporting$analysis_taxon_id) ||
      anyDuplicated(counts$analysis_taxon_id)) {
    stop(
      "ITEM8_CARDINALITY_GATE: duplicate outcome row for ",
      contrast_label, call. = FALSE
    )
  }
  paired <- merge(
    reporting, counts,
    by = c("analysis_taxon_id", "unit_label"),
    suffixes = c("_reporting", "_count"),
    all = FALSE, sort = FALSE
  )
  if (nrow(paired) != 46L ||
      anyDuplicated(paired$analysis_taxon_id)) {
    stop(
      "ITEM8_CARDINALITY_GATE: expected a 1:1 inner join over 46 species for ",
      contrast_label, call. = FALSE
    )
  }
  paired$positive_reporting <- paired$estimate_reporting > 0
  paired$positive_count <- paired$estimate_count > 0
  positive_both <- sum(
    paired$positive_reporting & paired$positive_count
  )
  positive_count_only <- sum(
    !paired$positive_reporting & paired$positive_count
  )
  positive_reporting_only <- sum(
    paired$positive_reporting & !paired$positive_count
  )
  negative_both <- sum(
    !paired$positive_reporting & !paired$positive_count
  )
  summary <- data.frame(
    contrast = contrast_label,
    positive_both = positive_both,
    positive_count_only = positive_count_only,
    positive_reporting_only = positive_reporting_only,
    negative_both = negative_both,
    paired_species = nrow(paired),
    reporting_positive = sum(paired$positive_reporting),
    reporting_positive_proportion = mean(paired$positive_reporting),
    count_positive = sum(paired$positive_count),
    count_positive_proportion = mean(paired$positive_count),
    discordant_pairs = positive_count_only + positive_reporting_only,
    exact_mcnemar_p_value = exact_mcnemar(
      positive_count_only, positive_reporting_only
    ),
    stringsAsFactors = FALSE
  )
  list(summary = summary, species = paired)
}

# -------------------------------------------------------------------------
# Item A: identify and reproduce the original contrast, then correct it.
# -------------------------------------------------------------------------

frozen_effects <- utils::read.csv(
  frozen_effects_path, check.names = FALSE
)
if ("active_minus_pre_14_day" %in% frozen_effects$contrast) {
  stop(
    "ITEM8_SOURCE_GATE: frozen period-contrast file unexpectedly contains ",
    "active_minus_pre_14_day", call. = FALSE
  )
}
original_rows <- frozen_effects[
  frozen_effects$analysis_role == "core_species" &
    frozen_effects$contrast == "did_active_0_14_day" &
    is_completed(frozen_effects$status) &
    is.finite(frozen_effects$estimate),
  c("analysis_taxon_id", "unit_label", "outcome", "estimate"),
  drop = FALSE
]
original_item8 <- paired_sign_summary(
  original_rows, "did_active_0_14_day"
)
old_item8 <- utils::read.csv(
  file.path(old_dir, "item8_paired_outcome_asymmetry.csv"),
  check.names = FALSE
)
old_columns <- c(
  "positive_both", "positive_count_only",
  "positive_reporting_only", "negative_both",
  "paired_species", "reporting_positive", "count_positive",
  "discordant_pairs"
)
if (nrow(old_item8) != 1L ||
    !identical(
      as.integer(original_item8$summary[1L, old_columns]),
      as.integer(old_item8[1L, old_columns])
    ) ||
    abs(
      original_item8$summary$exact_mcnemar_p_value -
        old_item8$exact_mcnemar_p_value
    ) > 1e-15) {
  stop(
    "ITEM8_REPRODUCTION_GATE: did_active_0_14_day does not reproduce ",
    "the original Item 8 table", call. = FALSE
  )
}

primary <- utils::read.csv(primary_path, check.names = FALSE)
primary_rows <- primary[
  primary$analysis_role == "core_species" &
    primary$contrast == "active_minus_pre_14_day" &
    is_completed(primary$status) &
    is.finite(primary$estimate),
  c(
    "analysis_taxon_id", "unit_label", "outcome", "estimate",
    "standard_error", "status"
  ),
  drop = FALSE
]
primary_reporting <- primary_rows[
  primary_rows$outcome == "detection", , drop = FALSE
]
primary_count <- primary_rows[
  primary_rows$outcome == "positive_numeric_count_given_detection",
  , drop = FALSE
]
if (nrow(primary_reporting) != 48L ||
    nrow(primary_count) != 46L ||
    anyDuplicated(primary_reporting$analysis_taxon_id) ||
    anyDuplicated(primary_count$analysis_taxon_id)) {
  stop(
    "ITEM8_PRIMARY_FAMILY_GATE: expected 48 reporting and 46 count ",
    "estimable core species", call. = FALSE
  )
}
corrected_item8 <- paired_sign_summary(
  primary_rows, "active_minus_pre_14_day"
)
corrected_item8$summary$full_reporting_estimable <- nrow(primary_reporting)
corrected_item8$summary$full_reporting_positive <- sum(
  primary_reporting$estimate > 0
)
corrected_item8$summary$full_reporting_positive_proportion <- mean(
  primary_reporting$estimate > 0
)
corrected_item8$summary$full_count_estimable <- nrow(primary_count)
corrected_item8$summary$full_count_positive <- sum(
  primary_count$estimate > 0
)
corrected_item8$summary$full_count_positive_proportion <- mean(
  primary_count$estimate > 0
)
corrected_item8$summary$reconciles_with_28_of_48_and_42_of_46 <-
  corrected_item8$summary$full_reporting_positive == 28L &&
  corrected_item8$summary$full_reporting_estimable == 48L &&
  corrected_item8$summary$full_count_positive == 42L &&
  corrected_item8$summary$full_count_estimable == 46L

excluded_reporting <- primary_reporting[
  !primary_reporting$analysis_taxon_id %in%
    corrected_item8$species$analysis_taxon_id,
  c("analysis_taxon_id", "unit_label", "estimate", "status"),
  drop = FALSE
]
if (nrow(excluded_reporting) != 2L ||
    sum(excluded_reporting$estimate > 0) != 1L) {
  stop(
    "ITEM8_RECONCILIATION_GATE: expected two reporting-only estimable ",
    "species, one positive and one negative", call. = FALSE
  )
}
corrected_item8$species$contrast <- "active_minus_pre_14_day"
corrected_item8$species <- corrected_item8$species[
  order(corrected_item8$species$unit_label), , drop = FALSE
]
write_output(
  corrected_item8$summary,
  "item8_paired_outcome_asymmetry.csv"
)
write_output(
  corrected_item8$species,
  "item8_paired_species.csv"
)
write_output(
  excluded_reporting,
  "item8_reporting_species_excluded_from_pair.csv"
)
write_output(
  rbind(
    transform(
      original_item8$summary,
      source_file = frozen_effects_path,
      role = "original_item8_reproduced"
    ),
    transform(
      corrected_item8$summary[, names(original_item8$summary), drop = FALSE],
      source_file = primary_path,
      role = "corrected_primary_contrast"
    )
  ),
  "item8_original_vs_corrected.csv"
)

# -------------------------------------------------------------------------
# Item B: exact spawn-start minus early-egg covariance and meta-regression.
# -------------------------------------------------------------------------

source(file.path("R", "post_stage4a_sog_event_study_v1.R"), local = FALSE)
old_species <- utils::read.csv(
  file.path(old_dir, "item10_species_timing_contrasts.csv"),
  check.names = FALSE
)
old_guild <- utils::read.csv(
  file.path(old_dir, "item10_guild_means.csv"),
  check.names = FALSE
)
old_tests <- utils::read.csv(
  file.path(old_dir, "item10_meta_regression_tests.csv"),
  check.names = FALSE
)
registry <- utils::read.csv(registry_path, check.names = FALSE)[
  , c("analysis_taxon_id", "common_name", "guild_ids"),
  drop = FALSE
]

expected_by_outcome <- c(
  detection = 48L,
  positive_numeric_count_given_detection = 46L
)
observed_by_outcome <- table(old_species$outcome)
if (!identical(
    as.integer(observed_by_outcome[names(expected_by_outcome)]),
    as.integer(expected_by_outcome)
  ) ||
  anyDuplicated(
    paste(old_species$analysis_taxon_id, old_species$outcome, sep = "|")
  )) {
  stop(
    "ITEM10_SPECIES_GATE: approximate source does not contain the fixed ",
    "48/46 component sets", call. = FALSE
  )
}

exact_rows <- vector("list", nrow(old_species))
for (i in seq_len(nrow(old_species))) {
  row <- old_species[i, , drop = FALSE]
  summary_path <- file.path(
    summary_dir,
    paste(
      row$analysis_taxon_id, row$outcome,
      "model_summary_v1.rds", sep = "_"
    )
  )
  if (!file.exists(summary_path)) {
    stop(
      "ITEM10_SUMMARY_GATE: missing summary for ",
      row$analysis_taxon_id, " / ", row$outcome,
      call. = FALSE
    )
  }
  model_summary <- readRDS(summary_path)
  beta <- model_summary$fixed_effects
  covariance <- model_summary$covariance
  if (!is_completed(model_summary$status) ||
      !identical(model_summary$analysis_taxon_id, row$analysis_taxon_id) ||
      !identical(model_summary$outcome, row$outcome) ||
      !is.numeric(beta) || is.null(names(beta)) ||
      !is.matrix(covariance) ||
      any(dim(covariance) != length(beta))) {
    stop(
      "ITEM10_SUMMARY_GATE: invalid fitted summary for ",
      row$analysis_taxon_id, " / ", row$outcome,
      call. = FALSE
    )
  }
  covariance <- covariance[names(beta), names(beta), drop = FALSE]
  definitions <- post_stage4a_contrast_definitions_v1(names(beta))
  contrast_names <- vapply(
    definitions, function(x) x$contrast, character(1L)
  )
  spawn_vector <- definitions[[
    match("did_spawn_start", contrast_names)
  ]]$vector
  early_vector <- definitions[[
    match("did_early_egg", contrast_names)
  ]]$vector
  if (is.null(spawn_vector) || is.null(early_vector)) {
    stop("ITEM10_CONTRAST_GATE: required contrast vector absent", call. = FALSE)
  }
  spawn_estimate <- sum(spawn_vector * beta)
  early_estimate <- sum(early_vector * beta)
  spawn_variance <- drop(
    t(spawn_vector) %*% covariance %*% spawn_vector
  )
  early_variance <- drop(
    t(early_vector) %*% covariance %*% early_vector
  )
  spawn_early_covariance <- drop(
    t(spawn_vector) %*% covariance %*% early_vector
  )
  difference_vector <- spawn_vector - early_vector
  exact_variance <- drop(
    t(difference_vector) %*% covariance %*% difference_vector
  )
  if (!is.finite(exact_variance) || exact_variance <= 0) {
    stop(
      "ITEM10_VARIANCE_GATE: non-positive exact variance for ",
      row$analysis_taxon_id, " / ", row$outcome,
      call. = FALSE
    )
  }
  if (max(
    abs(spawn_estimate - row$estimate_spawn_start),
    abs(early_estimate - row$estimate_early_egg),
    abs(sqrt(spawn_variance) - row$standard_error_spawn_start),
    abs(sqrt(early_variance) - row$standard_error_early_egg)
  ) > 1e-4) {
    stop(
      "ITEM10_POINT_ESTIMATE_GATE: persisted summary does not reproduce ",
      "the approximate input for ", row$analysis_taxon_id, " / ", row$outcome,
      call. = FALSE
    )
  }
  persisted_summary_timing_contrast <- spawn_estimate - early_estimate
  timing_contrast <- row$timing_contrast
  if (abs(
    persisted_summary_timing_contrast - timing_contrast
  ) > 1e-4) {
    stop(
      "ITEM10_TIMING_GATE: timing contrast changed for ",
      row$analysis_taxon_id, " / ", row$outcome,
      call. = FALSE
    )
  }
  exact_standard_error <- sqrt(exact_variance)
  exact_rows[[i]] <- data.frame(
    analysis_taxon_id = row$analysis_taxon_id,
    unit_label = row$unit_label,
    common_name = row$common_name,
    guild_ids = row$guild_ids,
    outcome = row$outcome,
    estimate_spawn_start = row$estimate_spawn_start,
    standard_error_spawn_start = row$standard_error_spawn_start,
    estimate_early_egg = row$estimate_early_egg,
    standard_error_early_egg = row$standard_error_early_egg,
    timing_contrast = timing_contrast,
    persisted_summary_timing_contrast =
      persisted_summary_timing_contrast,
    persisted_minus_frozen_timing_contrast =
      persisted_summary_timing_contrast - timing_contrast,
    approximate_timing_variance = row$timing_variance,
    approximate_timing_standard_error = row$timing_standard_error,
    spawn_early_covariance = spawn_early_covariance,
    covariance_sign = ifelse(
      spawn_early_covariance > 0, "positive",
      ifelse(spawn_early_covariance < 0, "negative", "zero")
    ),
    exact_timing_variance = exact_variance,
    exact_timing_standard_error = exact_standard_error,
    exact_conf_low = timing_contrast -
      1.959963984540054 * exact_standard_error,
    exact_conf_high = timing_contrast +
      1.959963984540054 * exact_standard_error,
    ratio_spawn_start_vs_early_egg = exp(timing_contrast),
    exact_standard_error_divided_by_approximate =
      exact_standard_error / row$timing_standard_error,
    exact_inverse_variance_weight = 1 / exact_variance,
    exact_variance_method =
      "linear_contrast_against_persisted_fixed_effect_covariance",
    stringsAsFactors = FALSE
  )
}
exact_species <- do.call(rbind, exact_rows)
if (nrow(exact_species) != 94L ||
    anyDuplicated(
      paste(
        exact_species$analysis_taxon_id,
        exact_species$outcome,
        sep = "|"
      )
    )) {
  stop("ITEM10_EXACT_CARDINALITY_GATE: exact rows changed", call. = FALSE)
}
registry_match <- match(
  exact_species$analysis_taxon_id, registry$analysis_taxon_id
)
if (anyNA(registry_match) ||
    any(
      exact_species$common_name != registry$common_name[registry_match]
    ) ||
    any(
      exact_species$guild_ids != registry$guild_ids[registry_match]
    )) {
  stop("ITEM10_GUILD_GATE: guild assignments changed", call. = FALSE)
}

meta_regression <- function(timing, variance_column, method) {
  guild_factor <- factor(timing$guild_ids)
  design <- stats::model.matrix(~ 0 + guild_factor)
  weights <- 1 / timing[[variance_column]]
  information <- crossprod(design, weights * design)
  coefficients <- solve(
    information,
    crossprod(design, weights * timing$timing_contrast)
  )
  coefficient_covariance <- solve(information)
  coefficient_se <- sqrt(diag(coefficient_covariance))
  guild_names <- levels(guild_factor)
  fitted <- drop(design %*% coefficients)
  grand_mean <- sum(weights * timing$timing_contrast) / sum(weights)
  q_total <- sum(
    weights * (timing$timing_contrast - grand_mean)^2
  )
  q_residual <- sum(
    weights * (timing$timing_contrast - fitted)^2
  )
  q_between <- q_total - q_residual
  df_between <- length(guild_names) - 1L
  df_residual <- nrow(timing) - length(guild_names)
  list(
    guild = data.frame(
      outcome = timing$outcome[[1L]],
      variance_method = method,
      guild = guild_names,
      species = as.integer(table(guild_factor)[guild_names]),
      mean_link_contrast = drop(coefficients),
      standard_error = coefficient_se,
      conf_low = drop(coefficients) -
        1.959963984540054 * coefficient_se,
      conf_high = drop(coefficients) +
        1.959963984540054 * coefficient_se,
      ratio_spawn_start_vs_early_egg = exp(drop(coefficients)),
      stringsAsFactors = FALSE
    ),
    tests = data.frame(
      outcome = timing$outcome[[1L]],
      variance_method = method,
      species = nrow(timing),
      guilds = length(guild_names),
      q_between = q_between,
      df_between = df_between,
      p_guild_differences = stats::pchisq(
        q_between, df_between, lower.tail = FALSE
      ),
      q_residual = q_residual,
      df_residual = df_residual,
      p_residual_heterogeneity = stats::pchisq(
        q_residual, df_residual, lower.tail = FALSE
      ),
      residual_i2_percent = 100 * max(
        0, (q_residual - df_residual) / q_residual
      ),
      stringsAsFactors = FALSE
    )
  )
}

approx_results <- list()
exact_results <- list()
for (outcome in names(expected_by_outcome)) {
  timing <- exact_species[
    exact_species$outcome == outcome, , drop = FALSE
  ]
  approx_results[[outcome]] <- meta_regression(
    timing, "approximate_timing_variance",
    "archived_standard_errors_covariance_assumed_zero"
  )
  exact_results[[outcome]] <- meta_regression(
    timing, "exact_timing_variance",
    "persisted_fixed_effect_covariance"
  )
}
approx_guild_recomputed <- do.call(
  rbind, lapply(approx_results, `[[`, "guild")
)
approx_tests_recomputed <- do.call(
  rbind, lapply(approx_results, `[[`, "tests")
)
exact_guild <- do.call(
  rbind, lapply(exact_results, `[[`, "guild")
)
exact_tests <- do.call(
  rbind, lapply(exact_results, `[[`, "tests")
)

old_guild_key <- paste(old_guild$outcome, old_guild$guild, sep = "|")
recomputed_guild_key <- paste(
  approx_guild_recomputed$outcome,
  approx_guild_recomputed$guild,
  sep = "|"
)
guild_match <- match(old_guild_key, recomputed_guild_key)
if (anyNA(guild_match) ||
    max(abs(
      old_guild$mean_link_contrast -
        approx_guild_recomputed$mean_link_contrast[guild_match]
    )) > 1e-10 ||
    max(abs(
      old_guild$standard_error -
        approx_guild_recomputed$standard_error[guild_match]
    )) > 1e-10) {
  stop(
    "ITEM10_APPROXIMATION_REPRODUCTION_GATE: old guild table did not ",
    "reproduce", call. = FALSE
  )
}
test_match <- match(old_tests$outcome, approx_tests_recomputed$outcome)
test_fields <- c(
  "q_between", "p_guild_differences", "q_residual",
  "p_residual_heterogeneity", "residual_i2_percent"
)
if (anyNA(test_match) ||
    max(abs(
      as.matrix(old_tests[, test_fields]) -
        as.matrix(approx_tests_recomputed[test_match, test_fields])
    )) > 1e-9) {
  stop(
    "ITEM10_APPROXIMATION_REPRODUCTION_GATE: old test table did not ",
    "reproduce", call. = FALSE
  )
}

exact_guild_key <- paste(exact_guild$outcome, exact_guild$guild, sep = "|")
exact_guild_match <- match(old_guild_key, exact_guild_key)
guild_side_by_side <- data.frame(
  outcome = old_guild$outcome,
  guild = old_guild$guild,
  species = old_guild$species,
  approximate_mean_link_contrast = old_guild$mean_link_contrast,
  approximate_standard_error = old_guild$standard_error,
  approximate_conf_low = old_guild$conf_low,
  approximate_conf_high = old_guild$conf_high,
  approximate_ratio_spawn_start_vs_early_egg =
    old_guild$ratio_spawn_start_vs_early_egg,
  exact_mean_link_contrast =
    exact_guild$mean_link_contrast[exact_guild_match],
  exact_standard_error =
    exact_guild$standard_error[exact_guild_match],
  exact_conf_low = exact_guild$conf_low[exact_guild_match],
  exact_conf_high = exact_guild$conf_high[exact_guild_match],
  exact_ratio_spawn_start_vs_early_egg =
    exact_guild$ratio_spawn_start_vs_early_egg[exact_guild_match],
  mean_change_exact_minus_approximate =
    exact_guild$mean_link_contrast[exact_guild_match] -
      old_guild$mean_link_contrast,
  approximate_interval_excludes_zero =
    old_guild$conf_low > 0 | old_guild$conf_high < 0,
  exact_interval_excludes_zero =
    exact_guild$conf_low[exact_guild_match] > 0 |
      exact_guild$conf_high[exact_guild_match] < 0,
  direction_changed =
    sign(exact_guild$mean_link_contrast[exact_guild_match]) !=
      sign(old_guild$mean_link_contrast),
  stringsAsFactors = FALSE
)

exact_test_match <- match(old_tests$outcome, exact_tests$outcome)
tests_side_by_side <- data.frame(
  outcome = old_tests$outcome,
  species = old_tests$species,
  guilds = old_tests$guilds,
  df_between = old_tests$df_between,
  approximate_q_between = old_tests$q_between,
  exact_q_between = exact_tests$q_between[exact_test_match],
  approximate_p_guild_differences = old_tests$p_guild_differences,
  exact_p_guild_differences =
    exact_tests$p_guild_differences[exact_test_match],
  df_residual = old_tests$df_residual,
  approximate_q_residual = old_tests$q_residual,
  exact_q_residual = exact_tests$q_residual[exact_test_match],
  approximate_p_residual_heterogeneity =
    old_tests$p_residual_heterogeneity,
  exact_p_residual_heterogeneity =
    exact_tests$p_residual_heterogeneity[exact_test_match],
  approximate_residual_i2_percent = old_tests$residual_i2_percent,
  exact_residual_i2_percent =
    exact_tests$residual_i2_percent[exact_test_match],
  stringsAsFactors = FALSE
)

covariance_summary_one <- function(x, label) {
  data.frame(
    outcome = label,
    components = nrow(x),
    mean_spawn_early_covariance = mean(x$spawn_early_covariance),
    median_spawn_early_covariance =
      stats::median(x$spawn_early_covariance),
    positive_covariance_components = sum(x$spawn_early_covariance > 0),
    zero_covariance_components = sum(x$spawn_early_covariance == 0),
    negative_covariance_components = sum(x$spawn_early_covariance < 0),
    mean_exact_se_divided_by_approximate =
      mean(x$exact_standard_error_divided_by_approximate),
    median_exact_se_divided_by_approximate =
      stats::median(x$exact_standard_error_divided_by_approximate),
    stringsAsFactors = FALSE
  )
}
covariance_summary <- rbind(
  covariance_summary_one(exact_species, "all_components"),
  do.call(rbind, lapply(
    split(exact_species, exact_species$outcome),
    function(x) covariance_summary_one(x, x$outcome[[1L]])
  ))
)

write_output(
  exact_species,
  "item10_species_timing_contrasts.csv"
)
write_output(
  guild_side_by_side,
  "item10_guild_means.csv"
)
write_output(
  tests_side_by_side,
  "item10_meta_regression_tests.csv"
)
write_output(
  covariance_summary,
  "item10_covariance_summary.csv"
)

message("REFEREE_READS_FOLLOWUP=PASS")
