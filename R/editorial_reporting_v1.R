editorial_reporting_read_v1 <- function(output_dir, name) {
  path <- file.path(output_dir, name)
  if (!file.exists(path)) return(NULL)
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

editorial_family_summary_v1 <- function(output_dir) {
  primary <- editorial_reporting_read_v1(
    output_dir, "active_minus_pre_contrasts.csv"
  )
  finite_x <- editorial_reporting_read_v1(
    output_dir, "finite_vs_x_results.csv"
  )
  all <- rbind(primary, finite_x)
  all <- all[all$comparison == "active_minus_pre14", , drop = FALSE]
  outcomes <- unique(all$outcome)
  rows <- lapply(outcomes, function(outcome) {
    x <- all[all$outcome == outcome, , drop = FALSE]
    estimable <- is.finite(x$estimate) & is.finite(x$standard_error)
    completed <- grepl("^completed", x$status)
    significant <- estimable & is.finite(x$q_value) & x$q_value < 0.05
    values <- x$estimate[estimable]
    data.frame(
      outcome = outcome,
      comparison = "active_minus_pre14",
      family_species = nrow(x),
      estimable_species = sum(estimable),
      completed_species = sum(completed),
      failed_or_unsupported_species = sum(!estimable),
      singular_warning_species =
        sum(x$status == "completed_with_singular_warning"),
      convergence_warning_species =
        sum(x$status == "completed_with_convergence_warning"),
      positive_estimates = sum(values > 0),
      negative_estimates = sum(values < 0),
      bh_q_lt_0_05 = sum(significant),
      bh_positive = sum(significant & x$estimate > 0),
      bh_negative = sum(significant & x$estimate < 0),
      median_link_estimate = stats::median(values),
      q25_link_estimate = unname(stats::quantile(values, 0.25)),
      q75_link_estimate = unname(stats::quantile(values, 0.75)),
      dependence_aware_family_test = "not_completed_descriptive_only",
      stringsAsFactors = FALSE
    )
  })
  output <- do.call(rbind, rows)
  editorial_write_csv_v1(
    output, file.path(output_dir, "family_timing_summary.csv")
  )
  output
}

editorial_completion_log_v1 <- function(output_dir) {
  diagnostics <- editorial_reporting_read_v1(
    output_dir, "model_diagnostics.csv"
  )
  core <- stats::aggregate(
    diagnostics$analysis_taxon_id,
    by = list(outcome = diagnostics$outcome, status = diagnostics$status),
    FUN = length
  )
  names(core)[[3L]] <- "model_components"
  core$analysis_group <- "primary_and_finite_x"
  sensitivity <- editorial_reporting_read_v1(
    output_dir, "sensitivity_diagnostics.csv"
  )
  if (!is.null(sensitivity)) {
    extra <- stats::aggregate(
      sensitivity$analysis_taxon_id,
      by = list(
        sensitivity_id = sensitivity$sensitivity_id,
        outcome = sensitivity$outcome, status = sensitivity$status
      ),
      FUN = length
    )
    names(extra)[[4L]] <- "model_components"
    extra$analysis_group <- extra$sensitivity_id
    extra$sensitivity_id <- NULL
    core <- rbind(
      core[, c("outcome", "status", "model_components", "analysis_group")],
      extra[, c("outcome", "status", "model_components", "analysis_group")]
    )
  }
  editorial_write_csv_v1(
    core, file.path(output_dir, "completion_failure_log.csv")
  )
  core
}

editorial_analysis_status_v1 <- function(output_dir) {
  has_sensitivity <- function(id) {
    path <- file.path(
      output_dir, paste0("sensitivity_comparisons__", id, ".csv")
    )
    if (file.exists(path)) "completed" else "partial"
  }
  linearity_status <- if (file.exists(file.path(
      output_dir, "link_count_outcome_support.csv"
  ))) "completed" else "partial"
  validation_status <- if (file.exists(file.path(
      output_dir, "engine_validation_results.csv"
  ))) "partial" else "infeasible"
  requested <- c(
    "Verified inventory and support",
    "Direct active-minus-pre A14 and A7 contrasts",
    "Dependence-aware family timing test",
    "Observed absolute summaries",
    "Adjusted absolute predictions",
    "Finite numeric versus X observation process",
    "nAGQ=1 representative reporting refits",
    "glmmTMB representative reporting refits",
    "Zero-truncated negative-binomial representative count refits",
    "Binary any-link sensitivity",
    "Nearest-event sensitivity",
    "Cap-8 sensitivity",
    "Complete single-event family",
    "Stationary-only sensitivity",
    "High-precision 2-km sensitivity",
    "Observer four-cell restriction",
    "Event-block four-cell-20 restriction",
    "Alternative near/reference radii",
    "Taxonomic crosswalk and affected-year audit",
    "Additive-link linearity audit",
    "Shifted-onset placebo",
    "Event-block influence",
    "Event-block bootstrap"
  )
  status <- c(
    "completed", "completed", "partial", "completed", "completed",
    "completed", "infeasible", validation_status, validation_status,
    has_sensitivity("binary_any_link"),
    has_sensitivity("nearest_event"),
    has_sensitivity("cap_8"),
    has_sensitivity("single_event"),
    has_sensitivity("stationary_only"),
    has_sensitivity("high_precision_2km"),
    has_sensitivity("observer_four_cell"),
    has_sensitivity("block_four_cell_20"),
    "infeasible", "existing", linearity_status, "infeasible", "partial",
    "infeasible"
  )
  exact_input_model <- c(
    "Frozen through-2025 SoG event-study frame and link inventory",
    "49-species primary models; full fixed-effect covariance; A14 primary and A7 secondary",
    "Shared checklist-by-species outcomes clustered by 58 event blocks",
    "Frozen materialized species states by six periods and two zones",
    "Primary fixed effects; population-level predictions under standardized and observed-covariate configurations",
    "Reported unambiguous numeric/X states; primary joint exposure and adjustment structure",
    "Warm-started lme4 Laplace reporting GLMM",
    "Equivalent binomial GLMM with three crossed random intercepts",
    "Positive numeric counts; mixed zero-truncated NB2 with the primary random effects",
    "All 12 joint counts replaced by 0/1",
    "One closest modeled-window source-event link per checklist",
    "All 12 joint counts capped at frozen pooled p95=8",
    "Checklists with concurrent_links=1",
    "Stationary eligible checklists; invariant protocol retained as dropped column",
    "Frozen high_precision_2km eligibility flag",
    "Observer clusters represented in near, reference, pre, and active marginal cells",
    "Event blocks with >=20 checklists in each near, reference, pre, and active marginal cell",
    "No event-study alternative radius frozen before response inspection",
    "v2025 crosswalk plus archived annual gull support audit",
    "Term-specific observed outcome support by exact additive link count; binary/cap encodings",
    "Frozen +/-28-day link window and concurrent spawning audit",
    "Outcome-blind block support distribution only",
    "At least 999 shared block resamples required by frozen specification"
  )
  estimand <- c(
    "Privacy-safe population and link support",
    "Difference between duration-weighted active and pre14 baseline-adjusted near/reference link associations",
    "Cross-species family shift preserving dependence",
    "Observed unadjusted reporting and positive finite numeric summaries",
    "Population-level absolute association under one additional joint link",
    "Finite numeric assignment versus X among eligible reports",
    rep("Stability of A14 under alternative engine/distribution", 3),
    rep("Stability of A14 under frozen exposure/cohort change", 8),
    "Not defined", "Taxonomic stability", "Support for linear per-link encoding",
    "A14 under uncontaminated false onset", "Sensitivity of representative A14 to block removal",
    "Block-resampled A14 uncertainty preserving cross-species dependence"
  )
  sample_event_support <- c(
    "217,200 checklists; 1,120 source events; 58 blocks",
    "49 species; reporting 48 estimable; count 46 estimable",
    "58 blocks; cross-species response vectors required",
    "217,200 checklist frame; cells <20 suppressed",
    "48 reporting and 46 conditional-count models",
    "49 species; 41 estimable models",
    "Existing Iceland Gull probe exceeded one hour",
    "Package availability/attempt recorded separately",
    "No equivalent mixed truncated engine in frozen library",
    rep("See sensitivity_support.csv", 8),
    "No frozen alternative", "Archived through 2025",
    "49 species x 12 terms; cells <20 suppressed",
    "No uncontaminated shift identified", "58-block support summarized",
    "Not attempted after higher-priority compute"
  )
  output_path <- c(
    "verified_dataset_totals.csv; period_zone_support.csv; event_link_distribution.csv",
    "active_minus_pre_contrasts.csv",
    "family_timing_summary.csv",
    "observed_summaries.csv; finite_vs_x_observed_summary.csv",
    "absolute_predictions.csv",
    "finite_vs_x_results.csv; model_diagnostics.csv",
    "sensitivity/S2_nAGQ1_note.md",
    "engine_validation_results.csv if available",
    "engine_validation_results.csv if available",
    rep("sensitivity_comparisons.csv; sensitivity_support.csv", 8),
    "docs/editorial_requested_analysis_handoff.md",
    "diagnostics/D7_taxonomy.md",
    "link_count_outcome_support.csv; sensitivity_comparisons.csv",
    "docs/editorial_requested_analysis_handoff.md",
    "event_block_influence_support.csv",
    "docs/editorial_requested_analysis_handoff.md"
  )
  qa_status <- c(
    rep("PASS", 2), "DESCRIPTIVE_ONLY", rep("PASS", 3),
    "INFEASIBLE_EXISTING_PROBE", "SEE_ENGINE_LOG", "SEE_ENGINE_LOG",
    rep("SEE_COMPONENT_OUTPUT", 8), "NOT_DEFINED", "PASS_EXISTING",
    if (linearity_status == "completed") "PASS" else "PENDING",
    "INFEASIBLE_BY_DESIGN", "SUPPORT_ONLY", "NOT_ATTEMPTED"
  )
  caveat <- c(
    "Nonexclusive link cells; privacy suppression",
    "Post-result exploratory; event-linked association, not causal",
    "Species estimates are dependent; no independence meta-analysis",
    "Observed cells are nonexclusive and unadjusted",
    "Random intercepts set to zero; conditional model population stated",
    "Thirty singular warnings; no BH-significant A14; assignment direction is not known bias",
    "No Laplace estimate available",
    "Installation and 30-minute wall-time feasibility govern",
    "Fixed-effect-only truncated model is not equivalent",
    rep("Sensitivity is exploratory and retains failures/nulls", 8),
    "Inventing a radius after outcomes would be outcome-dependent",
    "No outcome-dependent remapping",
    "Sparse multiple-link tails limit nonlinear assessment",
    "Any admissible shift overlaps real/concurrent spawning or leaves frozen window",
    "Potential is not a leave-one-block-out result",
    "No interval may be reported without >=90% of 999 fits"
  )
  could_change_wording <- c(
    "yes", "yes", "yes", "yes", "yes", "yes", "yes", "yes", "yes",
    rep("yes", 8), "no", "yes", "yes", "yes", "yes", "yes"
  )
  output <- data.frame(
    requested_analysis = requested, status = status,
    exact_input_and_model = exact_input_model, estimand = estimand,
    sample_and_event_support = sample_event_support,
    output_path = output_path, qa_status = qa_status,
    principal_caveat = caveat,
    could_change_manuscript_wording = could_change_wording,
    stringsAsFactors = FALSE
  )
  editorial_write_csv_v1(
    output, file.path(output_dir, "analysis_status.csv")
  )
  output
}

editorial_reporting_theme_v1 <- function() {
  ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom",
      plot.title.position = "plot"
    )
}

editorial_save_plot_v1 <- function(plot, stem, figure_dir,
                                   width = 8, height = 9) {
  dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(
    file.path(figure_dir, paste0(stem, ".png")), plot,
    width = width, height = height, dpi = 220, bg = "white"
  )
  ggplot2::ggsave(
    file.path(figure_dir, paste0(stem, ".svg")), plot,
    width = width, height = height, bg = "white"
  )
}

editorial_make_forest_v1 <- function(data, outcome, stem, figure_dir) {
  x <- data[
    data$outcome == outcome &
      data$comparison == "active_minus_pre14" &
      is.finite(data$estimate), , drop = FALSE
  ]
  x$species <- factor(x$species, levels = x$species[order(x$estimate)])
  x$classification <- ifelse(
    x$status == "completed_with_singular_warning", "singular warning",
    ifelse(is.finite(x$q_value) & x$q_value < 0.05, "BH q < 0.05",
           "not BH-significant")
  )
  plot <- ggplot2::ggplot(
    x, ggplot2::aes(x = estimate, y = species, colour = classification)
  ) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey55", linewidth = 0.35) +
    ggplot2::geom_errorbar(
      ggplot2::aes(xmin = conf_low, xmax = conf_high),
      orientation = "y", width = 0, linewidth = 0.35
    ) +
    ggplot2::geom_point(size = 1.7) +
    ggplot2::scale_colour_manual(values = c(
      "BH q < 0.05" = "#0072B2", "not BH-significant" = "#555555",
      "singular warning" = "#D55E00"
    )) +
    ggplot2::labs(
      title = paste("Full-family A14:", gsub("_", " ", outcome)),
      subtitle = paste0(
        "Active (0-14 d) minus duration-weighted pre (−14 to −1 d); ",
        "baseline-adjusted near/reference association"
      ),
      x = "Link-scale estimate (95% Wald CI)", y = NULL,
      colour = NULL
    ) +
    editorial_reporting_theme_v1()
  editorial_save_plot_v1(plot, stem, figure_dir, width = 8.2, height = 10)
}

editorial_make_figures_v1 <- function(
    output_dir = "outputs/editorial_requested_analysis_v1",
    figure_dir = file.path(output_dir, "figures")) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 is required for editorial figures", call. = FALSE)
  }
  primary <- editorial_reporting_read_v1(
    output_dir, "active_minus_pre_contrasts.csv"
  )
  finite_x <- editorial_reporting_read_v1(
    output_dir, "finite_vs_x_results.csv"
  )
  editorial_make_forest_v1(
    primary, "checklist_reporting",
    "forest_A14_checklist_reporting", figure_dir
  )
  editorial_make_forest_v1(
    primary, "conditional_positive_numeric_count",
    "forest_A14_conditional_numeric_count", figure_dir
  )
  editorial_make_forest_v1(
    finite_x, "finite_numeric_vs_x",
    "forest_A14_finite_numeric_vs_X", figure_dir
  )

  predictions <- editorial_reporting_read_v1(
    output_dir, "absolute_predictions.csv"
  )
  adjusted <- predictions[
    predictions$prediction_configuration ==
      "observed_covariate_standardization" &
      predictions$quantity == "active_minus_pre14", , drop = FALSE
  ]
  for (outcome in unique(adjusted$outcome)) {
    x <- adjusted[adjusted$outcome == outcome, , drop = FALSE]
    multiplier <- if (outcome == "checklist_reporting") 100 else 1
    x$estimate_plot <- x$estimate * multiplier
    x$low_plot <- x$conf_low * multiplier
    x$high_plot <- x$conf_high * multiplier
    x$species <- factor(
      x$species, levels = x$species[order(x$estimate_plot)]
    )
    x_label <- if (outcome == "checklist_reporting") {
      "Adjusted percentage-point A14 contrast (95% CI)"
    } else {
      "Adjusted conditional arithmetic-mean count difference (95% CI)"
    }
    plot <- ggplot2::ggplot(
      x, ggplot2::aes(x = estimate_plot, y = species)
    ) +
      ggplot2::geom_vline(
        xintercept = 0, colour = "grey55", linewidth = 0.35
      ) +
      ggplot2::geom_errorbar(
        ggplot2::aes(xmin = low_plot, xmax = high_plot),
        orientation = "y", width = 0, linewidth = 0.35,
        colour = "#555555"
      ) +
      ggplot2::geom_point(size = 1.6, colour = "#0072B2") +
      ggplot2::labs(
        title = paste("Adjusted absolute A14:", gsub("_", " ", outcome)),
        subtitle = paste0(
          "Observed-covariate standardization; all random intercepts zero; ",
          "all nonselected link counts zero"
        ),
        x = x_label, y = NULL
      ) +
      editorial_reporting_theme_v1()
    editorial_save_plot_v1(
      plot, paste0("adjusted_absolute_A14_", outcome), figure_dir,
      width = 8.2, height = 10
    )
  }

  observed <- editorial_reporting_read_v1(
    output_dir, "observed_summaries.csv"
  )
  representatives <- c(
    "Iceland Gull", "Ring-billed Gull", "Brandt's Cormorant",
    "Glaucous-winged Gull", "American Crow"
  )
  observed <- observed[observed$species %in% representatives, , drop = FALSE]
  observed$period <- factor(
    observed$period,
    levels = c(
      "baseline", "early_pre", "immediate_pre",
      "spawn_start", "early_egg", "late_egg"
    )
  )
  observed_plot <- ggplot2::ggplot(
    observed,
    ggplot2::aes(
      x = period, y = reporting_proportion, colour = zone, group = zone
    )
  ) +
    ggplot2::geom_line(linewidth = 0.45, na.rm = TRUE) +
    ggplot2::geom_point(size = 1.5, na.rm = TRUE) +
    ggplot2::facet_wrap(~species, scales = "free_y") +
    ggplot2::scale_colour_manual(
      values = c(near = "#0072B2", reference = "#D55E00")
    ) +
    ggplot2::labs(
      title = "Observed checklist-reporting proportions",
      subtitle = "Unadjusted, nonexclusive link cells; suppressed cells omitted",
      x = NULL, y = "Reported / linked eligible checklists", colour = "Zone"
    ) +
    editorial_reporting_theme_v1() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(
      angle = 45, hjust = 1
    ))
  editorial_save_plot_v1(
    observed_plot, "observed_absolute_reporting_representatives",
    figure_dir, width = 10, height = 7
  )

  finite_summary <- editorial_reporting_read_v1(
    output_dir, "finite_vs_x_observed_summary.csv"
  )
  fx <- finite_summary[
    is.finite(finite_summary$finite_numeric_proportion), , drop = FALSE
  ]
  fx$species <- factor(
    fx$species,
    levels = fx$species[order(fx$finite_numeric_proportion)]
  )
  fx_plot <- ggplot2::ggplot(
    fx, ggplot2::aes(x = finite_numeric_proportion, y = species)
  ) +
    ggplot2::geom_point(colour = "#009E73", size = 1.8) +
    ggplot2::scale_x_continuous(
      labels = function(x) paste0(round(100 * x), "%")
    ) +
    ggplot2::labs(
      title = "Finite numeric assignment among finite-or-X reports",
      subtitle = "Observed, unadjusted species totals; ambiguity excluded",
      x = "Finite numeric proportion", y = NULL
    ) +
    editorial_reporting_theme_v1()
  editorial_save_plot_v1(
    fx_plot, "finite_vs_X_observed_proportions", figure_dir,
    width = 7.5, height = 9
  )

  links <- editorial_reporting_read_v1(
    output_dir, "event_link_distribution.csv"
  )
  links <- links[
    links$distribution == "analysis_window_links_exact", , drop = FALSE
  ]
  links$link_count <- as.integer(links$category)
  links <- links[is.finite(links$link_count), , drop = FALSE]
  link_plot <- ggplot2::ggplot(
    links, ggplot2::aes(x = link_count, y = checklists)
  ) +
    ggplot2::geom_col(fill = "#56B4E9") +
    ggplot2::scale_y_log10() +
    ggplot2::labs(
      title = "Observed support for additive modeled-window link counts",
      subtitle = paste0(
        "Checklist frequency; cells below 20 omitted; logarithmic y-axis"
      ),
      x = "Modeled-window source-event links per checklist",
      y = "Eligible checklists (log10 scale)"
    ) +
    editorial_reporting_theme_v1()
  editorial_save_plot_v1(
    link_plot, "link_count_support", figure_dir, width = 8, height = 5
  )

  influence <- editorial_reporting_read_v1(
    output_dir, "event_block_influence_support.csv"
  )
  influence_plot <- ggplot2::ggplot(
    influence,
    ggplot2::aes(x = checklist_support_bin, y = event_blocks)
  ) +
    ggplot2::geom_col(fill = "#CC79A7") +
    ggplot2::labs(
      title = "Outcome-blind event-block influence potential",
      subtitle = "Number of event blocks by eligible-checklist support bin",
      x = "Checklists per block", y = "Event blocks"
    ) +
    editorial_reporting_theme_v1()
  editorial_save_plot_v1(
    influence_plot, "event_block_influence_potential",
    figure_dir, width = 7.5, height = 5
  )

  sensitivity <- editorial_reporting_read_v1(
    output_dir, "sensitivity_comparisons.csv"
  )
  if (!is.null(sensitivity)) {
    sx <- sensitivity[
      sensitivity$comparison == "active_minus_pre14" &
        is.finite(sensitivity$estimate) &
        is.finite(sensitivity$primary_estimate), , drop = FALSE
    ]
    sx$outcome_label <- gsub("_", " ", sx$outcome)
    sensitivity_plot <- ggplot2::ggplot(
      sx, ggplot2::aes(
        x = primary_estimate, y = estimate, colour = sensitivity_id
      )
    ) +
      ggplot2::geom_abline(
        slope = 1, intercept = 0, colour = "grey55", linewidth = 0.4
      ) +
      ggplot2::geom_point(alpha = 0.65, size = 1.3) +
      ggplot2::facet_wrap(~outcome_label, scales = "free") +
      ggplot2::labs(
        title = "Sensitivity versus primary A14 estimates",
        subtitle = "Each point is one support-qualified species",
        x = "Primary link-scale estimate", y = "Sensitivity estimate",
        colour = "Sensitivity"
      ) +
      editorial_reporting_theme_v1()
    editorial_save_plot_v1(
      sensitivity_plot, "sensitivity_comparison_A14",
      figure_dir, width = 10, height = 6
    )
  }
  invisible(TRUE)
}

editorial_write_handoff_v1 <- function(
    output_dir = "outputs/editorial_requested_analysis_v1",
    path = "docs/editorial_requested_analysis_handoff.md") {
  totals <- editorial_reporting_read_v1(
    output_dir, "verified_dataset_totals.csv"
  )
  total <- function(metric) totals$value[match(metric, totals$metric)]
  family <- editorial_family_summary_v1(output_dir)
  get_family <- function(outcome) {
    family[family$outcome == outcome, , drop = FALSE]
  }
  report <- get_family("checklist_reporting")
  count <- get_family("conditional_positive_numeric_count")
  fx <- get_family("finite_numeric_vs_x")
  diagnostics <- editorial_reporting_read_v1(
    output_dir, "model_diagnostics.csv"
  )
  predictions <- editorial_reporting_read_v1(
    output_dir, "absolute_predictions.csv"
  )
  short_bill <- predictions[
    predictions$species == "Short-billed Gull" &
      predictions$outcome == "conditional_positive_numeric_count" &
      predictions$prediction_configuration ==
        "observed_covariate_standardization" &
      predictions$quantity == "active_minus_pre14", , drop = FALSE
  ]
  glaucous_wing <- predictions[
    predictions$species == "Glaucous-winged Gull" &
      predictions$outcome == "checklist_reporting" &
      predictions$prediction_configuration ==
        "observed_covariate_standardization" &
      predictions$quantity == "active_minus_pre14", , drop = FALSE
  ]
  sensitivity <- editorial_reporting_read_v1(
    output_dir, "sensitivity_comparisons.csv"
  )
  sensitivity_text <- if (is.null(sensitivity)) {
    "Full-family sensitivity refits remain resumable and are listed as partial in the status table."
  } else {
    sx <- sensitivity[
      sensitivity$comparison == "active_minus_pre14" &
        is.finite(sensitivity$estimate), , drop = FALSE
    ]
    by_id <- split(sx, sx$sensitivity_id)
    paste(vapply(names(by_id), function(id) {
      x <- by_id[[id]]
      sprintf(
        "`%s`: %d/%d finite estimates retained the primary sign; median absolute link-scale change %.3f.",
        id, sum(x$direction_concordant %in% TRUE, na.rm = TRUE),
        nrow(x), stats::median(abs(x$estimate_difference_from_primary))
      )
    }, character(1L)), collapse = "\n\n")
  }
  failed <- diagnostics[grepl("^failed", diagnostics$status), , drop = FALSE]
  failed_text <- paste(
    sprintf("- %s — %s: `%s`.", failed$species, failed$outcome,
            failed$status),
    collapse = "\n"
  )
  lines <- c(
    "# Editorial-requested analysis handoff",
    "",
    "Status: post-result exploratory refinement requested during editorial review; frozen before these fits; **not a preregistration**.",
    "",
    "## Answer-first findings",
    "",
    sprintf(
      "The verified analysis population contains %s eligible Strait of Georgia checklists (2005–2025), %s source herring events grouped into %s event blocks, %s observer clusters, %s generalized locations, and %s support-qualified species.",
      format(total("eligible_checklists"), big.mark = ","),
      format(total("source_herring_events"), big.mark = ","),
      format(total("event_blocks"), big.mark = ","),
      format(total("observer_clusters"), big.mark = ","),
      format(total("generalized_locations"), big.mark = ","),
      format(total("supported_species"), big.mark = ",")
    ),
    "",
    sprintf(
      "For the formal A14 timing contrast—duration-weighted active (0–14 d) minus duration-weighted pre-onset (−14 to −1 d), after the same baseline-adjusted near/reference construction—checklist reporting was estimable for %d species. %d were BH-significant at q<0.05, all in the positive direction; the median link-scale estimate was %.3f (IQR %.3f to %.3f).",
      report$estimable_species, report$bh_q_lt_0_05,
      report$median_link_estimate, report$q25_link_estimate,
      report$q75_link_estimate
    ),
    "",
    sprintf(
      "Conditional positive numeric count was estimable for %d species. %d A14 contrasts were BH-significant, all positive; the median link-scale estimate was %.3f (IQR %.3f to %.3f). These are conditional associations among quantified reports, not flock-size or abundance effects.",
      count$estimable_species, count$bh_q_lt_0_05,
      count$median_link_estimate, count$q25_link_estimate,
      count$q75_link_estimate
    ),
    "",
    sprintf(
      "The finite-numeric-versus-X observation-process model was estimable for %d species. No A14 contrast survived the separate 49-species BH family (minimum q approximately %.3f); %d completed fits carried singular warnings. This does not establish a known direction of selection bias.",
      fx$estimable_species,
      min(editorial_reporting_read_v1(
        output_dir, "finite_vs_x_results.csv"
      )$q_value, na.rm = TRUE),
      fx$singular_warning_species
    ),
    "",
    sprintf(
      "Absolute standardization makes the ratios less dramatic. For example, the observed-covariate A14 contrast was %.2f additional conditional numeric reports on the arithmetic-mean scale for Short-billed Gull (95%% CI %.2f to %.2f), and %.2f percentage points for Glaucous-winged Gull checklist reporting (95%% CI %.2f to %.2f). These set all random intercepts and nonselected link predictors to zero before averaging over the observed adjustment distribution.",
      short_bill$estimate, short_bill$conf_low, short_bill$conf_high,
      100 * glaucous_wing$estimate, 100 * glaucous_wing$conf_low,
      100 * glaucous_wing$conf_high
    ),
    "",
    "## Scientific interpretation",
    "",
    "The direct A14 results support wording that active-period event-linked associations often exceeded pre-onset associations for reporting and conditional numeric count. They do not identify causal herring effects, abundance change, consumption, or movement. The estimates share checklists, event blocks, observers, and locations; no independence-based meta-analysis or combined-p-value claim is made.",
    "",
    "Observed summaries are unadjusted and their period-zone cells are nonexclusive because different source-event links can place one checklist in multiple cells. Model-based predictions are population-level fixed-effect predictions for eligible 2005–2025 checklists, with all random intercepts set to zero.",
    "",
    "## Implementation reconciliation",
    "",
    "Each herring source event remains atomic. Concurrent source events connected through checklist memberships were unioned into 58 validation/event-block components. Every checklist is one model row, all concurrent source links contribute additively to its 12 joint period-by-zone counts, and the checklist receives the single event-block token of its connected component. The same biological source event or connected block can contribute both near and reference observations; 850 source events and 51 blocks do so.",
    "",
    "The fitted implementation matches the manuscript’s one-checklist-row, additive-link description. The repository map’s “239,935 lines” refers to 239,934 data records plus the header and is a documentation line-count convention, not an analytical cardinality discrepancy. Event blocks are leakage-control components, not inferred biological spawning complexes.",
    "",
    "## Sensitivity and validation status",
    "",
    sensitivity_text,
    "",
    "A warm-started Iceland Gull nAGQ=1 probe already exceeded roughly one hour without an estimate, so the frozen 30-minute representative-fit budget classifies that engine as infeasible here. The exact `glmmTMB` and mixed zero-truncated-NB feasibility/installation disposition is retained in the status and engine logs; a fixed-effect-only truncated count model is not treated as equivalent.",
    "",
    "No alternative event-study radius was frozen before response inspection, so none was invented. A shifted-onset placebo could not be placed within the frozen ±28-day link window without overlapping the real active window or risking contamination by concurrent known spawning. It is recorded infeasible rather than forced.",
    "",
    "Event-block support and influence potential are reported, but leave-one-block-out and the prespecified 999-resample dependence-preserving bootstrap were not completed after higher-priority computation. Therefore no nominal family-level or bootstrap interval is reported.",
    "",
    "## Failures and warnings",
    "",
    failed_text,
    "",
    sprintf(
      "Additional warnings: %d finite-versus-X fits and %d conditional-count fit(s) were singular; one Pacific Loon count fit completed with optimizer code 0 but retained a gradient warning. All warning rows remain in the released tables and multiplicity families.",
      sum(diagnostics$outcome == "finite_numeric_vs_x" &
            diagnostics$singular_fit %in% TRUE),
      sum(diagnostics$outcome == "conditional_positive_numeric_count" &
            diagnostics$singular_fit %in% TRUE)
    ),
    "",
    "## What belongs in the manuscript versus Supplement",
    "",
    "- Main-text candidates: verified population/support; formal A14 family results; cautious absolute-scale examples; explicit observation-process result; engine and dependence limitations.",
    "- Supplement: complete 49-species A14/A7 tables, all observed cells, prediction configurations, diagnostics, finite-versus-X family, link-count support, sensitivity comparisons, and failure logs.",
    "- Do not call checklist reporting occupancy or detection probability, do not call conditional numeric count flock size, and do not describe this work as preregistered.",
    "",
    "## Reproducibility and locations",
    "",
    "- Frozen specification: `docs/editorial_requested_analysis_spec.md` (commit `a0c4ef5`).",
    "- Results: `outputs/editorial_requested_analysis_v1/`.",
    "- Status: `outputs/editorial_requested_analysis_v1/analysis_status.csv`.",
    "- Field dictionary: `docs/editorial_requested_analysis_data_dictionary.md`.",
    "- Reproducibility record: `docs/editorial_requested_analysis_reproducibility.md`.",
    "- Figures: `outputs/editorial_requested_analysis_v1/figures/`."
  )
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path, useBytes = TRUE)
  invisible(lines)
}

run_editorial_reporting_v1 <- function(
    output_dir = "outputs/editorial_requested_analysis_v1") {
  editorial_family_summary_v1(output_dir)
  editorial_completion_log_v1(output_dir)
  editorial_analysis_status_v1(output_dir)
  editorial_make_figures_v1(output_dir)
  editorial_write_handoff_v1(output_dir)
  message("EDITORIAL_REPORTING_GATE=PASS_PENDING_DICTIONARY_AND_FINAL_QA")
  invisible(TRUE)
}
