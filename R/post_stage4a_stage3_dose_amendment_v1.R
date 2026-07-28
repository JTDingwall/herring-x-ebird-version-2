stage3_dose_amendment_gate_v1 <- function(
    path = "metadata/post_stage4a_stage3_dose_amendment_v1.yml") {
  if (!file.exists(path)) {
    stop("STAGE3_DOSE_AMENDMENT_GATE: record absent", call. = FALSE)
  }
  amendment <- yaml::read_yaml(path)
  if (
    !identical(
      amendment$amendment_version,
      "post_stage4a_stage3_dose_amendment_v1"
    ) ||
      !identical(amendment$reason$surface_observed_events, 68L) ||
      !identical(amendment$reason$dive_observed_events, 950L) ||
      !identical(
        amendment$missing_component_reconciliation$
          linked_candidate_events_with_no_recorded_component,
        125L
      ) ||
      !identical(
        amendment$replacement_method_sensitivity$method,
        "dive_only"
      )
  ) {
    stop("STAGE3_DOSE_AMENDMENT_GATE: record mismatch", call. = FALSE)
  }
  invisible(amendment)
}

.stage3_dose_load_inputs_pre_amendment_v1 <-
  stage3_dose_load_inputs_v1

stage3_dose_analysis_index_audit_v1 <- function(inputs) {
  tokens <- as.character(inputs$base_events$analysis_event_token)
  links <- inputs$anchored_links[
    as.character(inputs$anchored_links$analysis_event_token) %in% tokens,
    ,
    drop = FALSE
  ]
  candidate <- unique(links[, c(
    "dose_event_token__", "score_status", "survey_method_group",
    "relative_spawn_index_t", "log_index", "event_length_m",
    "event_extent_m2"
  )])
  if (anyDuplicated(candidate$dose_event_token__)) {
    stop(
      "STAGE3_DOSE_AMENDED_EVENT_GATE: event attributes disagree",
      call. = FALSE
    )
  }
  expected <- c(
    linked_candidate_events = 1120L,
    no_recorded_component = 125L,
    positive_scored_event = 995L,
    dive_only = 950L,
    surface_only = 68L,
    incomplete_only = 102L
  )
  observed <- c(
    linked_candidate_events = nrow(candidate),
    no_recorded_component =
      sum(candidate$score_status == "no_recorded_component"),
    positive_scored_event =
      sum(candidate$score_status == "positive_scored_event"),
    dive_only = sum(candidate$survey_method_group == "dive_only"),
    surface_only = sum(
      candidate$survey_method_group == "surface_only"
    ),
    incomplete_only = sum(
      candidate$survey_method_group == "incomplete_only"
    )
  )
  if (!identical(as.integer(observed), as.integer(expected))) {
    stop(
      "STAGE3_DOSE_AMENDED_EVENT_GATE: linked event counts changed",
      call. = FALSE
    )
  }
  positive <- candidate[
    candidate$score_status == "positive_scored_event", , drop = FALSE
  ]
  if (
    any(!is.finite(positive$log_index)) ||
      any(is.finite(candidate$log_index[
        candidate$score_status == "no_recorded_component"
      ]))
  ) {
    stop(
      "STAGE3_DOSE_AMENDED_MISSING_COMPONENT_GATE: logging rule failed",
      call. = FALSE
    )
  }
  quantiles <- stats::quantile(
    positive$relative_spawn_index_t,
    probs = c(0, 0.25, 0.5, 0.75, 1),
    names = FALSE, type = 7
  )
  distribution <- data.frame(
    audit_section = "linked_analysis_event_index_distribution",
    method_group = "all",
    metric = c("minimum", "q25", "median", "q75", "maximum"),
    value = as.numeric(quantiles), count = NA_real_,
    count_suppressed_below_20 = FALSE,
    definition = "positive scored events among 1120 linked candidates",
    stringsAsFactors = FALSE
  )
  counts_raw <- c(
    aggregated_events = nrow(candidate),
    events_no_recorded_component =
      sum(candidate$score_status == "no_recorded_component"),
    nonpositive_scored_events =
      sum(candidate$score_status == "nonpositive_scored_event"),
    positive_scored_events =
      sum(candidate$score_status == "positive_scored_event"),
    multirow_events = 0L,
    dive_observed_events =
      sum(candidate$survey_method_group == "dive_only"),
    surface_observed_events =
      sum(candidate$survey_method_group == "surface_only"),
    incomplete_method_events =
      sum(candidate$survey_method_group == "incomplete_only")
  )
  definitions <- c(
    "unique frozen spawn events linked to eligible SoG 2005-2025 checklists",
    "unscorable; displayed 0.00 descriptively but dropped before logging",
    "recorded component present but nonpositive; dropped before logging",
    "positive finite index and eligible for log transformation",
    "event key has one frozen survey row for every linked event",
    "84.8 percent consistent-majority method set",
    "6.1 percent minority method set; sensitivity non-estimable",
    "method-incomplete linked event set"
  )
  counts <- data.frame(
    audit_section = "linked_analysis_event_counts",
    method_group = "all", metric = names(counts_raw),
    value = NA_real_,
    count = stage3_dose_release_count_v1(counts_raw),
    count_suppressed_below_20 =
      counts_raw > 0L & counts_raw < 20L,
    definition = definitions,
    stringsAsFactors = FALSE
  )
  cross <- data.table::as.data.table(candidate)[
    , .(count__ = .N),
    by = .(survey_method_group, score_status)
  ]
  cross_rows <- data.frame(
    audit_section = "linked_method_score_status_cross_tab",
    method_group = cross$survey_method_group,
    metric = cross$score_status, value = NA_real_,
    count = stage3_dose_release_count_v1(cross$count__),
    count_suppressed_below_20 =
      cross$count__ > 0L & cross$count__ < 20L,
    definition =
      "1120 linked candidates; no-component events are not zero spawn",
    stringsAsFactors = FALSE
  )
  method <- data.table::as.data.table(positive)[, .(
    count__ = .N,
    minimum = min(relative_spawn_index_t),
    q25 = stats::quantile(
      relative_spawn_index_t, 0.25, names = FALSE
    ),
    median = stats::median(relative_spawn_index_t),
    q75 = stats::quantile(
      relative_spawn_index_t, 0.75, names = FALSE
    ),
    maximum = max(relative_spawn_index_t)
  ), by = survey_method_group]
  method_rows <- do.call(rbind, lapply(seq_len(nrow(method)), function(i) {
    data.frame(
      audit_section = "linked_method_index_distribution",
      method_group = method$survey_method_group[[i]],
      metric = c("minimum", "q25", "median", "q75", "maximum"),
      value = as.numeric(method[i, c(
        "minimum", "q25", "median", "q75", "maximum"
      )]),
      count = stage3_dose_release_count_v1(method$count__[[i]]),
      count_suppressed_below_20 = method$count__[[i]] < 20L,
      definition = "positive scored linked candidate events",
      stringsAsFactors = FALSE
    )
  }))
  classified <- post_stage4a_classify_links_v1(links)
  window_links <- links[!is.na(classified$period), , drop = FALSE]
  window_events <- unique(window_links[, c(
    "dose_event_token__", "score_status", "survey_method_group"
  )])
  window_raw <- c(
    start_anchor_window_events = nrow(window_events),
    start_anchor_window_no_component_events = sum(
      window_events$score_status == "no_recorded_component"
    ),
    start_anchor_window_positive_scored_events = sum(
      window_events$score_status == "positive_scored_event"
    ),
    candidate_no_component_events_outside_start_window =
      expected[["no_recorded_component"]] -
      sum(window_events$score_status == "no_recorded_component"),
    start_anchor_window_dive_events = sum(
      window_events$survey_method_group == "dive_only"
    ),
    start_anchor_window_positive_dive_events = sum(
      window_events$survey_method_group == "dive_only" &
        window_events$score_status == "positive_scored_event"
    )
  )
  window <- data.frame(
    audit_section = "start_anchor_window_reconciliation",
    method_group = "all", metric = names(window_raw),
    value = NA_real_,
    count = stage3_dose_release_count_v1(window_raw),
    count_suppressed_below_20 =
      window_raw > 0L & window_raw < 20L,
    definition = c(
      "linked candidates retaining at least one -28 to +28 day start-anchor link",
      "dropped from every log-index and dose calculation",
      "events entering the real-anchor dose-scored link set",
      "linked candidates shifted outside model-period support",
      "dive candidates retaining a start-anchor model-period link",
      "positive dive events entering the dive-only dose-scored link set"
    ),
    stringsAsFactors = FALSE
  )
  link_audit <- stage3_dose_link_audit_v1(window_links)
  rbind(
    distribution, counts, cross_rows, method_rows, window, link_audit
  )
}

stage3_dose_load_inputs_v1 <- function(herring_path) {
  inputs <- .stage3_dose_load_inputs_pre_amendment_v1(herring_path)
  inputs$index_audit <- stage3_dose_analysis_index_audit_v1(inputs)
  inputs
}

.stage3_dose_sensitivity_table_pre_amendment_v1 <-
  stage3_dose_sensitivity_table_v1

stage3_dose_sensitivity_table_v1 <- function(
    sensitivity, real, label, extra = list()) {
  if (identical(label, "surface_only")) label <- "dive_only"
  out <- .stage3_dose_sensitivity_table_pre_amendment_v1(
    sensitivity, real, label, extra
  )
  out$linked_candidate_events <- 950L
  out$start_anchor_window_events <- 934L
  out$positive_dose_scored_events <- 923L
  out$no_component_events_dropped_before_log <- 11L
  out$surface_only_status <-
    "non_estimable_insufficient_method_support_68_linked_events"
  out$surface_linked_candidate_events <- 68L
  out$surface_positive_events <- 56L
  out$surface_no_component_events_dropped_before_log <- 12L
  out
}

.stage3_dose_verdict_pre_amendment_v1 <-
  stage3_dose_falsification_verdict_v1

stage3_dose_falsification_verdict_v1 <- function(
    real, method, extent, effort) {
  verdict <- .stage3_dose_verdict_pre_amendment_v1(
    real, method, extent, effort
  )
  verdict$reason <- gsub(
    "surface-only",
    "dive-only consistent-majority",
    verdict$reason,
    fixed = TRUE
  )
  verdict
}

.stage3_dose_report_pre_amendment_v1 <- stage3_dose_report_v1

stage3_dose_report_v1 <- function(
    output_root, index_audit, real, method, extent, effort,
    placebo, guild, tercile, grand_mean) {
  verdict <- .stage3_dose_report_pre_amendment_v1(
    output_root, index_audit, real, method, extent, effort,
    placebo, guild, tercile, grand_mean
  )
  path <- "STAGE3_DOSE_REPORT.md"
  lines <- readLines(path, warn = FALSE)
  lines <- gsub(
    "surface-only restriction",
    "dive-only consistent-majority restriction",
    lines, fixed = TRUE
  )
  lines <- gsub(
    "surface-only fits",
    "dive-only consistent-majority fits",
    lines, fixed = TRUE
  )
  target <- grep(
    "The surface-only table reports every species",
    lines, fixed = TRUE
  )
  replacement <- c(
    paste(
      "The surface-only set contained 68/1,120 linked candidate events",
      "(6.1%) and was declared non-estimable; no surface-only response",
      "model was fit or interpreted."
    ),
    paste(
      "The replacement dive-only consistent-majority set contained",
      "950/1,120 linked candidate events (84.8%). Its 98 species-outcome",
      "rows are reported beside the primary estimates; 11 dive events",
      "with no recorded component were dropped before logging."
    )
  )
  if (length(target) == 1L) {
    lines <- append(lines[-target], replacement, after = target - 1L)
  } else {
    stop("STAGE3_DOSE_AMENDED_REPORT_GATE: method paragraph absent",
         call. = FALSE)
  }
  missing_line <- grep(
    "events had no recorded component and were dropped",
    lines, fixed = TRUE
  )
  if (length(missing_line) == 1L) {
    lines <- append(
      lines,
      paste(
        "The descriptive `0.00` for those 125 events is a display convention,",
        "not an observed zero-spawn value: `log(index)` was never evaluated",
        "for them, and they were absent from every dose-scored link sum."
      ),
      after = missing_line
    )
  }
  writeLines(lines, path, useBytes = TRUE)
  verdict
}

run_post_stage4a_stage3_dose_amended_sensitivities_v1 <- function(
    primary_model_code_commit, amendment_execution_commit, herring_path,
    output_root = "outputs/post_stage4a_stage3_dose_v1") {
  started <- Sys.time()
  stage3_dose_authorization_gate_v1()
  stage3_dose_spec_gate_v1()
  stage3_dose_amendment_gate_v1()
  stage3_dose_parent_gate_v1()
  protected_root <- file.path(
    "data", "derived", "post_stage4a_stage3_dose_v1"
  )
  family_path <- file.path(
    protected_root, "checkpoint_2_family_results.rds"
  )
  if (
    !file.exists(file.path(protected_root, "checkpoint_2_complete.yml")) ||
      !file.exists(family_path)
  ) {
    stop("STAGE3_DOSE_STAGING_GATE: checkpoint 2 incomplete",
         call. = FALSE)
  }
  parent_roots <- c(
    "outputs/post_stage4a_sog_event_study_v1",
    "outputs/post_stage4a_staged_refit_v1",
    "outputs/post_stage4a_staged_refit_stage2_v1"
  )
  parent_before <- lapply(
    parent_roots, staged_refit_amendment_snapshot_v1
  )
  names(parent_before) <- parent_roots
  inputs <- stage3_dose_load_inputs_v1(herring_path)
  primary_signature <- stage3_dose_run_signature_v1(
    inputs, primary_model_code_commit
  )
  family_cache <- readRDS(family_path)
  if (!identical(
      family_cache$cache_signature, primary_signature
    )) {
    stop("STAGE3_DOSE_FAMILY_CACHE_GATE: primary cache changed",
         call. = FALSE)
  }
  real <- family_cache$results
  timings <- list()

  phase <- Sys.time()
  dive_links <- inputs$anchored_links[
    inputs$anchored_links$survey_method_group == "dive_only",
    ,
    drop = FALSE
  ]
  dive_wide <- stage3_dose_widen_by_link_v1(
    inputs$base_events, dive_links, inputs$index,
    real_grand_mean = inputs$real_grand_mean,
    links_are_reanchored = TRUE
  )
  dive_events <- staged_refit_s2_attach_detectability_v1(
    dive_wide$events, inputs$detectability
  )$events
  method <- stage3_dose_fit_family_v1(
    inputs$taxa, dive_events, inputs$states, inputs$masks,
    inputs$species_registry,
    file.path(protected_root, "checkpoints", "dive_only"),
    paste(
      primary_signature, amendment_execution_commit,
      "amendment_v1", "dive_only", sep = "|"
    ),
    fit_lrt = FALSE, variant = "decomposed",
    workers = post_stage4a_worker_count_v1(length(inputs$taxa))
  )
  timings$dive_only_seconds <- as.numeric(Sys.time() - phase)
  timings$surface_only_seconds <- 0

  phase <- Sys.time()
  extent_wide <- stage3_dose_widen_by_link_v1(
    inputs$base_events, inputs$anchored_links, inputs$index,
    real_grand_mean = inputs$real_grand_mean,
    links_are_reanchored = TRUE, include_extent = TRUE
  )
  extent_events <- staged_refit_s2_attach_detectability_v1(
    extent_wide$events, inputs$detectability
  )$events
  extent <- stage3_dose_fit_family_v1(
    inputs$taxa, extent_events, inputs$states, inputs$masks,
    inputs$species_registry,
    file.path(protected_root, "checkpoints", "extent"),
    paste(
      primary_signature, "extent",
      format(extent_wide$length_grand_mean, digits = 17), sep = "|"
    ),
    fit_lrt = FALSE, variant = "extent",
    workers = post_stage4a_worker_count_v1(length(inputs$taxa))
  )
  extent$extent_correlation <- extent_wide$extent_correlation
  extent$extent_event_n <- extent_wide$extent_event_n
  extent$length_grand_mean <- extent_wide$length_grand_mean
  timings$extent_seconds <- as.numeric(Sys.time() - phase)

  phase <- Sys.time()
  placebo_results <- list()
  for (offset in c(-90L, 90L)) {
    placebo_events <- stage3_dose_placebo_events_v1(inputs, offset)
    placebo_results[[as.character(offset)]] <-
      stage3_dose_fit_family_v1(
        inputs$taxa, placebo_events, inputs$states, inputs$masks,
        inputs$species_registry,
        file.path(
          protected_root, "checkpoints",
          paste0("placebo_", ifelse(offset < 0, "m", "p"), abs(offset))
        ),
        paste(primary_signature, "placebo", offset, sep = "|"),
        fit_lrt = FALSE, variant = "decomposed",
        workers = post_stage4a_worker_count_v1(length(inputs$taxa))
      )
  }
  placebo <- stage3_dose_placebo_tallies_v1(placebo_results)
  timings$placebo_seconds <- as.numeric(Sys.time() - phase)

  phase <- Sys.time()
  effort <- stage3_dose_effort_outcomes_v1(
    inputs$events,
    file.path(protected_root, "checkpoints", "effort"),
    primary_signature
  )
  guild <- stage3_dose_guild_meta_v1(
    real$effects, inputs$species_registry
  )
  tercile <- stage3_dose_tercile_results_v1(
    inputs,
    file.path(protected_root, "checkpoints", "terciles"),
    primary_signature
  )
  timings$effort_guild_tercile_seconds <-
    as.numeric(Sys.time() - phase)

  parent_after <- lapply(
    parent_roots, staged_refit_amendment_snapshot_v1
  )
  names(parent_after) <- parent_roots
  if (!identical(parent_before, parent_after)) {
    stop("STAGE3_DOSE_PARENT_IMMUTABILITY_GATE: parent changed",
         call. = FALSE)
  }
  primary <- real$effects[
    real$effects$component == "within_location", , drop = FALSE
  ]
  primary_tallies <- do.call(rbind, lapply(
    c("checklist_reporting", "conditional_positive_numeric_count"),
    function(outcome) {
      x <- primary[primary$outcome == outcome, , drop = FALSE]
      data.frame(
        outcome = outcome,
        positive_bh_q_lt_0_05 = sum(
          x$q_value < 0.05 & x$estimate > 0, na.rm = TRUE
        ),
        negative_bh_q_lt_0_05 = sum(
          x$q_value < 0.05 & x$estimate < 0, na.rm = TRUE
        ),
        estimable_species = sum(is.finite(x$estimate)),
        stringsAsFactors = FALSE
      )
    }
  ))
  execution_record <- list(
    execution_version = "post_stage4a_stage3_dose_execution_v1",
    analysis_status = "post_result_estimand_refinement_not_confirmatory",
    execution_code_commit = amendment_execution_commit,
    primary_model_code_commit = primary_model_code_commit,
    amendment_execution_commit = amendment_execution_commit,
    amendment_record =
      "metadata/post_stage4a_stage3_dose_amendment_v1.yml",
    executed_at_utc = format(
      Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"
    ),
    elapsed_seconds = as.numeric(Sys.time() - started),
    stage_timings_seconds = timings,
    completed_checkpoints = c(
      "checkpoint_1_case_species",
      "checkpoint_2_fixed_49_family",
      "checkpoint_3_amended_sensitivities"
    ),
    authorization = list(
      variable = "POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED",
      exact_value_verified_in_process = TRUE,
      set_by_agent = FALSE
    ),
    population = list(
      region = "SoG", years = c(2005L, 2025L),
      eligible_checklists = 217200L,
      fixed_family_species = 49L,
      linked_candidate_spawn_events = 1120L,
      records_2026_plus_read = 0L
    ),
    index = list(
      transform = "log(relative_spawn_index_t)",
      grand_mean_log_index = inputs$real_grand_mean,
      aggregation =
        "sum rows within Year+LocationCode+Section+SpawnNumber",
      linked_candidates_with_no_recorded_component = 125L,
      descriptive_zero_display_entered_as_zero_spawn = FALSE,
      missing_component_rule = paste(
        "125 unscorable linked events dropped before logging;",
        "121 retained a start-anchor window link but contributed no dose"
      ),
      source_sha256 = inputs$index$source_hash
    ),
    method_sensitivity = list(
      surface_only = list(
        linked_candidate_events = 68L,
        percent = 6.071428571428571,
        model_fit = FALSE,
        status = "non_estimable_insufficient_method_support"
      ),
      dive_only = list(
        linked_candidate_events = 950L,
        percent = 84.82142857142857,
        start_anchor_window_events = 934L,
        positive_dose_scored_events = 923L,
        model_fit = TRUE,
        role = "consistent_majority_set"
      )
    ),
    joins = list(
      source_rows_to_aggregated_events = "many_to_one_PASS",
      source_links_to_aggregated_events = "many_to_one_PASS",
      links_to_checklists_then_aggregate = "many_to_one_PASS",
      checklist_to_aggregated_event_link = "unique_PASS",
      detectability_to_checklists = "one_to_one_217200_PASS",
      species_to_primary_guild = "many_to_one_seven_guilds_PASS"
    ),
    engines = list(
      checklist_reporting = "lme4::glmer binomial nAGQ=0",
      conditional_positive_numeric_count =
        "lme4::lmer log count; REML estimates; ML LRT",
      effort_outcomes = "lme4::lmer REML"
    ),
    multiplicity = list(
      primary =
        "BH fixed 49 separately by outcome for dose_did_active_minus_pre",
      likelihood_ratio =
        "BH fixed 49 separately by outcome; separate from primary",
      effort = "BH across three effort outcomes",
      placebo = "BH fixed 49 separately by offset and outcome"
    ),
    parent_stage2_bh_positive = list(
      conditional_positive_numeric_count = 20L,
      checklist_reporting = 13L
    ),
    stage3_primary_tallies = split(
      primary_tallies, seq_len(nrow(primary_tallies))
    ),
    placebo_tallies = split(placebo, seq_len(nrow(placebo))),
    extent = list(
      index_extent_pearson_correlation =
        extent_wide$extent_correlation,
      eligible_events = stage3_dose_release_count_v1(
        extent_wide$extent_event_n
      ),
      link_grand_mean_log_length = extent_wide$length_grand_mean
    ),
    fit_diagnostics = list(
      real_diagnostic_rows = nrow(real$diagnostics),
      failed_real_effect_rows = stage3_dose_release_count_v1(
        sum(!is.finite(primary$estimate))
      ),
      failed_real_lrt_rows = stage3_dose_release_count_v1(
        sum(!is.finite(real$lrt$p_value))
      ),
      warnings_real_diagnostic_rows = stage3_dose_release_count_v1(
        sum(
          real$diagnostics$singular_fit %in% TRUE |
            real$diagnostics$rank_deficient %in% TRUE |
            !real$diagnostics$converged %in% TRUE,
          na.rm = TRUE
        )
      ),
      no_fallback_models = TRUE
    ),
    full_fixed_effect_covariance_used = TRUE,
    parent_outputs_unchanged = TRUE,
    historical_withdrawn_control_outputs_retained_unchanged = TRUE,
    r_version = R.version.string,
    package_versions = as.list(vapply(
      c("data.table", "digest", "lme4", "yaml"),
      function(package) as.character(utils::packageVersion(package)),
      character(1L)
    )),
    workers = post_stage4a_worker_count_v1(length(inputs$taxa))
  )
  written <- stage3_dose_write_outputs_v1(
    output_root, inputs, real, method, extent, effort,
    placebo, guild, tercile, execution_record
  )
  stage3_dose_checkpoint_marker_v1(
    file.path(protected_root, "checkpoint_3_complete.yml"),
    "checkpoint_3_amended_sensitivities",
    amendment_execution_commit, Sys.time() - started,
    list(
      primary_model_code_commit = primary_model_code_commit,
      amendment_record =
        "metadata/post_stage4a_stage3_dose_amendment_v1.yml",
      output_root = output_root,
      verdict = written$verdict$verdict
    )
  )
  invisible(written)
}
