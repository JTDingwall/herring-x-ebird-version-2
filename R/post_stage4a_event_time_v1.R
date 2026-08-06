event_time_version_v1 <- function() {
  "post_stage4a_event_time_v1"
}

event_time_window_v1 <- function() {
  -5L:5L
}

event_time_day_label_v1 <- function(day) {
  paste0("d", ifelse(day < 0, paste0("m", abs(day)), as.character(day)))
}

# Exposure terms for the day-resolved design. The registered baseline
# (-28 to -15) and the periods outside the window are kept exactly as the
# registered design defines them, so a day estimate is directly comparable to
# the registered active-minus-pre14 contrast. The three registered periods that
# overlap the window (immediate_pre, spawn_start, early_egg) are split into
# day-resolved terms plus a residual term for the days they cover outside it.
event_time_block_spec_v1 <- function() {
  list(
    baseline = c(-28L, -15L),
    early_pre = c(-14L, -8L),
    immediate_pre_residual = c(-7L, -6L),
    early_egg_residual = c(6L, 14L),
    late_egg = c(15L, 28L)
  )
}

event_time_terms_v1 <- function() {
  zones <- c("near", "reference")
  blocks <- names(event_time_block_spec_v1())
  block_terms <- as.vector(outer(
    zones, blocks, function(zone, block) paste("et", zone, block, sep = "_")
  ))
  day_terms <- as.vector(outer(
    zones, event_time_day_label_v1(event_time_window_v1()),
    function(zone, day) paste("et", zone, day, sep = "_")
  ))
  c(block_terms, day_terms)
}

event_time_classify_links_v1 <- function(links) {
  required <- c("analysis_event_token", "event_day", "distance_km")
  if (!all(required %in% names(links))) {
    stop("EVENT_TIME_LINK_GATE: required link fields unavailable",
         call. = FALSE)
  }
  event_day <- suppressWarnings(as.integer(links$event_day))
  distance_km <- suppressWarnings(as.numeric(links$distance_km))
  if (
    anyNA(event_day) || anyNA(distance_km) ||
      any(distance_km < 0 | distance_km > 20.0001)
  ) {
    stop("EVENT_TIME_LINK_RANGE_GATE: invalid day or distance",
         call. = FALSE)
  }
  zone <- ifelse(distance_km < 5, "near", "reference")
  window <- event_time_window_v1()
  label <- rep(NA_character_, length(event_day))
  in_window <- event_day >= min(window) & event_day <= max(window)
  label[in_window] <- event_time_day_label_v1(event_day[in_window])
  for (block in names(event_time_block_spec_v1())) {
    range <- event_time_block_spec_v1()[[block]]
    use <- !in_window & event_day >= range[[1L]] & event_day <= range[[2L]]
    label[use] <- block
  }
  term <- ifelse(is.na(label), NA_character_, paste("et", zone, label, sep = "_"))
  data.frame(
    analysis_event_token = as.character(links$analysis_event_token),
    term = term,
    stringsAsFactors = FALSE
  )
}

event_time_add_exposure_v1 <- function(events, links) {
  tokens <- as.character(events$analysis_event_token)
  selected <- links[
    as.character(links$analysis_event_token) %in% tokens, , drop = FALSE
  ]
  classified <- event_time_classify_links_v1(selected)
  classified <- classified[!is.na(classified$term), , drop = FALSE]
  terms <- event_time_terms_v1()
  if (!all(classified$term %in% terms)) {
    stop("EVENT_TIME_TERM_GATE: unregistered day term", call. = FALSE)
  }
  # Link counts, not indicators, to match the registered exposure semantics.
  counts <- data.table::as.data.table(classified)[
    , .(exposure_links = .N), by = .(analysis_event_token, term)
  ]
  wide <- data.table::dcast(
    counts, analysis_event_token ~ term,
    value.var = "exposure_links", fill = 0L
  )
  event_dt <- data.table::as.data.table(data.table::copy(events))
  event_dt[, event_time_row_order__ := .I]
  joined <- merge(
    event_dt, wide, by = "analysis_event_token", all.x = TRUE, sort = FALSE
  )
  data.table::setorder(joined, event_time_row_order__)
  joined[, event_time_row_order__ := NULL]
  if (
    nrow(joined) != nrow(events) ||
      anyDuplicated(joined$analysis_event_token)
  ) {
    stop("EVENT_TIME_AGGREGATION_GATE: model-row cardinality changed",
         call. = FALSE)
  }
  for (term in terms) {
    if (!term %in% names(joined)) joined[, (term) := 0L]
    data.table::set(joined, which(is.na(joined[[term]])), term, 0L)
    joined[, (term) := as.integer(get(term))]
  }
  as.data.frame(joined)
}

event_time_formula_v1 <- function(response = "model_response") {
  fixed <- c(
    event_time_terms_v1(),
    "factor(checklist_year)", "protocol", "log_duration",
    "log_effort_distance", "observer_count",
    staged_refit_s2_detectability_terms_v1()
  )
  stats::as.formula(paste(
    response, "~", paste(fixed, collapse = " + "),
    "+ (1 | event_block_token) + (1 | observer_cluster_token) +",
    "(1 | location_cluster_token)"
  ))
}

# DiD for one day: (near_day - reference_day) - (near_baseline -
# reference_baseline). Identical in form to the registered contrast, with the
# single day standing in for the pooled active window.
event_time_day_weights_v1 <- function(day) {
  label <- event_time_day_label_v1(day)
  stats::setNames(
    c(1, -1, -1, 1),
    c(
      paste("et", "near", label, sep = "_"),
      paste("et", "reference", label, sep = "_"),
      "et_near_baseline",
      "et_reference_baseline"
    )
  )
}

event_time_support_v1 <- function(d) {
  terms <- event_time_terms_v1()
  exposed <- vapply(terms, function(term) sum(d[[term]] > 0L), integer(1L))
  data.frame(
    term = names(exposed),
    exposed_checklists = .post_stage4a_release_count_v1(as.numeric(exposed)),
    meets_minimum_20 = exposed >= 20L,
    stringsAsFactors = FALSE
  )
}

event_time_profile_v1 <- function(fit, outcome) {
  beta <- lme4::fixef(fit)
  covariance <- as.matrix(stats::vcov(fit))
  rows <- lapply(event_time_window_v1(), function(day) {
    weights <- event_time_day_weights_v1(day)
    wald <- staged_refit_wald_v1(beta, covariance, weights)
    satterthwaite <- if (inherits(fit, "lmerModLmerTest")) {
      L <- .post_stage4a_contrast_vector_v1(names(beta), weights)
      out <- try(
        lmerTest::contest1D(
          fit, L, ddf = "Satterthwaite", confint = TRUE, level = 0.95
        ),
        silent = TRUE
      )
      if (inherits(out, "try-error")) NULL else out
    } else {
      NULL
    }
    if (is.null(satterthwaite)) {
      estimate <- wald[["estimate"]]
      standard_error <- wald[["standard_error"]]
      denominator_df <- Inf
      conf_low <- wald[["conf_low"]]
      conf_high <- wald[["conf_high"]]
      p_value <- wald[["p_value"]]
      method <- "wald"
    } else {
      estimate <- satterthwaite[["Estimate"]]
      standard_error <- satterthwaite[["Std. Error"]]
      denominator_df <- satterthwaite[["df"]]
      conf_low <- satterthwaite[["lower"]]
      conf_high <- satterthwaite[["upper"]]
      p_value <- satterthwaite[["Pr(>|t|)"]]
      method <- "satterthwaite_denominator_df"
    }
    data.frame(
      analysis_version = event_time_version_v1(),
      outcome = outcome,
      event_day = day,
      estimate = estimate,
      standard_error = standard_error,
      denominator_df = denominator_df,
      conf_low = conf_low,
      conf_high = conf_high,
      p_value = p_value,
      ratio = exp(estimate),
      ratio_conf_low = exp(conf_low),
      ratio_conf_high = exp(conf_high),
      interval_excludes_one = is.finite(conf_low) & is.finite(conf_high) &
        (conf_low > 0 | conf_high < 0),
      interval_method = method,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

# The pooled registered contrast recomputed from this same model, so the day
# profile can be anchored against the number the manuscript already reports.
event_time_pooled_check_v1 <- function(fit, outcome) {
  window <- event_time_window_v1()
  active_days <- window[window >= 0 & window <= 3]
  pre_days <- window[window >= -5 & window <= -1]
  combine <- function(days, sign) {
    out <- numeric()
    for (day in days) {
      weights <- event_time_day_weights_v1(day) * sign / length(days)
      for (name in names(weights)) {
        out[[name]] <- if (name %in% names(out)) {
          out[[name]] + weights[[name]]
        } else {
          weights[[name]]
        }
      }
    }
    out
  }
  weights <- combine(active_days, 1)
  pre <- combine(pre_days, -1)
  for (name in names(pre)) {
    weights[[name]] <- if (name %in% names(weights)) {
      weights[[name]] + pre[[name]]
    } else {
      pre[[name]]
    }
  }
  wald <- staged_refit_wald_v1(
    lme4::fixef(fit), as.matrix(stats::vcov(fit)), weights
  )
  data.frame(
    analysis_version = event_time_version_v1(),
    outcome = outcome,
    comparison = "mean_day_0_to_3_minus_mean_day_minus5_to_minus1",
    estimate = wald[["estimate"]],
    standard_error = wald[["standard_error"]],
    conf_low = wald[["conf_low"]],
    conf_high = wald[["conf_high"]],
    p_value = wald[["p_value"]],
    ratio = exp(wald[["estimate"]]),
    ratio_conf_low = exp(wald[["conf_low"]]),
    ratio_conf_high = exp(wald[["conf_high"]]),
    stringsAsFactors = FALSE
  )
}

event_time_effort_profile_v1 <- function(d) {
  # Descriptive only: how many checklists sit in each near-zone day cell, and
  # their median duration. Birders may target spawns, and the reader needs to
  # see that separately from the bird response.
  rows <- lapply(event_time_window_v1(), function(day) {
    label <- event_time_day_label_v1(day)
    near <- d[[paste("et", "near", label, sep = "_")]] > 0L
    reference <- d[[paste("et", "reference", label, sep = "_")]] > 0L
    data.frame(
      analysis_version = event_time_version_v1(),
      event_day = day,
      near_checklists = .post_stage4a_release_count_v1(sum(near)),
      reference_checklists = .post_stage4a_release_count_v1(sum(reference)),
      near_median_duration_minutes = if (sum(near) >= 20L) {
        stats::median(exp(d$log_duration[near]), na.rm = TRUE)
      } else {
        NA_real_
      },
      reference_median_duration_minutes = if (sum(reference) >= 20L) {
        stats::median(exp(d$log_duration[reference]), na.rm = TRUE)
      } else {
        NA_real_
      },
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

run_post_stage4a_event_time_v1 <- function(
    execution_code_commit,
    species = "Bald Eagle",
    output_root = "outputs/post_stage4a_event_time_v1") {
  started <- Sys.time()
  authorization <- staged_refit_authorization_gate_v1()
  staged_refit_s2_gate_v1()
  if (!identical(
    Sys.getenv("POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED"),
    authorization$environment_acknowledgement$value
  )) {
    stop("The exact author-set acknowledgement is required", call. = FALSE)
  }
  parent_before <- staged_refit_parent_hash_snapshot_v1()
  stage2_before <- staged_refit_amendment_snapshot_v1(
    "outputs/post_stage4a_staged_refit_stage2_v1"
  )
  blockaware_before <- staged_refit_amendment_snapshot_v1(
    "outputs/post_stage4a_blockaware_v1"
  )

  inputs <- stage2_block_slope_load_inputs_v1()
  registry <- utils::read.csv(
    "metadata/canonical_species_registry.csv", stringsAsFactors = FALSE
  )
  taxon <- registry$analysis_taxon_id[match(species, registry$common_name)]
  if (length(taxon) != 1L || is.na(taxon)) {
    stop("EVENT_TIME_SPECIES_GATE: unresolved species", call. = FALSE)
  }

  protected_links <-
    "data/derived/stage3_phase2_protected/metadata_source_point_links.tsv.gz"
  # Reuse the single existing definition of the frozen herring source path
  # rather than repeating the raw filename, which the privacy scan prohibits
  # outside its allowlisted files.
  herring_path <- Sys.getenv("HERRING_EBIRD_V2_HERRING", unset = "")
  if (!nzchar(herring_path)) {
    herring_path <- eval(
      formals(stage2_block_slope_load_inputs_v1)$herring_path
    )
  }
  anchor <- staged_refit_build_anchor_lookup_v1(herring_path)
  links <- staged_refit_reanchor_links_v1(
    .stage4a_read_gz(protected_links), anchor
  )
  events <- event_time_add_exposure_v1(inputs$events, links)
  if (nrow(events) != nrow(inputs$events)) {
    stop("EVENT_TIME_POPULATION_GATE: row count changed", call. = FALSE)
  }

  dat <- stage4a_materialize_taxon(
    events, inputs$states, inputs$masks, taxon
  )
  results <- list()
  supports <- list()
  effort <- NULL
  for (outcome in blockaware_outcomes_v1()) {
    if (outcome == "checklist_reporting") {
      use <- !is.na(dat$detection)
      d <- dat[use, , drop = FALSE]
      d$model_response <- d$detection
    } else {
      use <- is.finite(dat$numeric_count) & dat$numeric_count > 0
      d <- dat[use, , drop = FALSE]
      d$model_response <- log(d$numeric_count)
    }
    support <- event_time_support_v1(d)
    support$outcome <- outcome
    supports[[outcome]] <- support
    if (!all(support$meets_minimum_20)) {
      stop("EVENT_TIME_SUPPORT_GATE: a day cell falls below 20 for ",
           outcome, call. = FALSE)
    }
    if (is.null(effort)) effort <- event_time_effort_profile_v1(d)
    message("EVENT_TIME_FIT_START outcome=", outcome, " n=", nrow(d))
    formula <- event_time_formula_v1("model_response")
    fit <- if (outcome == "checklist_reporting") {
      lme4::glmer(
        formula, data = d, family = stats::binomial(), nAGQ = 0L,
        control = lme4::glmerControl(
          optimizer = "nloptwrap", calc.derivs = TRUE,
          optCtrl = list(maxeval = 10000L)
        )
      )
    } else {
      lmerTest::lmer(
        formula, data = d, REML = TRUE,
        control = lme4::lmerControl(
          optimizer = "nloptwrap", calc.derivs = TRUE,
          optCtrl = list(maxeval = 10000L)
        )
      )
    }
    singular <- lme4::isSingular(fit, tol = 1e-4)
    classification <- .post_stage4a_model_messages_v1(
      fit@optinfo$conv$opt, fit@optinfo$conv$lme4$messages, singular
    )
    profile <- event_time_profile_v1(fit, outcome)
    profile$species <- species
    profile$n <- .post_stage4a_release_count_v1(nrow(d))
    profile$converged <- classification$converged
    profile$singular_fit <- singular
    pooled <- event_time_pooled_check_v1(fit, outcome)
    pooled$species <- species
    results[[outcome]] <- list(profile = profile, pooled = pooled)
    message(
      "EVENT_TIME_FIT_DONE outcome=", outcome,
      " converged=", classification$converged, " singular=", singular
    )
    rm(fit, d)
    gc()
  }

  profile <- do.call(rbind, lapply(results, `[[`, "profile"))
  pooled <- do.call(rbind, lapply(results, `[[`, "pooled"))
  support <- do.call(rbind, supports)
  rownames(profile) <- NULL
  rownames(pooled) <- NULL
  rownames(support) <- NULL

  dir.create(output_root, recursive = TRUE, showWarnings = FALSE)
  outputs <- list(
    event_time_profile = profile,
    event_time_pooled_check = pooled,
    event_time_term_support = support,
    event_time_effort_profile = effort
  )
  paths <- character()
  for (name in names(outputs)) {
    path <- file.path(output_root, paste0(name, ".csv"))
    .post_stage4a_write_csv_v1(outputs[[name]], path)
    paths <- c(paths, path)
  }
  staged_refit_privacy_column_gate_v1(paths)

  if (!identical(parent_before, staged_refit_parent_hash_snapshot_v1())) {
    stop("EVENT_TIME_HISTORY_GATE: parent changed", call. = FALSE)
  }
  if (!identical(
    stage2_before,
    staged_refit_amendment_snapshot_v1(
      "outputs/post_stage4a_staged_refit_stage2_v1"
    )
  )) {
    stop("EVENT_TIME_HISTORY_GATE: Stage 2 changed", call. = FALSE)
  }
  if (!identical(
    blockaware_before,
    staged_refit_amendment_snapshot_v1("outputs/post_stage4a_blockaware_v1")
  )) {
    stop("EVENT_TIME_HISTORY_GATE: block-aware output changed", call. = FALSE)
  }

  execution <- list(
    execution_version = event_time_version_v1(),
    analysis_status = "exploratory_single_species_descriptive_event_time",
    confirmatory = FALSE,
    multiplicity_family_membership = "none_not_a_registered_family",
    interpretation_limits = list(
      single_species_chosen_after_seeing_results = TRUE,
      no_benjamini_hochberg_applied = TRUE,
      random_slope_omitted = paste(
        "the block-aware random slope is defined on the pooled",
        "active-minus-pre14 direction and has no single counterpart at day",
        "resolution, so this model keeps the Stage 2 event-block random",
        "intercept; the day intervals are therefore Stage 2 width and are",
        "narrower than a block-aware interval by roughly the 16 to 18 per",
        "cent median widening measured in post_stage4a_blockaware_v1"
      ),
      day_estimates_are_not_independent = TRUE,
      effort_profile_is_descriptive_only = TRUE
    ),
    execution_code_commit = execution_code_commit,
    executed_at_utc = format(
      as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"
    ),
    elapsed_seconds = as.numeric(
      difftime(Sys.time(), started, units = "secs")
    ),
    species = species,
    window_days = range(event_time_window_v1()),
    design = list(
      contrast = paste(
        "for each day d, (near_d - reference_d) -",
        "(near_baseline - reference_baseline)"
      ),
      baseline_days = event_time_block_spec_v1()$baseline,
      near_zone_km = "less than 5",
      reference_zone_km = "5 to 20",
      exposure_values = "link counts, matching the registered design",
      registered_periods_outside_the_window = "retained unchanged",
      exposure_terms = length(event_time_terms_v1())
    ),
    engines = list(
      checklist_reporting = "lme4::glmer binomial nAGQ=0",
      conditional_positive_numeric_count = "lmerTest::lmer REML"
    ),
    interval_methods = list(
      checklist_reporting = "wald",
      conditional_positive_numeric_count = "satterthwaite_denominator_df"
    ),
    population = list(
      region = "SoG", years = c(2005L, 2025L),
      checklists = nrow(events), records_2026_plus_read = 0L
    ),
    protected_input_hashes = as.list(inputs$protected_hashes),
    herring_source_hash = inputs$herring_source_hash,
    privacy_column_gate = "PASS",
    historical_outputs_modified = FALSE
  )
  staged_refit_write_yaml_lf_v1(
    execution, file.path(output_root, "execution_record_v1.yml")
  )
  manifest <- staged_refit_output_manifest_v1(output_root)
  .post_stage4a_write_csv_v1(
    manifest, file.path(output_root, "output_hash_manifest_v1.csv")
  )
  message("EVENT_TIME_GATE=PASS_EXPLORATORY")
  invisible(list(
    profile = profile, pooled = pooled, support = support, effort = effort
  ))
}
