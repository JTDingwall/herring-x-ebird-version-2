editorial_field_descriptions_v1 <- function() {
  c(
    analysis_version = "Version identifier for the analysis that produced the row.",
    analysis_taxon_id = "Privacy-safe stable analysis taxon token; not an eBird record identifier.",
    species = "English common name under the frozen v2025 taxonomy crosswalk.",
    outcome = "Modeled observation process: checklist reporting, conditional positive numeric count, or finite numeric versus X.",
    comparison = "Compound timing contrast: A14 active-minus-pre14 or secondary A7 active-minus-pre7.",
    primary_comparison = "TRUE for the frozen primary A14 comparison.",
    active_estimate = "Duration-weighted active-period baseline-adjusted near/reference estimate on the link scale.",
    active_standard_error = "Standard error of active_estimate from the full fixed-effect covariance matrix.",
    pre_estimate = "Pre-onset baseline-adjusted near/reference estimate on the link scale.",
    pre_standard_error = "Standard error of pre_estimate from the full fixed-effect covariance matrix.",
    active_pre_covariance = "Estimated covariance between the active and pre compound contrasts.",
    estimate = "Compound contrast estimate on the fitted link scale, or the named absolute prediction quantity.",
    standard_error = "Standard error of estimate.",
    conf_low = "Lower bound of the two-sided 95% confidence interval.",
    conf_high = "Upper bound of the two-sided 95% confidence interval.",
    ratio = "Exponentiated link-scale contrast estimate.",
    ratio_conf_low = "Lower 95% confidence bound after exponentiation.",
    ratio_conf_high = "Upper 95% confidence bound after exponentiation.",
    p_value = "Two-sided Wald p-value; blank when the model or contrast is not estimable.",
    q_value = "Benjamini-Hochberg adjusted p-value within the stated outcome-by-comparison family.",
    n = "Privacy-safe number of rows used by the fitted model; counts below 20 are suppressed.",
    full_covariance_used = "Whether all fixed-effect variance and covariance terms were used for the compound contrast.",
    status = "Completion, warning, failure, support, or feasibility classification.",
    multiplicity_family = "Exact family within which BH adjustment was applied.",
    engine = "Model-fitting engine, likelihood family, and approximation.",
    event_blocks = "Number of represented leakage-control event-block random-effect levels; counts below 20 are suppressed.",
    observer_clusters = "Number of represented privacy-safe observer-cluster levels; counts below 20 are suppressed.",
    generalized_locations = "Number of represented generalized-location random-effect levels; counts below 20 are suppressed.",
    converged = "Whether the fitted model met the repository convergence classification.",
    singular_fit = "Whether one or more fitted random-effect variance components were on the boundary at tolerance 1e-4.",
    rank_deficient = "Whether the fixed-effect model matrix lost rank.",
    optimizer_code = "Native optimizer return code; zero means the optimizer completed.",
    positive_definite_hessian = "Whether the glmmTMB standard-error Hessian was positive definite.",
    convergence_message = "Truncated optimizer or lme4 convergence message.",
    maximum_absolute_gradient = "Maximum absolute raw derivative component reported by the fitted model.",
    event_block_variance = "Estimated variance of the event-block random intercept.",
    observer_variance = "Estimated variance of the observer-cluster random intercept.",
    location_variance = "Estimated variance of the generalized-location random intercept.",
    residual_variance = "Estimated residual variance for the log-Gaussian count model; blank for binomial models.",
    dispersion_parameter = "Estimated glmmTMB negative-binomial dispersion parameter; nonapplicable to the binomial validation.",
    reproduction_max_abs_estimate_difference = "Maximum absolute difference from matching frozen historical component estimates.",
    term = "Joint period-by-zone exposure predictor name.",
    exposed_rows = "Model rows with a positive value of the named exposure term; counts below 20 are suppressed.",
    finite_numeric_rows = "Finite-numeric model rows exposed in the named term; counts below 20 are suppressed.",
    unquantified_x_rows = "Unquantified-X model rows exposed in the named term; counts below 20 are suppressed.",
    prediction_configuration = "Standardized profile or observed-covariate standardization.",
    quantity = "Named predicted level or compound absolute-scale contrast.",
    interval_method = "Method used to propagate fixed-effect covariance to the 95% interval.",
    random_effect_handling = "How random effects were treated in prediction.",
    covariate_handling = "Values or distribution used for non-exposure covariates.",
    population = "Population to which the prediction configuration applies.",
    metric = "Name of an inventory quantity.",
    value = "Verified numerical value of the inventory quantity.",
    unit = "Unit associated with value.",
    scope = "Population and time scope of the inventory row.",
    qa_status = "QA disposition for the row or requested analysis.",
    period = "Frozen event-study temporal period.",
    zone = "Frozen spatial zone: near 0 to <5 km or reference 5 to 20 km.",
    checklists = "Privacy-safe number of eligible checklists in the category.",
    event_links = "Number of source-event-to-checklist links in the category.",
    source_events = "Number of distinct source herring events represented in the category.",
    distribution = "Link-count distribution being summarized.",
    category = "Exact or grouped link-count category.",
    proportion = "Share of the distribution total in the category.",
    checklist_support_bin = "Outcome-blind bin of eligible-checklist support per event block.",
    influence_basis = "Statement that block influence potential uses support only and no response inspection.",
    checklist_denominator = "Linked eligible checklists contributing to the nonexclusive observed cell.",
    reported_checklists = "Eligible linked checklists reporting the species; counts below 20 are suppressed.",
    reporting_proportion = "Observed unadjusted reported_checklists divided by checklist_denominator.",
    finite_numeric_reports = "Reported occurrences stored as exact positive finite numeric counts; counts below 20 are suppressed.",
    unquantified_x_reports = "Reported occurrences stored as unquantified X; counts below 20 are suppressed.",
    lower_bound_reports = "Reported occurrences stored as lower-bound counts; counts below 20 are suppressed.",
    other_reported_states = "Reported occurrences in retained states other than finite numeric, X, or lower bound.",
    finite_numeric_proportion_among_reports = "Observed share of reported occurrences with a positive finite numeric count.",
    x_proportion_among_reports = "Observed share of reported occurrences recorded as X.",
    positive_finite_count_q25 = "Observed first quartile of positive finite numeric counts.",
    positive_finite_count_median = "Observed median of positive finite numeric counts.",
    positive_finite_count_q75 = "Observed third quartile of positive finite numeric counts.",
    observed_unadjusted = "TRUE when the row is a descriptive, unadjusted summary.",
    suppressed_below_20 = "Whether the applicable cell was suppressed for having fewer than 20 rows.",
    reported_occurrences = "All reported occurrences before restriction to finite numeric or X states.",
    finite_vs_x_denominator = "Unambiguous reported occurrences eligible for the finite-numeric-versus-X comparison.",
    finite_numeric_proportion = "Observed finite-numeric share of the finite-or-X denominator, released only with support in both classes.",
    file = "Repository-relative output file included in the hash manifest.",
    sha256 = "SHA-256 digest of the exact file bytes.",
    sensitivity_id = "Frozen identifier for the exposure encoding or cohort restriction.",
    sensitivity_q_value = "BH-adjusted p-value within the sensitivity, outcome, and comparison family.",
    primary_estimate = "Matching primary A14/A7 link-scale estimate.",
    primary_standard_error = "Standard error of the matching primary estimate.",
    primary_conf_low = "Lower 95% confidence bound for the matching primary estimate.",
    primary_conf_high = "Upper 95% confidence bound for the matching primary estimate.",
    primary_ratio = "Exponentiated matching primary estimate.",
    primary_ratio_conf_low = "Lower exponentiated 95% confidence bound for the primary estimate.",
    primary_ratio_conf_high = "Upper exponentiated 95% confidence bound for the primary estimate.",
    primary_q_value = "BH-adjusted p-value for the matching primary estimate.",
    primary_status = "Completion or warning status of the matching primary model.",
    estimate_difference_from_primary = "Sensitivity estimate minus matching primary estimate on the link scale.",
    direction_concordant = "Whether the sensitivity and primary link-scale estimates have the same sign.",
    model_n = "Privacy-safe row count used by the sensitivity model.",
    model_event_blocks = "Event-block random-effect levels represented in the sensitivity model.",
    model_observer_clusters = "Observer-cluster random-effect levels represented in the sensitivity model.",
    model_generalized_locations = "Generalized-location random-effect levels represented in the sensitivity model.",
    retained_checklists = "Eligible checklists retained after the outcome-blind sensitivity transformation.",
    retained_fraction = "retained_checklists divided by the 217,200-checklist primary frame.",
    changed_component = "Exact exposure encoding or cohort component changed by the sensitivity.",
    transformed_event_link_total = "Sum of the 12 transformed joint link predictors across retained checklists.",
    checklists_with_transformed_links = "Retained checklists with at least one positive transformed exposure term.",
    maximum_transformed_link_total = "Maximum row sum of transformed joint exposure terms.",
    unchanged_components = "Model components explicitly held fixed in the sensitivity.",
    response_fields_read_for_transform = "Count of response fields used to define the outcome-blind transformation; required to be zero.",
    link_count = "Exact additive source-event-link count for the named term.",
    checklist_rows = "Eligible rows at the exact link count; suppressed below 20.",
    positive_finite_numeric_reports = "Rows at the exact link count with a reported positive finite numeric count.",
    positive_finite_numeric_median = "Observed median positive finite numeric count at the exact link count.",
    requested_analysis = "Editorial-requested analysis component.",
    exact_input_and_model = "Concise specification of the exact input, transformation, and model.",
    estimand = "Quantity targeted by the requested analysis.",
    sample_and_event_support = "Verified or referenced checklist, species, event, or block support.",
    output_path = "Repository-relative artifact path.",
    principal_caveat = "Most important limitation on interpretation.",
    could_change_manuscript_wording = "Whether the component could materially affect manuscript wording.",
    family_species = "Species rows in the frozen inferential family.",
    estimable_species = "Species with finite compound estimate and standard error.",
    completed_species = "Species whose model status begins with completed.",
    failed_or_unsupported_species = "Species without a finite compound estimate.",
    singular_warning_species = "Completed species models carrying a singular-fit warning.",
    convergence_warning_species = "Completed species models carrying a convergence warning.",
    positive_estimates = "Finite compound estimates above zero.",
    negative_estimates = "Finite compound estimates below zero.",
    bh_q_lt_0_05 = "Finite estimates with BH q-value below 0.05.",
    bh_positive = "BH-significant estimates above zero.",
    bh_negative = "BH-significant estimates below zero.",
    median_link_estimate = "Median finite compound estimate on the link scale.",
    q25_link_estimate = "First quartile of finite compound estimates on the link scale.",
    q75_link_estimate = "Third quartile of finite compound estimates on the link scale.",
    dependence_aware_family_test = "Disposition of the cross-species dependence-aware family test.",
    model_components = "Number of species-by-outcome model components in the status group.",
    analysis_group = "Primary/finite-X family or named sensitivity to which the status count applies.",
    check = "Name of a deterministic QA gate.",
    observed = "Value observed by the QA gate.",
    expected = "Required value or range for the QA gate.",
    tolerance = "Absolute numerical tolerance where applicable."
  )
}

editorial_table_descriptions_v1 <- function() {
  c(
    "verified_dataset_totals.csv" = "Verified privacy-safe population and model inventory.",
    "period_zone_support.csv" = "Checklist, source-event-link, and source-event support by frozen period and zone.",
    "event_link_distribution.csv" = "Exact and grouped additive source-event-link distributions.",
    "active_minus_pre_contrasts.csv" = "Complete 49-species primary A14 and secondary A7 contrast results for both primary outcomes.",
    "observed_summaries.csv" = "Observed unadjusted species summaries in each nonexclusive period-zone cell.",
    "finite_vs_x_observed_summary.csv" = "Species totals and class support for finite numeric versus X assignment.",
    "finite_vs_x_results.csv" = "Complete 49-species exploratory finite-numeric-versus-X A14 and A7 results.",
    "absolute_predictions.csv" = "Adjusted absolute levels and contrasts under two documented prediction configurations.",
    "model_diagnostics.csv" = "Fit, convergence, gradient, rank, singularity, and random-effect diagnostics.",
    "model_term_support.csv" = "Outcome-specific support for every joint exposure term.",
    "event_block_influence_support.csv" = "Outcome-blind distribution of event-block checklist support.",
    "sensitivity_comparisons.csv" = "Sensitivity A14/A7 estimates joined to matching primary estimates.",
    "sensitivity_diagnostics.csv" = "Model diagnostics for completed full-family sensitivities.",
    "sensitivity_support.csv" = "Outcome-blind retained cohort and transformed-link support by sensitivity.",
    "link_count_outcome_support.csv" = "Privacy-suppressed observed outcome support at each exact term-specific link count.",
    "family_timing_summary.csv" = "Descriptive full-family A14 sign, BH, and distribution summary.",
    "completion_failure_log.csv" = "Complete model-component counts by outcome, status, and analysis group.",
    "analysis_status.csv" = "Machine-readable disposition of every editorial request.",
    "engine_validation_results.csv" = "Representative glmmTMB A14/A7 estimates joined to their primary counterparts.",
    "engine_validation_diagnostics.csv" = "Convergence, Hessian, gradient, dispersion, and random-effect diagnostics for representative glmmTMB fits.",
    "qa_summary.csv" = "Deterministic checkpoint, algebra, key, holdout, and privacy QA results.",
    "output_hash_manifest.csv" = "SHA-256 manifest for released editorial output files."
  )
}

run_editorial_dictionary_v1 <- function(
    output_dir = "outputs/editorial_requested_analysis_v1",
    path = "docs/editorial_requested_analysis_data_dictionary.md") {
  table_descriptions <- editorial_table_descriptions_v1()
  field_descriptions <- editorial_field_descriptions_v1()
  tables <- names(table_descriptions)
  tables <- tables[file.exists(file.path(output_dir, tables))]
  lines <- c(
    "# Editorial-requested analysis data dictionary",
    "",
    "All tables are privacy-safe aggregates or model summaries. Blank numeric fields indicate suppression, non-estimability, or nonapplicability as specified by the row status. No table contains checklist, observer, event, block, locality, or coordinate identifiers.",
    ""
  )
  dictionary_rows <- list()
  row_index <- 0L
  for (table in tables) {
    data <- utils::read.csv(
      file.path(output_dir, table), stringsAsFactors = FALSE,
      check.names = FALSE, nrows = 50L
    )
    unknown <- setdiff(names(data), names(field_descriptions))
    if (length(unknown)) {
      stop(
        "EDITORIAL_DICTIONARY_GATE: missing field descriptions: ",
        paste(unknown, collapse = ", "), call. = FALSE
      )
    }
    lines <- c(
      lines, paste0("## `", table, "`"), "",
      table_descriptions[[table]], "",
      "| Field | R type | Definition |",
      "|---|---|---|"
    )
    for (field in names(data)) {
      type <- class(data[[field]])[[1L]]
      description <- field_descriptions[[field]]
      lines <- c(
        lines,
        paste0("| `", field, "` | ", type, " | ", description, " |")
      )
      row_index <- row_index + 1L
      dictionary_rows[[row_index]] <- data.frame(
        table = table, field = field, r_type = type,
        description = description, stringsAsFactors = FALSE
      )
    }
    lines <- c(lines, "")
  }
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path, useBytes = TRUE)
  rows <- do.call(rbind, dictionary_rows)
  editorial_write_csv_v1(
    rows, file.path(output_dir, "data_dictionary.csv")
  )
  message("EDITORIAL_DATA_DICTIONARY_GATE=PASS fields=", nrow(rows))
  invisible(rows)
}
