.stage4a_publication_assert_unique_v2 <- function(x, keys, label) {
  missing <- setdiff(keys, names(x))
  if (length(missing)) stop(label, ": missing key fields: ", paste(missing, collapse = ", "))
  key_data <- as.data.frame(x, stringsAsFactors = FALSE)[, keys, drop = FALSE]
  signature <- do.call(paste, c(lapply(key_data, as.character), sep = "\034"))
  if (anyDuplicated(signature)) stop(label, ": key is not unique", call. = FALSE)
  invisible(TRUE)
}

.stage4a_publication_completed_v2 <- function(status) grepl("^completed", status)

.stage4a_publication_weighted_mean_v2 <- function(value, weight) {
  use <- is.finite(value) & is.finite(weight) & weight > 0
  if (!any(use)) return(NA_real_)
  stats::weighted.mean(value[use], weight[use])
}

.stage4a_publication_verify_manifest_v2 <- function(root, manifest_path) {
  manifest <- data.table::fread(file.path(root, manifest_path))
  for (i in seq_len(nrow(manifest))) {
    artifact <- file.path(root, manifest$artifact_path[i])
    if (!file.exists(artifact)) stop("Manifest artifact missing: ", manifest$artifact_path[i])
    hash <- digest::digest(artifact, algo = "sha256", file = TRUE, serialize = FALSE)
    if (!identical(hash, manifest$sha256[i])) {
      stop("Manifest hash mismatch: ", manifest$artifact_path[i])
    }
  }
  invisible(manifest)
}

.stage4a_publication_model_labels_v2 <- function() c(
  M01_PRIMARY_v2 = "Matched primary",
  M27_v2 = "Date placebo",
  M28_v2 = "Location placebo",
  S4A12_WCVI_2KM_v2 = "WCVI 2-km cohort",
  S4A11_WCVI_DOMINANT_OBSERVER_v2 = "Dominant-observer holdout"
)

.stage4a_publication_model_colors_v2 <- function() c(
  M01_PRIMARY_v2 = "#174a6e", M27_v2 = "#c26a1b", M28_v2 = "#2b8c7e",
  S4A12_WCVI_2KM_v2 = "#7b4fa3", S4A11_WCVI_DOMINANT_OBSERVER_v2 = "#b23a48"
)

.stage4a_publication_marker_v2 <- function(model, x, y, color) {
  if (model %in% c("M01_PRIMARY_v2", "M27_v2")) {
    if (model == "M01_PRIMARY_v2") {
      return(sprintf("<circle cx='%d' cy='%d' r='4' fill='%s' stroke='%s'/>",
                     x, y, color, color))
    }
    return(sprintf("<rect x='%d' y='%d' width='8' height='8' fill='%s' stroke='%s'/>",
                   x - 4L, y - 4L, color, color))
  }
  if (model == "M28_v2") return(sprintf(
    "<path d='M %d %d L %d %d L %d %d Z' fill='%s' stroke='%s'/>",
    x, y - 5L, x - 5L, y + 4L, x + 5L, y + 4L, color, color))
  if (model == "S4A12_WCVI_2KM_v2") return(sprintf(
    "<path d='M %d %d L %d %d L %d %d L %d %d Z' fill='%s' stroke='%s'/>",
    x, y - 5L, x - 5L, y, x, y + 5L, x + 5L, y, color, color))
  sprintf("<path d='M %d %d L %d %d M %d %d L %d %d' stroke='%s' stroke-width='2'/>",
          x - 4L, y - 4L, x + 4L, y + 4L, x - 4L, y + 4L, x + 4L, y - 4L, color)
}

.stage4a_publication_forest_v2 <- function(x, models, regions, path, title) {
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  labels <- .stage4a_publication_model_labels_v2()
  colors <- .stage4a_publication_model_colors_v2()
  outcomes <- c("detection", "positive_numeric_count_given_detection")
  panel_height <- 320L
  width <- 1200L
  height <- 72L + length(regions) * panel_height
  body <- c(.stage4a_report_text(width / 2L, 26L, title, 18L, "middle", "bold"))
  legend_x <- seq(170L, 1030L, length.out = length(models))
  for (i in seq_along(models)) {
    body <- c(body,
      .stage4a_publication_marker_v2(models[i], legend_x[i], 50L, colors[models[i]]),
      .stage4a_report_text(legend_x[i] + 10L, 54L, labels[models[i]], 10L))
  }
  for (region_index in seq_along(regions)) for (outcome_index in seq_along(outcomes)) {
    region_name <- regions[region_index]
    outcome <- outcomes[outcome_index]
    d <- x[x$region == region_name & x$outcome == outcome &
             x$model_version_id %in% models, , drop = FALSE]
    x0 <- (outcome_index - 1L) * 600L
    y0 <- 65L + (region_index - 1L) * panel_height
    left <- x0 + 180L
    right <- x0 + 560L
    guilds <- sort(unique(d$unit_label), method = "radix")
    top <- y0 + 55L
    bottom <- top + max(1L, length(guilds) - 1L) * 27L
    xr <- range(c(0, d$conf_low, d$conf_high), finite = TRUE)
    pad <- max(diff(xr) * 0.08, 0.08)
    xr <- xr + c(-pad, pad)
    zero <- .stage4a_report_scale_x(0, xr[1L], xr[2L], left, right)
    body <- c(body,
      .stage4a_report_text(x0 + 300L, y0 + 25L,
        paste(region_name, if (outcome == "detection") "detection" else "positive count"),
        15L, "middle", "bold"),
      sprintf("<line x1='%d' y1='%d' x2='%d' y2='%d' class='axis'/>",
              left, bottom + 18L, right, bottom + 18L),
      sprintf("<line x1='%d' y1='%d' x2='%d' y2='%d' class='zero'/>",
              zero, top - 13L, zero, bottom + 10L),
      .stage4a_report_text(left, bottom + 38L, format(xr[1L], digits = 3), 10L,
                           "middle", class = "muted"),
      .stage4a_report_text(right, bottom + 38L, format(xr[2L], digits = 3), 10L,
                           "middle", class = "muted"))
    offsets <- seq(-7L, 7L, length.out = length(models))
    for (guild_index in seq_along(guilds)) {
      y <- top + (guild_index - 1L) * 27L
      body <- c(body, .stage4a_report_text(left - 10L, y + 4L, guilds[guild_index],
                                           10L, "end"))
      for (model_index in seq_along(models)) {
        z <- d[d$unit_label == guilds[guild_index] &
                 d$model_version_id == models[model_index], , drop = FALSE]
        if (nrow(z) != 1L) stop(
          "Publication forest join/accounting failure: ", region_name, " / ", outcome,
          " / ", guilds[guild_index], " / ", models[model_index], " = ", nrow(z))
        yy <- as.integer(round(y + offsets[model_index]))
        if (is.finite(z$estimate)) {
          xx <- .stage4a_report_scale_x(c(z$conf_low, z$estimate, z$conf_high),
                                        xr[1L], xr[2L], left, right)
          body <- c(body,
            sprintf("<line x1='%d' y1='%d' x2='%d' y2='%d' stroke='%s' stroke-width='1.5'/>",
                    xx[1L], yy, xx[3L], yy, colors[models[model_index]]),
            .stage4a_publication_marker_v2(models[model_index], xx[2L], yy,
                                            colors[models[model_index]]))
        } else {
          body <- c(body, .stage4a_report_text(right + 10L, yy + 3L, "x", 10L,
                                               "start", class = "muted"))
        }
      }
    }
  }
  .stage4a_report_svg_document(path, width, height, body)
}

.stage4a_publication_diagnostics_svg_v2 <- function(summary, path) {
  labels <- .stage4a_publication_model_labels_v2()
  models <- names(labels)
  statuses <- c("completed", "completed_with_singular_warning", "failed_convergence")
  colors <- c(completed = "#2b8c7e", completed_with_singular_warning = "#d6a54b",
              failed_convergence = "#b23a48")
  width <- 980L
  height <- 390L
  left <- 275L
  right <- 900L
  bar_height <- 34L
  body <- c(.stage4a_report_text(width / 2L, 28L,
    "Matched sensitivity component diagnostics", 18L, "middle", "bold"))
  for (i in seq_along(statuses)) {
    lx <- 300L + (i - 1L) * 215L
    body <- c(body, sprintf("<rect x='%d' y='46' width='13' height='13' fill='%s'/>",
                            lx, colors[statuses[i]]),
      .stage4a_report_text(lx + 19L, 57L,
        c("Completed", "Singular warning", "Failed convergence")[i], 11L))
  }
  counts <- summary[, .(components = sum(components)), by = .(model_version_id, status)]
  for (i in seq_along(models)) {
    y <- 90L + (i - 1L) * 56L
    body <- c(body, .stage4a_report_text(left - 12L, y + 22L, labels[models[i]],
                                         12L, "end"))
    cursor <- left
    for (status_name in statuses) {
      n <- counts[model_version_id == models[i] & status == status_name, components]
      if (!length(n)) n <- 0L
      w <- as.integer(round(n / 32 * (right - left)))
      if (w > 0L) body <- c(body,
        sprintf("<rect x='%d' y='%d' width='%d' height='%d' fill='%s' stroke='white'/>",
                cursor, y, w, bar_height, colors[status_name]),
        .stage4a_report_text(cursor + w / 2L, y + 22L, n, 11L, "middle", "bold"))
      cursor <- cursor + w
    }
    body <- c(body, .stage4a_report_text(right + 8L, y + 22L,
      paste0(sum(counts[model_version_id == models[i], components]), " components"),
      10L, "start", class = "muted"))
  }
  body <- c(body, .stage4a_report_text(width / 2L, 375L,
    "Singularity is retained as a warning; convergence failures have no released estimate.",
    11L, "middle", class = "muted"))
  .stage4a_report_svg_document(path, width, height, body)
}

build_stage4a_publication_report_v2 <- function(repo_root = ".") {
  root <- normalizePath(repo_root, winslash = "/", mustWork = TRUE)
  path <- function(...) file.path(root, ...)
  output_dir <- path("outputs", "stage4a_publication_v2")
  report_dir <- path("reports")
  figure_dir <- path("reports", "figures")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

  .stage4a_publication_verify_manifest_v2(
    root, "outputs/stage4a_publication_sensitivity_v2/output_hash_manifest_v2.csv")
  .stage4a_publication_verify_manifest_v2(
    root, "outputs/stage4a_pooling_repair_v2/output_hash_manifest_v2.csv")
  .stage4a_publication_verify_manifest_v2(
    root, "outputs/stage4a_pooling_report_v2/report_artifact_hashes_v2.csv")

  sensitivity <- data.table::fread(path("outputs", "stage4a_publication_sensitivity_v2",
                                        "sensitivity_effect_estimates_v2.csv"))
  diagnostics <- data.table::fread(path("outputs", "stage4a_publication_sensitivity_v2",
                                        "model_diagnostics_v2.csv"))
  validation <- data.table::fread(path("outputs", "stage4a_publication_sensitivity_v2",
                                       "matched_validation_v2.csv"))
  model_map <- data.table::fread(path("metadata",
                                      "stage4a_publication_sensitivity_model_map_v2.csv"))
  primary <- data.table::fread(path("outputs", "stage4a_pooling_report_v2",
                                    "primary_guild_results_v2.csv"))
  species <- data.table::fread(path("outputs", "stage4a_pooling_report_v2",
                                    "priority_a_species_results_v2.csv"))
  event <- data.table::fread(path("outputs", "stage4a_pooling_report_v2",
                                  "event_time_family_results_v2.csv"))
  family <- data.table::fread(path("outputs", "stage4a_pooling_report_v2",
                                   "family_diagnostics_v2.csv"))
  row_audit <- data.table::fread(path("outputs", "stage4a_pooling_repair_v2",
                                      "row_inclusion_exclusion_audit_v2.csv"))
  execution <- yaml::read_yaml(path("outputs", "stage4a_publication_sensitivity_v2",
                                    "execution_record_v2.yml"))

  if (nrow(sensitivity) != 128L || nrow(primary) != 32L || nrow(species) != 20L ||
      nrow(event) != 160L || nrow(family) != 162L || nrow(row_audit) != 6562L) {
    stop("STAGE4A_PUBLICATION_ACCOUNTING: source artifact row counts failed")
  }
  if (execution$maximum_checklist_year_read > 2025L ||
      execution$records_2026_plus_read != 0L) {
    stop("STAGE4A_PUBLICATION_YEAR_GATE: 2026+ records were read")
  }
  .stage4a_publication_assert_unique_v2(
    sensitivity, c("model_version_id", "region", "unit_label", "outcome"),
    "sensitivity effects")
  .stage4a_publication_assert_unique_v2(
    primary, c("model_id", "region", "unit_label", "outcome", "contrast"),
    "registered primary effects")

  sensitivity <- model_map[, .(model_version_id, publication_role)][
    sensitivity, on = "model_version_id"]
  if (anyNA(sensitivity$publication_role)) stop("Sensitivity model-map join failed")
  sensitivity[, effect_scale := ifelse(outcome == "detection", "log_odds",
    "log_expected_positive_numeric_count")]
  data.table::setorder(sensitivity, model_version_id, region, outcome, unit_label)

  reference <- sensitivity[model_version_id == "M01_PRIMARY_v2", .(
    region, unit_label, outcome, reference_estimate = estimate,
    reference_conf_low = conf_low, reference_conf_high = conf_high,
    reference_q_value = q_value, reference_status = status
  )]
  comparisons <- sensitivity[model_version_id != "M01_PRIMARY_v2"]
  .stage4a_publication_assert_unique_v2(reference, c("region", "unit_label", "outcome"),
                                        "matched sparse reference")
  if (nrow(reference) != 32L || nrow(comparisons) != 96L) {
    stop("STAGE4A_PUBLICATION_JOIN_CARDINALITY: expected 32-to-96 many-to-one join")
  }
  concordance <- merge(comparisons, reference,
    by = c("region", "unit_label", "outcome"), all.x = TRUE, sort = FALSE)
  if (nrow(concordance) != 96L || anyNA(concordance$reference_status)) {
    stop("STAGE4A_PUBLICATION_JOIN_CARDINALITY: sensitivity join did not preserve 96 rows")
  }
  concordance[, `:=`(
    estimate_difference_from_matched_reference = estimate - reference_estimate,
    same_estimate_sign = is.finite(estimate) & is.finite(reference_estimate) &
      sign(estimate) == sign(reference_estimate),
    confidence_intervals_overlap = is.finite(conf_low) & is.finite(reference_conf_low) &
      pmax(conf_low, reference_conf_low) <= pmin(conf_high, reference_conf_high)
  )]
  data.table::setorder(concordance, model_version_id, region, outcome, unit_label)

  diagnostic_summary <- diagnostics[, .(components = .N),
    by = .(model_version_id, region, outcome, status, converged, singular_fit)]
  data.table::setorder(diagnostic_summary, model_version_id, region, outcome, status)
  sensitivity_summary <- sensitivity[, .(
    expected_components = .N,
    completed_components = sum(.stage4a_publication_completed_v2(status)),
    failed_components = sum(!.stage4a_publication_completed_v2(status)),
    singular_warning_components = sum(status == "completed_with_singular_warning"),
    bh_q_below_0p05 = sum(.stage4a_publication_completed_v2(status) &
                            is.finite(q_value) & q_value < 0.05),
    positive_estimates = sum(.stage4a_publication_completed_v2(status) &
                               is.finite(estimate) & estimate > 0)
  ), by = .(model_version_id, region, outcome, publication_role)]
  data.table::setorder(sensitivity_summary, model_version_id, region, outcome)

  validation_summary <- validation[, .(
    component_fold_rows = .N,
    registered_folds = data.table::uniqueN(fold),
    median_n_validation_supported = as.numeric(stats::median(
      n_validation_supported, na.rm = TRUE)),
    maximum_unsupported_factor_levels = as.numeric(max(
      n_validation_unsupported_factor_levels, na.rm = TRUE)),
    metric_1_name = paste(sort(unique(metric_1_name)), collapse = "|"),
    supported_weighted_metric_1 = .stage4a_publication_weighted_mean_v2(
      metric_1, n_validation_supported),
    metric_2_name = paste(sort(unique(metric_2_name)), collapse = "|"),
    supported_weighted_metric_2 = .stage4a_publication_weighted_mean_v2(
      metric_2, n_validation_supported),
    conditional_observer_or_location_BLUP_used =
      any(conditional_observer_or_location_BLUP_used)
  ), by = .(model_version_id, region, outcome, validation_view,
            prediction_support_rule)]
  data.table::setorder(validation_summary, model_version_id, region, outcome)

  row_audit[, release_category := data.table::fcase(
    disposition_reason_code == "EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION",
      "EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION",
    numeric_input_reason_code == "NON_ESTIMABLE_MODEL_STATUS",
      "NON_ESTIMABLE_MODEL_STATUS",
    default = "INCLUDED_PRIMARY_REPRESENTATION"
  )]
  exclusion_summary <- row_audit[, .(rows = .N), by = release_category]
  exclusion_summary[, publication_treatment := data.table::fcase(
    release_category == "INCLUDED_PRIMARY_REPRESENTATION", "v2 posterior released",
    release_category == "NON_ESTIMABLE_MODEL_STATUS", "explicit NA retained",
    release_category == "EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION",
      "canonical representation retained; duplicate is explicit NA",
    default = "review required"
  )]
  data.table::setorder(exclusion_summary, release_category)
  if (any(exclusion_summary$rows > 0 & exclusion_summary$rows < 20)) {
    stop("STAGE4A_PUBLICATION_PRIVACY: exclusion summary cell below 20")
  }
  pooling_summary <- data.table::data.table(
    metric = c("invalid_v1_finite_rows", "invalid_v1_families", "compatible_v2_families",
      "estimable_v2_families", "nonestimable_v2_families", "v2_posterior_rows",
      "noncompleted_rows_explicit_na", "duplicate_representations_explicit_na"),
    value = c(6562L, 112L, nrow(family), sum(family$estimability_status == "ESTIMABLE"),
      sum(family$estimability_status != "ESTIMABLE"),
      exclusion_summary[release_category == "INCLUDED_PRIMARY_REPRESENTATION", rows],
      exclusion_summary[release_category == "NON_ESTIMABLE_MODEL_STATUS", rows],
      exclusion_summary[release_category ==
        "EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION", rows])
  )
  classification <- data.table::data.table(
    analysis_component = c("Registered M01/M02 Stage 4A coefficients",
      "Aggregate pooling repair v2", "M27/M28 matched placebos",
      "WCVI 2-km cohort sensitivity", "WCVI dominant-observer holdout",
      "M05 event-time contrasts", "M26 v1 visitation summary"),
    classification = c("confirmatory core", "confirmatory synthesis repair",
      "diagnostic sensitivity", "secondary sensitivity", "secondary sensitivity",
      "registered secondary", "historical only"),
    registered_before_outcome_inspection = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
    publication_use = c("primary individual inference", "compatible-family synthesis",
      "falsification diagnostic", "robustness", "robustness",
      "discrete exposure-window description", "retired without replacement"),
    caveat = c("checklist-conditional association", "does not replace individual inference",
      "null result does not establish causal identification", "cohort restriction only",
      "observer exclusion only", "not a continuous trajectory or causal event study",
      "no registered exposure or visitation contrast")
  )
  disposition <- data.table::fread(path("outputs", "stage4a_publication_sensitivity_v2",
                                        "model_disposition_v2.csv"))

  primary[, effect_scale := ifelse(outcome == "detection", "log_odds",
                                    "log_expected_positive_numeric_count")]
  primary[, analysis_role := "confirmatory_registered_core"]
  species[, effect_scale := ifelse(outcome == "detection", "log_odds",
                                    "log_expected_positive_numeric_count")]
  species[, analysis_role := "confirmatory_registered_priority_a"]
  event[, analysis_role := "registered_secondary_discrete_event_time"]
  primary_columns <- c("model_id", "region", "unit_label", "unit_class", "outcome",
    "contrast", "effect_scale", "estimate", "standard_error", "conf_low", "conf_high",
    "p_value", "q_value", "n", "status", "partial_pool_estimate_v2",
    "partial_pool_standard_error_v2", "partial_pool_conf_low_v2",
    "partial_pool_conf_high_v2", "pooling_reason_code_v2", "analysis_role")
  primary <- primary[, ..primary_columns]
  species <- species[, ..primary_columns]

  tables <- list(
    primary_guild_table_v2 = primary,
    priority_a_species_table_v2 = species,
    event_time_table_v2 = event,
    matched_sensitivity_table_v2 = sensitivity,
    sensitivity_concordance_v2 = concordance,
    sensitivity_summary_v2 = sensitivity_summary,
    model_diagnostic_summary_v2 = diagnostic_summary,
    validation_summary_v2 = validation_summary,
    pooling_repair_summary_v2 = pooling_summary,
    supplementary_family_table_v2 = family,
    supplementary_exclusion_summary_v2 = exclusion_summary,
    analysis_classification_v2 = classification,
    model_disposition_v2 = disposition
  )
  for (name in names(tables)) .stage4a_pooling_v2_write_csv(
    tables[[name]], file.path(output_dir, paste0(name, ".csv")))

  placebo_figure <- file.path(figure_dir, "stage4a_publication_v2_placebo_comparison.svg")
  placebo_inline <- .stage4a_publication_forest_v2(
    sensitivity, c("M01_PRIMARY_v2", "M27_v2", "M28_v2"), c("SoG", "WCVI"),
    placebo_figure, "Matched whole-bundle placebo diagnostics")
  robustness_figure <- file.path(figure_dir, "stage4a_publication_v2_wcvi_robustness.svg")
  robustness_inline <- .stage4a_publication_forest_v2(
    sensitivity, c("M01_PRIMARY_v2", "S4A12_WCVI_2KM_v2",
                   "S4A11_WCVI_DOMINANT_OBSERVER_v2"), "WCVI",
    robustness_figure, "WCVI matched spatial and observer sensitivities")
  diagnostics_figure <- file.path(figure_dir, "stage4a_publication_v2_diagnostics.svg")
  diagnostics_inline <- .stage4a_publication_diagnostics_svg_v2(
    diagnostic_summary, diagnostics_figure)

  completed <- sum(.stage4a_publication_completed_v2(sensitivity$status))
  failed <- nrow(sensitivity) - completed
  singular <- sum(sensitivity$status == "completed_with_singular_warning")
  placebo <- sensitivity[model_version_id %in% c("M27_v2", "M28_v2") &
    .stage4a_publication_completed_v2(status)]
  placebo_significant <- sum(is.finite(placebo$q_value) & placebo$q_value < 0.05)
  primary_sig <- sensitivity[model_version_id == "M01_PRIMARY_v2" &
    .stage4a_publication_completed_v2(status) & is.finite(q_value) & q_value < 0.05, .N]
  primary_completed <- sensitivity[model_version_id == "M01_PRIMARY_v2" &
    .stage4a_publication_completed_v2(status), .N]
  falsification_warning <- sensitivity[model_version_id == "M01_PRIMARY_v2" &
    unit_label == "falsification" & region == "SoG" &
    .stage4a_publication_completed_v2(status) & is.finite(q_value) & q_value < 0.05, .N]
  fit_accounting_text <- if (failed == 0L) paste0(
    "All 128 components completed and released finite estimates; ", singular,
    " retain an explicit singular-fit warning. No component failed convergence and no ",
    "simplified GLM fallback was used.") else paste0(
    failed, " of 128 components failed convergence and release no coefficient; ",
    singular, " components completed with a singular-fit warning. No simplified GLM ",
    "fallback was used.")

  methods <- c(
    "# Stage 4A publication methods v2", "",
    "The accepted invalid Stage 4A v1 pooling scope is 6,562 finite released aggregate rows in 112 historical families. The earlier 4,890-row/84-family audit omitted the registered North-region literal code `NA` because global base-R missing-value parsing converted that category to missing. The v2 reader preserves identity and categorical fields as character values, validates region codes against the frozen registry, and applies missing-value rules by column. No protected record was recovered or newly exposed by this correction.", "",
    "The aggregate repair used tracked privacy-safe coefficients and frozen metadata only. Compatible evidence was grouped without mixing models, estimands, response states, unit classes, scales, exposures, windows, buffers, populations, adjustment sets, or coefficient meanings. The frozen normal-normal empirical-Bayes method-of-moments estimator produced 162 estimable v2 families. All unaffected individual-model fields remain byte-for-byte equal at source serialization; M11/M12 duplicate representations and noncompleted fits remain explicit NA rows.", "",
    "Publication sensitivity models use the same sparse mixed-model engine within each comparison: binomial-logit `glmer` for detection and REML `lmer` for log positive numeric count, each with random intercepts for event block, observer cluster, and location cluster. M27/M28 move the full linked exposure bundle within region-year strata using frozen nonzero cyclic shifts. The WCVI 2-km and dominant-observer analyses change only their registered cohort restriction. Four-fold event-blocked validation is retained. M26 v1 is retired without replacement.", "",
    "Primary interpretation: among eligible submitted complete eBird checklists, modeled bird-response outcomes were associated with recorded local herring-spawn exposure after adjustment for the registered effort, observer, temporal, and spatial covariates. Coefficients remain on separate detection log-odds and positive-log-count scales."
  )
  claims <- c(
    "# Stage 4A claim boundaries v2", "",
    "Supported wording: Among eligible submitted complete eBird checklists, modeled bird-response outcomes were associated with recorded local herring-spawn exposure after adjustment for the registered effort, observer, temporal, and spatial covariates.", "",
    "Ecological discussion may state that some patterns are consistent with short-duration bird aggregations around herring spawning. The analyses do not identify population abundance, biomass, occupancy, migration, movement, or causal effects. They are conditional on checklist submission and registered eligibility.", "",
    "The two placebos are diagnostics, not proof of exchangeability or causal identification. The prespecified falsification guild is a specificity panel, not a guaranteed biological nonresponder. Outcome-informed follow-up work must be labeled exploratory and must state when it was selected.", "",
    "Missing herring components are not zeros. Surveyed-positive, surveyed-negative, and unmonitored-unknown coverage remain distinct. Missing DFO records are not surveyed negatives, and incomplete DFO monitoring is a substantive limitation."
  )
  reproducibility <- c(
    "# Stage 4A reproducibility and data access v2", "",
    paste0("Pre-execution specification commit: `", execution$pre_execution_spec_commit, "`."),
    paste0("Execution-code commit: `", execution$execution_code_commit, "`."),
    paste0("Protected model components: ", completed, " completed or completed with warning; ",
           failed, " failed with explicit status; ", singular, " singular warnings retained."),
    "Maximum checklist year read was 2025; the recorded count of 2026+ rows read was zero.",
    "Protected event, response-state, and ambiguity inputs remain local and are represented only by SHA-256 hashes in the execution record. No protected rows, observer identities, localities, exact coordinates, event tokens, or source-row mappings are released.",
    "The tracked publication package is built exclusively from privacy-safe aggregate artifacts. Raw EBD/SED and record-level derivatives require authorized access and are not distributed."
  )
  methods_file <- file.path(report_dir, "stage4a_publication_methods_v2.md")
  claims_file <- file.path(report_dir, "stage4a_publication_claim_boundaries_v2.md")
  reproducibility_file <- file.path(report_dir, "stage4a_publication_reproducibility_v2.md")
  .stage4a_pooling_v2_write_text_lf(methods, methods_file)
  .stage4a_pooling_v2_write_text_lf(claims, claims_file)
  .stage4a_pooling_v2_write_text_lf(reproducibility, reproducibility_file)

  summary_table <- data.table::data.table(
    result = c("Accepted invalid v1 scope", "Compatible/estimable v2 families",
      "Matched sensitivity components", "Completed components", "Singular warnings",
      "Explicit convergence failures", "Completed placebo components with BH q < 0.05",
      "Matched-primary components with BH q < 0.05", "2026+ rows read"),
    value = c("6,562 rows / 112 families", "162 / 162", "128", completed, singular,
      failed, paste0(placebo_significant, " / ", nrow(placebo)),
      paste0(primary_sig, " / ", primary_completed, " completed"), "0")
  )
  diagnostic_display <- sensitivity_summary[, .(
    model = .stage4a_publication_model_labels_v2()[model_version_id], region,
    response = ifelse(outcome == "detection", "detection", "positive count"),
    completed = completed_components, failed = failed_components,
    singular = singular_warning_components, bh_q_below_0p05
  )]
  html <- paste0(
    "<!doctype html><html><head><meta charset='utf-8'>",
    "<meta name='viewport' content='width=device-width,initial-scale=1'>",
    "<title>Stage 4A Publication Analysis v2</title><style>",
    ":root{--ink:#17212b;--muted:#596674;--paper:#fff;--panel:#f5f7f8;--line:#ccd4db;--blue:#174a6e;--gold:#b7791f;--red:#b23a48}",
    "body{font-family:system-ui,-apple-system,sans-serif;max-width:1180px;margin:0 auto;padding:28px 22px;color:var(--ink);background:var(--paper);line-height:1.55}",
    "h1,h2{line-height:1.2}h1{color:var(--blue)}h2{margin-top:2.2rem;border-bottom:1px solid var(--line);padding-bottom:.35rem}",
    ".summary{background:var(--panel);border-left:5px solid var(--blue);padding:14px 18px}.caution{background:var(--panel);border-left:5px solid var(--gold);padding:12px 16px}.failure{border-left-color:var(--red)}",
    ".figure{margin:22px 0;padding:12px;background:white;border:1px solid #d5dde3;overflow:auto}.figure svg{width:100%;height:auto;min-width:760px}.caption{font-size:.9rem;color:var(--muted)}",
    ".table-wrap{overflow:auto}table{border-collapse:collapse;width:100%;font-size:.86rem}th,td{border:1px solid var(--line);padding:6px 8px;text-align:left}th{background:var(--panel)}code{font-size:.9em}",
    "</style></head><body>",
    "<h1>Stage 4A Publication Analysis v2</h1>",
    "<div class='summary'><p><strong>Publication core.</strong> Among eligible submitted complete eBird checklists, modeled bird-response outcomes were associated with recorded local herring-spawn exposure after adjustment for the registered effort, observer, temporal, and spatial covariates.</p><p>The registered individual-model results remain primary; repaired v2 pooling is compatible-family synthesis. Matched sparse models are used only to compare the primary exposure assignment with placebos and WCVI cohort sensitivities on the same engine.</p></div>",
    "<h2>Release accounting</h2>", .stage4a_report_table(summary_table, 5L),
    "<p>The accepted parser correction accounts for 6,562 finite v1 pooling rows and 112 historical families. It restores the literal registered North code <code>NA</code> from tracked aggregates; it does not recover protected data. All 162 compatible v2 families are estimable, 6,085 primary representations receive v2 posteriors, 38 noncompleted rows remain explicit NA, and 439 duplicate M11/M12 representations remain explicit NA.</p>",
    "<h2>Confirmatory guild and species results</h2><p>The versioned primary-guild and Priority-A species tables report every frozen row without selection by direction or significance. Detection and positive-count coefficients remain on separate scales; individual and v2 posterior inference remain visibly distinct.</p>",
    "<div class='figure'>", paste(readLines(path("reports", "figures", "stage4a_pooling_v2_primary_guild.svg"), warn = FALSE), collapse = "\n"), "<p class='caption'>Registered M01 guild coefficients: unchanged individual estimates and compatible-family v2 posteriors, with normal 95% intervals.</p></div>",
    "<div class='figure'>", paste(readLines(path("reports", "figures", "stage4a_pooling_v2_priority_a_species.svg"), warn = FALSE), collapse = "\n"), "<p class='caption'>Frozen Priority-A M02 species subset. No species was selected from observed results.</p></div>",
    "<h2>Discrete event-time contrasts</h2><p>M05 event windows are registered categorical coefficients. The plot shows all eight guild intervals in each region-response panel; gold diamonds are descriptive medians, not new pooled estimates. The panels do not imply a continuous trajectory or causal event-study design.</p>",
    "<div class='figure'>", paste(readLines(path("reports", "figures", "stage4a_pooling_v2_event_time.svg"), warn = FALSE), collapse = "\n"), "</div>",
    "<h2>Whole-bundle placebo diagnostics</h2><p>Across ", nrow(placebo), " completed M27/M28 components, ", placebo_significant, " had BH q below 0.05 in their registered model-region-response family. This attenuation after response-blind within-region-year bundle reassignment is a useful diagnostic, but it does not establish causal identification. The SoG falsification guild was non-null in the matched primary reference (", falsification_warning, " of two response components at BH q below 0.05), reinforcing that residual habitat, submission, or observer structure remains plausible.</p>",
    "<div class='figure'>", placebo_inline, "<p class='caption'>Matched sparse primary, date-placebo, and location-placebo coefficients with normal 95% intervals. Every registered component is retained.</p></div>",
    "<h2>WCVI spatial and observer robustness</h2><p>The 2-km cohort and dominant-observer holdout preserve the matched model architecture; only the intended cohort restriction changes. They retain several positive associations, while sparse WCVI geometry produces visible singular warnings. These results support qualified robustness, not uniform stability.</p>",
    "<div class='figure'>", robustness_inline, "<p class='caption'>WCVI matched-reference, high-spatial-precision, and observer-holdout coefficients; all registered components have finite intervals.</p></div>",
    "<h2>Model diagnostics and blocked validation</h2>",
    "<div class='figure'>", diagnostics_inline, "</div>",
    .stage4a_report_table(diagnostic_display, 4L),
    "<div class='caution failure'><p><strong>Fit accounting.</strong> ", fit_accounting_text, " Four-fold event-blocked validation remains in the supplementary validation table, including unsupported-factor-level counts and a declaration that observer/location BLUPs were not used for new-event predictions.</p></div>",
    "<h2>Model disposition and exploratory work</h2><p>M26 v1 is retired from the inferential publication set without replacement because it lacks a registered exposure or visitation contrast. Outcome-informed follow-up analysis is permitted only when labeled exploratory, dated relative to outcome inspection, and accompanied by multiplicity reporting where a hypothesis family is evaluated. All prespecified results remain reported regardless of sign.</p>",
    "<h2>Limitations and claim boundary</h2><div class='caution'><p>These are checklist-conditional associations, not population abundance, biomass, occupancy, migration, movement, or causal effects. Checklist submission, observer behavior, residual spatial-temporal confounding, interference among concurrent spawn events, and incomplete DFO monitoring remain limitations. All concurrent event links contribute additively. Missing herring components are not zero; missing DFO records are not surveyed negatives, and unmonitored coverage remains unknown.</p></div>",
    "<h2>Reproducibility and access</h2><p>The sensitivity execution is linked to pre-execution commit <code>", execution$pre_execution_spec_commit, "</code> and code commit <code>", execution$execution_code_commit, "</code>. Maximum year read was 2025 and the 2026+ row count was zero. Only privacy-safe aggregates, diagnostics, hashes, and report materials are tracked; protected rows, identities, localities, exact coordinates, and transformation mappings remain unreleased.</p>",
    "</body></html>"
  )
  report_file <- file.path(report_dir, "stage4a_publication_analysis_v2.html")
  .stage4a_pooling_v2_write_text_lf(html, report_file)

  source_manifests <- c(
    "outputs/stage4a_pooling_repair_v2/output_hash_manifest_v2.csv",
    "outputs/stage4a_pooling_report_v2/report_artifact_hashes_v2.csv",
    "outputs/stage4a_publication_sensitivity_v2/output_hash_manifest_v2.csv"
  )
  source_hashes <- data.table::data.table(
    artifact_path = source_manifests,
    sha256 = vapply(file.path(root, source_manifests), function(file) digest::digest(
      file, algo = "sha256", file = TRUE, serialize = FALSE), character(1L)),
    role = c("aggregate_repair_source_manifest", "pooling_report_source_manifest",
             "protected_sensitivity_aggregate_manifest")
  )
  source_hash_file <- file.path(output_dir, "source_artifact_hashes_v2.csv")
  .stage4a_pooling_v2_write_csv(source_hashes, source_hash_file)

  artifact_files <- c(file.path(output_dir, paste0(names(tables), ".csv")),
    source_hash_file, report_file, methods_file, claims_file, reproducibility_file,
    placebo_figure, robustness_figure, diagnostics_figure)
  normalized <- normalizePath(artifact_files, winslash = "/", mustWork = TRUE)
  manifest <- data.table::data.table(
    artifact_path = substring(normalized, nchar(root) + 2L),
    sha256 = vapply(artifact_files, function(file) digest::digest(
      file, algo = "sha256", file = TRUE, serialize = FALSE), character(1L)),
    bytes = as.numeric(file.info(artifact_files)$size)
  )
  .stage4a_pooling_v2_write_csv(manifest,
    file.path(output_dir, "publication_artifact_hashes_v2.csv"))
  invisible(list(report = report_file, manifest = manifest, tables = tables))
}
