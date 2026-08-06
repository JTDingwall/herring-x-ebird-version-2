staged_refit_s1_version_v1 <- function() {
  "post_stage4a_staged_refit_v1_s1_anchor"
}

staged_refit_authorization_gate_v1 <- function(
    path = "metadata/post_stage4a_staged_refit_authorization_v1.yml") {
  if (!file.exists(path)) {
    stop("STAGED_REFIT_AUTHORIZATION_GATE: record unavailable",
         call. = FALSE)
  }
  authorization <- yaml::read_yaml(path)
  required <- list(
    authorization_version =
      "post_stage4a_staged_refit_authorization_v1",
    scientific_decision =
      "AUTHORIZE_STAGED_REFIT_ANCHOR_DETECTABILITY_DOSE_V1"
  )
  for (name in names(required)) {
    if (!identical(authorization[[name]], required[[name]])) {
      stop("STAGED_REFIT_AUTHORIZATION_GATE: record mismatch",
           call. = FALSE)
    }
  }
  if (
      !identical(
        authorization$environment_acknowledgement$variable,
        "POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED"
      ) ||
      !is.character(authorization$environment_acknowledgement$value) ||
      length(authorization$environment_acknowledgement$value) != 1L ||
      !nzchar(authorization$environment_acknowledgement$value) ||
      !identical(
        authorization$environment_acknowledgement$set_by_agent,
        "prohibited"
      ) ||
      !identical(
        authorization$authorized_population$end_year,
        2025L
      ) ||
      !identical(
        authorization$authorized_refit$stages$s1_anchor$day0,
        "first_recorded_spawn_date_at_location"
      ) ||
      !identical(
        authorization$authorized_refit$stages$s1_anchor$
          fallback_where_start_date_absent,
        "end_date"
      )
  ) {
    stop("STAGED_REFIT_AUTHORIZATION_GATE: scope mismatch",
         call. = FALSE)
  }
  invisible(authorization)
}

staged_refit_clean_v1 <- function(x) {
  trimws(gsub("\ufeff", "", as.character(x), fixed = TRUE))
}

staged_refit_missing_text_v1 <- function(x) {
  cleaned <- toupper(trimws(as.character(x)))
  is.na(x) | cleaned %in% c("", "NA", "N/A", "NULL")
}

staged_refit_hash_token_v1 <- function(domain, value) {
  if (!requireNamespace("digest", quietly = TRUE)) {
    stop("digest is required for staged-refit token reconstruction",
         call. = FALSE)
  }
  substr(vapply(
    paste0(domain, "|", value),
    digest::digest,
    character(1L),
    algo = "sha256",
    serialize = FALSE
  ), 1L, 24L)
}

staged_refit_build_anchor_lookup_v1 <- function(herring_path) {
  if (!file.exists(herring_path)) {
    stop("STAGED_REFIT_HERRING_SOURCE_GATE: configured source is unavailable",
         call. = FALSE)
  }
  expected_hash <-
    "6d3b2c08e3586bde52f5fe2af602c63014468b54e49dc906bd1f8dfe6706e8ac"
  observed_hash <- .post_stage4a_sha256_v1(herring_path)
  if (!identical(observed_hash, expected_hash)) {
    stop("STAGED_REFIT_HERRING_SOURCE_HASH_GATE: mismatch", call. = FALSE)
  }
  required <- c(
    "Year", "StatisticalArea", "Section", "LocationCode", "SpawnNumber",
    "StartDate", "EndDate", "Longitude", "Latitude"
  )
  source <- data.table::fread(
    herring_path,
    select = required,
    colClasses = "character",
    na.strings = NULL,
    showProgress = FALSE
  )
  .post_stage4a_require_fields_v1(
    source, required, "herring anchor source"
  )
  source[, source_row__ := .I]
  for (name in required) {
    data.table::set(
      source, j = name, value = staged_refit_clean_v1(source[[name]])
    )
  }
  raw_rows <- nrow(source)
  raw_start_missing <- sum(staged_refit_missing_text_v1(source$StartDate))
  raw_end_missing <- sum(staged_refit_missing_text_v1(source$EndDate))

  source[, event_year__ := suppressWarnings(as.integer(Year))]
  source[, start_date__ := data.table::as.IDate(
    StartDate, format = "%Y-%m-%d"
  )]
  source[, end_date__ := data.table::as.IDate(
    EndDate, format = "%Y-%m-%d"
  )]
  source[, longitude__ := suppressWarnings(as.numeric(Longitude))]
  source[, latitude__ := suppressWarnings(as.numeric(Latitude))]
  in_year <- !is.na(source$event_year__) &
    source$event_year__ >= 1988L & source$event_year__ <= 2025L
  has_date <- !is.na(source$start_date__) | !is.na(source$end_date__)
  valid_coordinate <- is.finite(source$longitude__) &
    is.finite(source$latitude__) &
    source$longitude__ >= -180 & source$longitude__ <= 180 &
    source$latitude__ >= -90 & source$latitude__ <= 90
  source <- source[in_year & has_date & valid_coordinate]
  if (!nrow(source)) {
    stop("STAGED_REFIT_HERRING_SOURCE_GATE: no valid through-2025 records",
         call. = FALSE)
  }
  both_dates <- !is.na(source$start_date__) & !is.na(source$end_date__)
  span <- as.integer(source$end_date__ - source$start_date__)
  source[, anchor_fallback__ := is.na(start_date__) & !is.na(end_date__)]
  source[, anchor_shift_days__ := 0L]
  source[both_dates, anchor_shift_days__ := floor(span[both_dates] / 2)]
  source[, source_identity__ := paste(
    source_row__,
    event_year__,
    StatisticalArea,
    Section,
    LocationCode,
    SpawnNumber,
    sep = "|"
  )]
  source[, herring_source_token := staged_refit_hash_token_v1(
    "herring_source", source_identity__
  )]
  if (anyNA(source$herring_source_token) ||
      anyDuplicated(source$herring_source_token)) {
    stop("STAGED_REFIT_ANCHOR_LOOKUP_KEY_GATE: source token is not unique",
         call. = FALSE)
  }
  lookup <- as.data.frame(source[, .(
    herring_source_token,
    event_year = event_year__,
    anchor_shift_days = as.integer(anchor_shift_days__),
    used_end_date_fallback = as.logical(anchor_fallback__)
  )])
  attr(lookup, "source_hash") <- observed_hash
  attr(lookup, "raw_rows") <- raw_rows
  attr(lookup, "raw_start_missing") <- raw_start_missing
  attr(lookup, "raw_end_missing") <- raw_end_missing
  attr(lookup, "valid_source_records_1988_2025") <- nrow(source)
  attr(lookup, "valid_source_records_using_fallback") <-
    sum(source$anchor_fallback__)
  lookup
}

staged_refit_reanchor_links_v1 <- function(links, anchor_lookup) {
  .post_stage4a_require_fields_v1(
    links,
    c(
      "analysis_event_token", "herring_source_token", "event_year",
      "event_day", "distance_km"
    ),
    "staged-refit link table"
  )
  .post_stage4a_require_fields_v1(
    anchor_lookup,
    c(
      "herring_source_token", "event_year", "anchor_shift_days",
      "used_end_date_fallback"
    ),
    "staged-refit anchor lookup"
  )
  if (anyDuplicated(anchor_lookup$herring_source_token)) {
    stop("STAGED_REFIT_ANCHOR_JOIN_GATE: duplicate source lookup key",
         call. = FALSE)
  }
  # Declared cardinality: links (many) -> anchor lookup (one).
  index <- match(
    as.character(links$herring_source_token),
    as.character(anchor_lookup$herring_source_token)
  )
  if (anyNA(index)) {
    stop("STAGED_REFIT_ANCHOR_JOIN_GATE: unmatched source link",
         call. = FALSE)
  }
  if (!all(
      as.integer(links$event_year) ==
        as.integer(anchor_lookup$event_year[index])
  )) {
    stop("STAGED_REFIT_ANCHOR_JOIN_GATE: event-year disagreement",
         call. = FALSE)
  }
  out <- links
  out$event_day_parent__ <- as.integer(out$event_day)
  out$anchor_shift_days__ <-
    as.integer(anchor_lookup$anchor_shift_days[index])
  out$anchor_fallback__ <-
    as.logical(anchor_lookup$used_end_date_fallback[index])
  out$event_day <- out$event_day_parent__ + out$anchor_shift_days__
  if (nrow(out) != nrow(links) ||
      any(out$event_day - out$event_day_parent__ !=
            out$anchor_shift_days__)) {
    stop("STAGED_REFIT_ANCHOR_JOIN_CARDINALITY_GATE: links changed",
         call. = FALSE)
  }
  out
}

staged_refit_anchor_audit_v1 <- function(
    events, parent_links, anchored_links, anchor_lookup,
    distribution_links = anchored_links) {
  if (nrow(parent_links) != nrow(anchored_links)) {
    stop("STAGED_REFIT_ANCHOR_AUDIT_GATE: link rows differ", call. = FALSE)
  }
  key_equal <- as.character(parent_links$analysis_event_token) ==
    as.character(anchored_links$analysis_event_token) &
    as.character(parent_links$herring_source_token) ==
      as.character(anchored_links$herring_source_token)
  if (!all(key_equal)) {
    stop("STAGED_REFIT_ANCHOR_AUDIT_GATE: link order/key changed",
         call. = FALSE)
  }

  source_shift <- unique(distribution_links[, c(
    "herring_source_token", "anchor_shift_days__", "anchor_fallback__"
  )])
  if (anyDuplicated(source_shift$herring_source_token)) {
    stop("STAGED_REFIT_ANCHOR_AUDIT_GATE: inconsistent source shift",
         call. = FALSE)
  }
  exact <- as.data.frame(table(
    factor(
      source_shift$anchor_shift_days__,
      levels = sort(unique(source_shift$anchor_shift_days__))
    )
  ), stringsAsFactors = FALSE)
  names(exact) <- c("category", "value")
  exact$audit_section <- "anchor_shift_exact_days"
  exact$metric <- "linked_source_events"
  exact$unit <- "source_events"
  exact$note <- "shift equals floor(recorded span / 2)"

  bin <- ifelse(
    source_shift$anchor_shift_days__ < 0L,
    "negative_reversed_interval",
    ifelse(
      source_shift$anchor_shift_days__ >= 3L, "3+",
      as.character(source_shift$anchor_shift_days__)
    )
  )
  requested_levels <- c(
    "negative_reversed_interval", "0", "1", "2", "3+"
  )
  requested <- data.frame(
    category = requested_levels,
    value = as.integer(table(factor(bin, levels = requested_levels))),
    audit_section = "anchor_shift_requested_bins",
    metric = "linked_source_events",
    unit = "source_events",
    note = paste0(
      "prespecified nonnegative bins plus explicit reversed-interval audit"
    ),
    stringsAsFactors = FALSE
  )

  parent_class <- post_stage4a_classify_links_v1(parent_links)
  s1_class <- post_stage4a_classify_links_v1(anchored_links)
  parent_window <- !is.na(parent_class$period)
  s1_window <- !is.na(s1_class$period)
  event_index <- match(
    as.character(parent_links$analysis_event_token),
    as.character(events$analysis_event_token)
  )
  if (anyNA(event_index)) {
    stop("STAGED_REFIT_ANCHOR_AUDIT_GATE: link-to-event join failed",
         call. = FALSE)
  }
  source_parent <- unique(parent_links$herring_source_token[parent_window])
  source_s1 <- unique(anchored_links$herring_source_token[s1_window])
  block_parent <- unique(events$event_block_token[event_index[parent_window]])
  block_s1 <- unique(events$event_block_token[event_index[s1_window]])
  checklist_parent <-
    unique(parent_links$analysis_event_token[parent_window])
  checklist_s1 <- unique(anchored_links$analysis_event_token[s1_window])
  scope_metric <- c(
    "raw_herring_source_rows",
    "raw_source_rows_start_date_missing",
    "raw_source_rows_end_date_missing",
    "valid_source_records_1988_2025",
    "valid_source_records_using_end_date_fallback",
    "linked_source_events",
    "linked_source_events_using_end_date_fallback",
    "eligible_checklist_model_rows_parent",
    "eligible_checklist_model_rows_s1",
    "checklists_with_analysis_window_link_parent",
    "checklists_with_analysis_window_link_s1",
    "checklists_dropped_from_analysis_window",
    "checklists_added_to_analysis_window",
    "source_events_with_analysis_window_link_parent",
    "source_events_with_analysis_window_link_s1",
    "source_events_dropped_from_analysis_window",
    "source_events_added_to_analysis_window",
    "event_blocks_with_analysis_window_link_parent",
    "event_blocks_with_analysis_window_link_s1",
    "event_blocks_dropped_from_analysis_window",
    "event_blocks_added_to_analysis_window"
  )
  scope_value <- c(
    attr(anchor_lookup, "raw_rows"),
    attr(anchor_lookup, "raw_start_missing"),
    attr(anchor_lookup, "raw_end_missing"),
    attr(anchor_lookup, "valid_source_records_1988_2025"),
    attr(anchor_lookup, "valid_source_records_using_fallback"),
    nrow(source_shift),
    sum(source_shift$anchor_fallback__),
    nrow(events),
    nrow(events),
    length(checklist_parent),
    length(checklist_s1),
    length(setdiff(checklist_parent, checklist_s1)),
    length(setdiff(checklist_s1, checklist_parent)),
    length(source_parent),
    length(source_s1),
    length(setdiff(source_parent, source_s1)),
    length(setdiff(source_s1, source_parent)),
    length(block_parent),
    length(block_s1),
    length(setdiff(block_parent, block_s1)),
    length(setdiff(block_s1, block_parent))
  )
  scope <- data.frame(
    category = "all",
    value = as.numeric(scope_value),
    audit_section = "scope_and_fallback",
    metric = scope_metric,
    unit = ifelse(
      grepl("checklist", scope_metric), "checklists",
      ifelse(grepl("block", scope_metric), "event_blocks",
             "source_events")
    ),
    note = "aggregate only; no source or checklist identifiers released",
    stringsAsFactors = FALSE
  )
  out <- rbind(
    exact[, c("audit_section", "metric", "category", "value", "unit", "note")],
    requested[, c(
      "audit_section", "metric", "category", "value", "unit", "note"
    )],
    scope[, c("audit_section", "metric", "category", "value", "unit", "note")]
  )

  parent_period <- ifelse(
    is.na(parent_class$period), "outside_analysis_window", parent_class$period
  )
  s1_period <- ifelse(
    is.na(s1_class$period), "outside_analysis_window", s1_class$period
  )
  migration <- data.table::data.table(
    parent_period = parent_period,
    s1_period = s1_period,
    zone = parent_class$zone
  )[, .(link_count = .N), by = .(parent_period, s1_period, zone)]
  migration[, changed_period := parent_period != s1_period]
  migration[, parent_period_links := sum(link_count), by = parent_period]
  migration[, share_of_parent_period := link_count / parent_period_links]
  period_order <- c(
    post_stage4a_period_spec_v1()$period, "outside_analysis_window"
  )
  migration[, parent_order__ := match(parent_period, period_order)]
  migration[, s1_order__ := match(s1_period, period_order)]
  migration[, zone_order__ := match(zone, c("near", "reference"))]
  data.table::setorder(
    migration, parent_order__, s1_order__, zone_order__
  )
  migration[, c("parent_order__", "s1_order__", "zone_order__") := NULL]
  list(anchor_audit = out, migration = as.data.frame(migration))
}

staged_refit_s1_contrast_weights_v1 <- function() {
  term <- function(zone, period) paste("es", zone, period, sep = "_")
  did <- function(period) {
    stats::setNames(
      c(1, -1, -1, 1),
      c(
        term("near", period), term("reference", period),
        term("near", "baseline"), term("reference", "baseline")
      )
    )
  }
  combine <- function(...) {
    out <- numeric()
    for (piece in list(...)) {
      for (name in names(piece)) {
        out[[name]] <- if (name %in% names(out)) {
          out[[name]] + piece[[name]]
        } else {
          piece[[name]]
        }
      }
    }
    out
  }
  active <- combine(
    (4 / 15) * did("spawn_start"),
    (11 / 15) * did("early_egg")
  )
  pre14 <- combine(
    0.5 * did("early_pre"),
    0.5 * did("immediate_pre")
  )
  list(
    active_minus_pre14 = combine(active, -pre14),
    active_minus_pre7 = combine(active, -did("immediate_pre")),
    spawn_start_minus_early_egg =
      combine(did("spawn_start"), -did("early_egg"))
  )
}

staged_refit_wald_v1 <- function(beta, covariance, weights) {
  vector <- .post_stage4a_contrast_vector_v1(names(beta), weights)
  if (is.null(vector)) {
    return(c(
      estimate = NA_real_, standard_error = NA_real_, conf_low = NA_real_,
      conf_high = NA_real_, p_value = NA_real_
    ))
  }
  estimate <- sum(vector * beta)
  variance <- drop(t(vector) %*% covariance %*% vector)
  standard_error <- if (is.finite(variance) && variance >= 0) {
    sqrt(variance)
  } else {
    NA_real_
  }
  p_value <- if (is.finite(standard_error) && standard_error > 0) {
    2 * stats::pnorm(-abs(estimate / standard_error))
  } else {
    NA_real_
  }
  z <- 1.959963984540054
  c(
    estimate = estimate,
    standard_error = standard_error,
    conf_low = estimate - z * standard_error,
    conf_high = estimate + z * standard_error,
    p_value = p_value
  )
}

staged_refit_random_variances_v1 <- function(fit) {
  vc <- as.data.frame(lme4::VarCorr(fit))
  value <- function(group) {
    x <- vc$vcov[vc$grp == group & is.na(vc$var2)]
    if (length(x)) x[[1L]] else NA_real_
  }
  c(
    event_block_variance = value("event_block_token"),
    observer_variance = value("observer_cluster_token"),
    location_variance = value("location_cluster_token"),
    residual_variance = if ("Residual" %in% vc$grp) {
      value("Residual")
    } else {
      NA_real_
    }
  )
}

staged_refit_s1_empty_component_v1 <- function(
    taxon_id, unit_label, analysis_role, outcome, n, status) {
  contrasts <- do.call(rbind, lapply(
    names(staged_refit_s1_contrast_weights_v1()),
    function(comparison) {
      data.frame(
        analysis_version = staged_refit_s1_version_v1(),
        stage = "s1_anchor",
        analysis_taxon_id = taxon_id,
        species = unit_label,
        analysis_role = analysis_role,
        outcome = outcome,
        comparison = comparison,
        primary_comparison = comparison == "active_minus_pre14",
        estimate = NA_real_,
        standard_error = NA_real_,
        conf_low = NA_real_,
        conf_high = NA_real_,
        ratio = NA_real_,
        ratio_conf_low = NA_real_,
        ratio_conf_high = NA_real_,
        p_value = NA_real_,
        q_value = NA_real_,
        n = .post_stage4a_release_count_v1(n),
        full_fixed_effect_covariance_used = TRUE,
        status = status,
        stringsAsFactors = FALSE
      )
    }
  ))
  diagnostic <- data.frame(
    analysis_version = staged_refit_s1_version_v1(),
    stage = "s1_anchor",
    analysis_taxon_id = taxon_id,
    species = unit_label,
    analysis_role = analysis_role,
    outcome = outcome,
    engine = if (outcome == "conditional_positive_numeric_count") {
      "lme4_lmer_REML"
    } else {
      "lme4_glmer_nAGQ0"
    },
    n = .post_stage4a_release_count_v1(n),
    converged = FALSE,
    singular_fit = NA,
    rank_deficient = NA,
    convergence_message = status,
    maximum_absolute_gradient = NA_real_,
    event_block_variance = NA_real_,
    observer_variance = NA_real_,
    location_variance = NA_real_,
    residual_variance = NA_real_,
    status = status,
    stringsAsFactors = FALSE
  )
  list(contrasts = contrasts, diagnostic = diagnostic)
}

staged_refit_s1_fit_component_v1 <- function(
    dat, taxon_id, unit_label, analysis_role, outcome,
    checkpoint_path, cache_signature) {
  if (file.exists(checkpoint_path)) {
    cached <- readRDS(checkpoint_path)
    if (identical(cached$cache_signature, cache_signature)) {
      return(cached$result)
    }
  }
  if (outcome == "checklist_reporting") {
    use <- !is.na(dat$detection)
    dat$model_response <- dat$detection
  } else if (outcome == "conditional_positive_numeric_count") {
    use <- is.finite(dat$numeric_count) & dat$numeric_count > 0
    dat$model_response <- log(dat$numeric_count)
  } else {
    stop("STAGED_REFIT_OUTCOME_GATE: unsupported outcome", call. = FALSE)
  }
  d <- dat[use, , drop = FALSE]
  terms <- post_stage4a_exposure_terms_v1()
  exposed <- vapply(terms, function(term) sum(d[[term]] > 0L), integer(1L))
  grouping_levels <- c(
    event_block_token = length(unique(d$event_block_token)),
    observer_cluster_token = length(unique(d$observer_cluster_token)),
    location_cluster_token = length(unique(d$location_cluster_token))
  )
  insufficient <- nrow(d) < 20L ||
    length(unique(d$model_response)) < 2L ||
    any(exposed < 20L) ||
    any(grouping_levels < 2L)
  if (insufficient) {
    result <- staged_refit_s1_empty_component_v1(
      taxon_id, unit_label, analysis_role, outcome, nrow(d),
      "failed_insufficient_support"
    )
    saveRDS(
      list(cache_signature = cache_signature, result = result),
      checkpoint_path
    )
    return(result)
  }

  formula <- post_stage4a_formula_v1("model_response")
  fit <- try(
    if (outcome == "checklist_reporting") {
      lme4::glmer(
        formula,
        data = d,
        family = stats::binomial(),
        nAGQ = 0L,
        control = lme4::glmerControl(
          optimizer = "nloptwrap",
          calc.derivs = TRUE,
          optCtrl = list(maxeval = 10000L)
        )
      )
    } else {
      lme4::lmer(
        formula,
        data = d,
        REML = TRUE,
        control = lme4::lmerControl(
          optimizer = "nloptwrap",
          calc.derivs = TRUE,
          optCtrl = list(maxeval = 10000L)
        )
      )
    },
    silent = TRUE
  )
  if (inherits(fit, "try-error")) {
    result <- staged_refit_s1_empty_component_v1(
      taxon_id, unit_label, analysis_role, outcome, nrow(d),
      "failed_numerical_fit_no_fallback"
    )
    result$diagnostic$convergence_message <- substr(
      gsub("[\r\n]+", " ", as.character(fit)), 1L, 240L
    )
    saveRDS(
      list(cache_signature = cache_signature, result = result),
      checkpoint_path
    )
    return(result)
  }

  beta <- lme4::fixef(fit)
  covariance <- as.matrix(stats::vcov(fit))
  singular <- lme4::isSingular(fit, tol = 1e-4)
  optimizer_code <- fit@optinfo$conv$opt
  classification <- .post_stage4a_model_messages_v1(
    optimizer_code, fit@optinfo$conv$lme4$messages, singular
  )
  rank_deficient <- length(beta) < ncol(stats::model.matrix(
    lme4::nobars(formula), d
  ))
  optimizer_completed <- length(optimizer_code) == 1L &&
    !is.na(optimizer_code) && optimizer_code == 0L
  status <- if (!classification$converged && optimizer_completed) {
    "completed_with_convergence_warning"
  } else if (!classification$converged) {
    "failed_convergence"
  } else if (singular) {
    "completed_with_singular_warning"
  } else if (rank_deficient) {
    "completed_with_rank_deficiency_warning"
  } else {
    "completed"
  }
  weights <- staged_refit_s1_contrast_weights_v1()
  contrasts <- do.call(rbind, lapply(names(weights), function(comparison) {
    x <- staged_refit_wald_v1(beta, covariance, weights[[comparison]])
    row_status <- if (
      is.finite(x[["estimate"]]) &&
        is.finite(x[["standard_error"]]) &&
        x[["standard_error"]] > 0
    ) {
      status
    } else {
      "failed_contrast_geometry"
    }
    data.frame(
      analysis_version = staged_refit_s1_version_v1(),
      stage = "s1_anchor",
      analysis_taxon_id = taxon_id,
      species = unit_label,
      analysis_role = analysis_role,
      outcome = outcome,
      comparison = comparison,
      primary_comparison = comparison == "active_minus_pre14",
      estimate = x[["estimate"]],
      standard_error = x[["standard_error"]],
      conf_low = x[["conf_low"]],
      conf_high = x[["conf_high"]],
      ratio = exp(x[["estimate"]]),
      ratio_conf_low = exp(x[["conf_low"]]),
      ratio_conf_high = exp(x[["conf_high"]]),
      p_value = x[["p_value"]],
      q_value = NA_real_,
      n = .post_stage4a_release_count_v1(nrow(d)),
      full_fixed_effect_covariance_used = TRUE,
      status = row_status,
      stringsAsFactors = FALSE
    )
  }))
  gradients <- fit@optinfo$derivs$gradient
  variances <- staged_refit_random_variances_v1(fit)
  diagnostic <- data.frame(
    analysis_version = staged_refit_s1_version_v1(),
    stage = "s1_anchor",
    analysis_taxon_id = taxon_id,
    species = unit_label,
    analysis_role = analysis_role,
    outcome = outcome,
    engine = if (outcome == "conditional_positive_numeric_count") {
      "lme4_lmer_REML"
    } else {
      "lme4_glmer_nAGQ0"
    },
    n = .post_stage4a_release_count_v1(nrow(d)),
    converged = classification$converged,
    singular_fit = singular,
    rank_deficient = rank_deficient,
    convergence_message = classification$message,
    maximum_absolute_gradient = if (is.null(gradients)) {
      NA_real_
    } else {
      max(abs(gradients))
    },
    event_block_variance = variances[["event_block_variance"]],
    observer_variance = variances[["observer_variance"]],
    location_variance = variances[["location_variance"]],
    residual_variance = variances[["residual_variance"]],
    status = status,
    stringsAsFactors = FALSE
  )
  result <- list(
    contrasts = contrasts,
    diagnostic = diagnostic,
    beta = beta,
    covariance = covariance
  )
  saveRDS(
    list(cache_signature = cache_signature, result = result),
    checkpoint_path
  )
  result
}

staged_refit_adjust_bh_v1 <- function(contrasts, family_prefix) {
  contrasts$q_value <- NA_real_
  family <- paste(contrasts$outcome, contrasts$comparison, sep = "__")
  for (name in unique(family)) {
    index <- which(family == name & is.finite(contrasts$p_value))
    contrasts$q_value[index] <- stats::p.adjust(
      contrasts$p_value[index], method = "BH"
    )
  }
  contrasts$multiplicity_family <- paste0(family_prefix, "__", family)
  contrasts
}

staged_refit_process_core_taxon_v1 <- function(
    taxon_id, events, states, masks, species_registry,
    checkpoint_dir, run_signature) {
  unit_label <- species_registry$common_name[
    match(taxon_id, species_registry$analysis_taxon_id)
  ]
  if (length(unit_label) != 1L || is.na(unit_label) || !nzchar(unit_label)) {
    stop("STAGED_REFIT_TAXON_NAME_GATE: unresolved core taxon",
         call. = FALSE)
  }
  dat <- stage4a_materialize_taxon(events, states, masks, taxon_id)
  models <- lapply(
    c("checklist_reporting", "conditional_positive_numeric_count"),
    function(outcome) {
      checkpoint <- file.path(
        checkpoint_dir, paste(taxon_id, outcome, "rds", sep = "_")
      )
      staged_refit_s1_fit_component_v1(
        dat, taxon_id, unit_label, "core_species", outcome, checkpoint,
        paste(run_signature, taxon_id, outcome, sep = "|")
      )
    }
  )
  names(models) <- c(
    "checklist_reporting", "conditional_positive_numeric_count"
  )
  models
}

staged_refit_parallel_core_v1 <- function(
    taxa, events, states, masks, species_registry,
    checkpoint_dir, run_signature, workers) {
  if (!length(taxa)) return(list())
  workers <- min(as.integer(workers), length(taxa))
  fit_one <- function(taxon_id) {
    staged_refit_process_core_taxon_v1(
      taxon_id, events, states, masks, species_registry,
      checkpoint_dir, run_signature
    )
  }
  if (workers <= 1L) return(lapply(taxa, fit_one))
  cluster <- parallel::makePSOCKcluster(workers)
  tryCatch({
    parallel::clusterEvalQ(cluster, {
      Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
      source(file.path("R", "stage4a_core.R"), local = FALSE)
      source(file.path("R", "stage4a_production.R"), local = FALSE)
      source(file.path("R", "post_stage4a_sog_event_study_v1.R"),
             local = FALSE)
      source(file.path("R", "post_stage4a_distance_band_sensitivity_v2.R"),
             local = FALSE)
      source(file.path("R", "post_stage4a_staged_refit_v1.R"),
             local = FALSE)
      NULL
    })
    parallel::clusterExport(
      cluster,
      c(
        "events", "states", "masks", "species_registry", "checkpoint_dir",
        "run_signature"
      ),
      envir = environment()
    )
    parallel::parLapply(cluster, taxa, function(taxon_id) {
      staged_refit_process_core_taxon_v1(
        taxon_id, events, states, masks, species_registry,
        checkpoint_dir, run_signature
      )
    })
  }, finally = {
    parallel::stopCluster(cluster)
  })
}

staged_refit_flatten_models_v1 <- function(results, field) {
  pieces <- unlist(lapply(results, function(x) lapply(x, `[[`, field)),
                   recursive = FALSE)
  pieces <- pieces[vapply(
    pieces, function(x) is.data.frame(x) && nrow(x), logical(1L)
  )]
  if (!length(pieces)) return(data.frame())
  do.call(rbind, pieces)
}

staged_refit_load_control_denominators_v1 <- function(events, extract_path) {
  if (!file.exists(extract_path) || file.info(extract_path)$size == 0) {
    stop("STAGED_REFIT_CONTROL_EXTRACT_GATE: protected extract unavailable",
         call. = FALSE)
  }
  selected_names <- c("American Robin", "Chestnut-backed Chickadee")
  source_names <- c(
    "CATEGORY", "COMMON NAME", "SCIENTIFIC NAME", "OBSERVATION COUNT",
    "SAMPLING EVENT IDENTIFIER", "OBSERVATION DATE"
  )
  ebd <- data.table::fread(
    extract_path,
    sep = "\t",
    header = TRUE,
    select = source_names,
    quote = "",
    na.strings = c("", "NA"),
    showProgress = FALSE
  )
  data.table::setnames(
    ebd,
    source_names,
    c(
      "category", "common_name", "scientific_name", "observation_count",
      "source_id", "observation_date"
    )
  )
  ebd[, observation_date := data.table::as.IDate(observation_date)]
  if (any(
      ebd$observation_date > data.table::as.IDate("2025-12-31"),
      na.rm = TRUE
  )) {
    stop("STAGED_REFIT_CONTROL_YEAR_GATE: 2026+ response row persisted",
         call. = FALSE)
  }
  ebd <- ebd[category == "species" & common_name %in% selected_names]
  if (!setequal(unique(ebd$common_name), selected_names)) {
    stop("STAGED_REFIT_CONTROL_TAXON_GATE: mandatory control missing",
         call. = FALSE)
  }
  taxonomy <- ebd[, .(
    scientific_name = paste(sort(unique(scientific_name)), collapse = ";")
  ), by = common_name]
  if (any(grepl(";", taxonomy$scientific_name, fixed = TRUE))) {
    stop("STAGED_REFIT_CONTROL_TAXONOMY_GATE: scientific-name ambiguity",
         call. = FALSE)
  }

  sed_cache <- readRDS(file.path(
    "outputs", "input_audit_local", "stage2", "sed_stage2_cache.rds"
  ))
  if (!identical(sort(names(sed_cache)), sort(c(
      "checklists", "cross_private", "shared_audit"
  )))) {
    stop("STAGED_REFIT_CONTROL_SED_CACHE_GATE: unexpected schema",
         call. = FALSE)
  }
  cross <- data.table::as.data.table(sed_cache$cross_private)[
    , .(source_id, analysis_id)
  ]
  if (anyDuplicated(cross$source_id)) {
    stop("STAGED_REFIT_CONTROL_SOURCE_JOIN_GATE: source crosswalk duplicated",
         call. = FALSE)
  }
  # Declared cardinality: EBD reports (many) -> source crosswalk (one).
  data.table::setkey(cross, source_id)
  before <- nrow(ebd)
  ebd <- cross[ebd, on = "source_id", nomatch = 0L]
  if (!nrow(ebd) || nrow(ebd) > before) {
    stop("STAGED_REFIT_CONTROL_SOURCE_JOIN_GATE: join cardinality failed",
         call. = FALSE)
  }

  raw <- trimws(as.character(ebd$observation_count))
  numeric_syntax <- grepl("^[0-9]+$", raw)
  lower_syntax <- grepl(
    "^(>=|>|at least[[:space:]]+)?[0-9]+[+]?$",
    raw,
    ignore.case = TRUE
  ) & !numeric_syntax
  ebd[, count_state := data.table::fifelse(
    toupper(raw) == "X",
    "X",
    data.table::fifelse(
      numeric_syntax,
      "numeric",
      data.table::fifelse(
        lower_syntax, "lower_bound", "ambiguity_affected"
      )
    )
  )]
  ebd[, numeric_count := data.table::fifelse(
    numeric_syntax, as.numeric(raw), NA_real_
  )]
  ebd[, lower_bound_count := data.table::fifelse(
    lower_syntax, as.numeric(gsub("[^0-9]", "", raw)), NA_real_
  )]
  collapsed <- ebd[, {
    signatures <- unique(paste(
      count_state, numeric_count, lower_bound_count, sep = "|"
    ))
    if (length(signatures) == 1L) {
      .(
        count_state = count_state[[1L]],
        numeric_count = numeric_count[[1L]],
        lower_bound_count = lower_bound_count[[1L]]
      )
    } else {
      .(
        count_state = "ambiguity_affected",
        numeric_count = NA_real_,
        lower_bound_count = NA_real_
      )
    }
  }, by = .(analysis_id, common_name)]
  if (anyDuplicated(collapsed[, .(analysis_id, common_name)])) {
    stop("STAGED_REFIT_CONTROL_COLLAPSE_GATE: duplicate outcome",
         call. = FALSE)
  }
  collapsed[, analysis_event_token := staged_refit_hash_token_v1(
    "analysis_event", analysis_id
  )]
  event_tokens <- as.character(events$analysis_event_token)
  denominators <- setNames(vector("list", length(selected_names)),
                           selected_names)
  for (species in selected_names) {
    z <- collapsed[common_name == species]
    index <- match(event_tokens, z$analysis_event_token)
    dat <- events
    dat$detection <- ifelse(is.na(index), 0L, 1L)
    ambiguity <- !is.na(index) &
      z$count_state[index] == "ambiguity_affected"
    dat$detection[ambiguity] <- NA_integer_
    dat$numeric_count <- z$numeric_count[index]
    dat$count_type <- z$count_state[index]
    taxon_id <- paste0(
      "ctl_",
      substr(digest::digest(
        paste0("terrestrial_control|", species),
        algo = "sha256",
        serialize = FALSE
      ), 1L, 12L)
    )
    denominators[[species]] <- list(
      data = dat,
      taxon_id = taxon_id,
      scientific_name = taxonomy$scientific_name[
        match(species, taxonomy$common_name)
      ]
    )
  }
  attr(denominators, "extract_hash") <-
    .post_stage4a_sha256_v1(extract_path)
  attr(denominators, "joined_report_rows") <- nrow(ebd)
  attr(denominators, "collapsed_control_checklist_species_rows") <-
    nrow(collapsed)
  denominators
}

staged_refit_fit_controls_v1 <- function(
    denominators, checkpoint_dir, run_signature) {
  results <- list()
  for (species in names(denominators)) {
    info <- denominators[[species]]
    results[[species]] <- lapply(
      c("checklist_reporting", "conditional_positive_numeric_count"),
      function(outcome) {
        checkpoint <- file.path(
          checkpoint_dir,
          paste0(
            gsub("[^A-Za-z0-9]+", "_", tolower(species)),
            "_", outcome, ".rds"
          )
        )
        staged_refit_s1_fit_component_v1(
          info$data,
          info$taxon_id,
          species,
          "negative_control",
          outcome,
          checkpoint,
          paste(run_signature, species, outcome, sep = "|")
        )
      }
    )
    names(results[[species]]) <- c(
      "checklist_reporting", "conditional_positive_numeric_count"
    )
  }
  results
}

staged_refit_parent_primary_v1 <- function() {
  parent_path <- file.path(
    ".worktrees", "conventional-sensitivity-v9", "outputs",
    "editorial_requested_analysis_v1", "active_minus_pre_contrasts.csv"
  )
  manifest_path <- file.path(
    ".worktrees", "conventional-sensitivity-v9", "outputs",
    "editorial_requested_analysis_v1", "output_hash_manifest.csv"
  )
  if (!file.exists(parent_path) || !file.exists(manifest_path)) {
    stop(
      paste0(
        "STAGED_REFIT_PUBLISHED_PARENT_GATE: the exact editorial ",
        "active-minus-pre aggregate is unavailable"
      ),
      call. = FALSE
    )
  }
  expected_parent_hash <-
    "8fe49d6f9d4edc60e248608c4cd9f35581932db762f711cf903227ed2d4ce861"
  if (!identical(
      .post_stage4a_sha256_v1(parent_path),
      expected_parent_hash
  )) {
    stop("STAGED_REFIT_PUBLISHED_PARENT_HASH_GATE: frozen hash mismatch",
         call. = FALSE)
  }
  manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE)
  row <- which(
    basename(gsub("\\\\", "/", manifest$file)) ==
      "active_minus_pre_contrasts.csv"
  )
  if (length(row) != 1L ||
      !identical(
        .post_stage4a_sha256_v1(parent_path),
        manifest$sha256[[row]]
      )) {
    stop("STAGED_REFIT_PUBLISHED_PARENT_HASH_GATE: mismatch",
         call. = FALSE)
  }
  parent <- utils::read.csv(parent_path, stringsAsFactors = FALSE)
  parent <- parent[
    parent$comparison == "active_minus_pre14" &
      parent$outcome %in% c(
        "checklist_reporting", "conditional_positive_numeric_count"
      ),
    ,
    drop = FALSE
  ]
  key <- paste(parent$analysis_taxon_id, parent$outcome, sep = "\r")
  if (nrow(parent) != 98L || anyDuplicated(key)) {
    stop("STAGED_REFIT_PUBLISHED_PARENT_CARDINALITY_GATE: expected 49 x 2",
         call. = FALSE)
  }
  published <- utils::read.csv(
    "figures_out/tableS_primary_contrast_49x2.csv",
    stringsAsFactors = FALSE
  )
  pub_key <- paste(published$species, published$outcome, sep = "\r")
  parent_outcome <- ifelse(
    parent$outcome == "checklist_reporting",
    "checklist_reporting",
    "conditional_positive_numeric_count"
  )
  parent_key <- paste(parent$species, parent_outcome, sep = "\r")
  index <- match(pub_key, parent_key)
  same_numeric <- function(left, right, tolerance = 1e-12) {
    missing_left <- is.na(left)
    missing_right <- is.na(right)
    identical(missing_left, missing_right) &&
      (
        all(missing_left) ||
          max(abs(left[!missing_left] - right[!missing_right])) <=
            tolerance
      )
  }
  if (nrow(published) != 98L || anyNA(index) ||
      anyDuplicated(pub_key) ||
      !same_numeric(
        as.numeric(published$ratio),
        as.numeric(parent$ratio[index])
      ) ||
      !same_numeric(
        as.numeric(published$q_value),
        as.numeric(parent$q_value[index])
      )) {
    stop(
      "STAGED_REFIT_PUBLISHED_PARENT_RECONCILIATION_GATE: manuscript table differs",
      call. = FALSE
    )
  }
  attr(parent, "source_path") <- gsub("\\\\", "/", parent_path)
  attr(parent, "source_hash") <- .post_stage4a_sha256_v1(parent_path)
  parent
}

staged_refit_delta_vs_parent_v1 <- function(primary, parent) {
  new_key <- paste(primary$analysis_taxon_id, primary$outcome, sep = "\r")
  old_key <- paste(parent$analysis_taxon_id, parent$outcome, sep = "\r")
  if (length(new_key) != 98L || anyDuplicated(new_key) ||
      length(old_key) != 98L || anyDuplicated(old_key)) {
    stop("STAGED_REFIT_DELTA_JOIN_GATE: expected unique 49 x 2 keys",
         call. = FALSE)
  }
  index <- match(new_key, old_key)
  if (anyNA(index)) {
    stop("STAGED_REFIT_DELTA_JOIN_GATE: unmatched parent contrast",
         call. = FALSE)
  }
  data.frame(
    stage = "s1_anchor",
    analysis_taxon_id = primary$analysis_taxon_id,
    species = primary$species,
    outcome = primary$outcome,
    comparison = primary$comparison,
    parent_estimate = as.numeric(parent$estimate[index]),
    s1_estimate = primary$estimate,
    estimate_delta = primary$estimate - as.numeric(parent$estimate[index]),
    parent_standard_error = as.numeric(parent$standard_error[index]),
    s1_standard_error = primary$standard_error,
    parent_ratio = as.numeric(parent$ratio[index]),
    s1_ratio = primary$ratio,
    parent_q_value = as.numeric(parent$q_value[index]),
    s1_q_value = primary$q_value,
    parent_status = parent$status[index],
    s1_status = primary$status,
    changed_direction = sign(primary$estimate) !=
      sign(as.numeric(parent$estimate[index])),
    changed_bh_significance = (primary$q_value < 0.05) !=
      (as.numeric(parent$q_value[index]) < 0.05),
    stringsAsFactors = FALSE
  )
}

staged_refit_guild_timing_v1 <- function(core_contrasts, species_registry) {
  timing <- core_contrasts[
    core_contrasts$comparison == "spawn_start_minus_early_egg" &
      is.finite(core_contrasts$estimate) &
      is.finite(core_contrasts$standard_error) &
      core_contrasts$standard_error > 0,
    ,
    drop = FALSE
  ]
  guild_lookup <- species_registry[, c(
    "analysis_taxon_id", "common_name", "guild_ids"
  )]
  if (anyDuplicated(guild_lookup$analysis_taxon_id)) {
    stop("STAGED_REFIT_GUILD_JOIN_GATE: registry key duplicated",
         call. = FALSE)
  }
  index <- match(timing$analysis_taxon_id, guild_lookup$analysis_taxon_id)
  if (anyNA(index) ||
      any(timing$species != guild_lookup$common_name[index])) {
    stop("STAGED_REFIT_GUILD_JOIN_GATE: species-to-guild join failed",
         call. = FALSE)
  }
  timing$guild <- guild_lookup$guild_ids[index]
  output <- list()
  j <- 0L
  for (outcome_now in unique(timing$outcome)) {
    x <- timing[timing$outcome == outcome_now, , drop = FALSE]
    factor_guild <- factor(x$guild)
    design <- stats::model.matrix(~ 0 + factor_guild)
    weight <- 1 / (x$standard_error^2)
    information <- crossprod(design, weight * design)
    if (qr(information)$rank != ncol(information)) {
      stop("STAGED_REFIT_GUILD_GEOMETRY_GATE: rank deficiency",
           call. = FALSE)
    }
    coefficient <- solve(
      information, crossprod(design, weight * x$estimate)
    )
    coefficient_covariance <- solve(information)
    coefficient_se <- sqrt(diag(coefficient_covariance))
    fitted <- drop(design %*% coefficient)
    grand_mean <- sum(weight * x$estimate) / sum(weight)
    q_total <- sum(weight * (x$estimate - grand_mean)^2)
    q_residual <- sum(weight * (x$estimate - fitted)^2)
    q_between <- q_total - q_residual
    guild_names <- levels(factor_guild)
    df_between <- length(guild_names) - 1L
    df_residual <- nrow(x) - length(guild_names)
    z <- 1.959963984540054
    j <- j + 1L
    output[[j]] <- data.frame(
      stage = "s1_anchor",
      row_type = "guild_mean",
      outcome = outcome_now,
      guild = guild_names,
      species = as.integer(table(factor_guild)[guild_names]),
      estimate = drop(coefficient),
      standard_error = coefficient_se,
      conf_low = drop(coefficient) - z * coefficient_se,
      conf_high = drop(coefficient) + z * coefficient_se,
      ratio_spawn_start_vs_early_egg = exp(drop(coefficient)),
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
      variance_method = "full_fixed_effect_covariance",
      stringsAsFactors = FALSE
    )
  }
  do.call(rbind, output)
}

staged_refit_augment_guild_parent_v1 <- function(
    guild_timing,
    means_path = file.path(
      "outputs", "referee_reads_followup_v1", "item10_guild_means.csv"
    ),
    tests_path = file.path(
      "outputs", "referee_reads_followup_v1",
      "item10_meta_regression_tests.csv"
    )) {
  expected_hashes <- c(
    means =
      "adf518b01daac652a22aa6a998c0af40e9597e5aaa45205ec6d27e8a590ed1f4",
    tests =
      "6b3c4f916f7ef38b3a2db5cf74318ca45f288613af729e263bbe8f2497cf10a3"
  )
  observed_hashes <- c(
    means = .post_stage4a_sha256_v1(means_path),
    tests = .post_stage4a_sha256_v1(tests_path)
  )
  if (!identical(observed_hashes, expected_hashes)) {
    stop("STAGED_REFIT_GUILD_PARENT_HASH_GATE: mismatch",
         call. = FALSE)
  }
  parent_means <- utils::read.csv(
    means_path, stringsAsFactors = FALSE
  )
  parent_tests <- utils::read.csv(
    tests_path, stringsAsFactors = FALSE
  )
  parent_means$outcome <- ifelse(
    parent_means$outcome == "detection",
    "checklist_reporting",
    ifelse(
      parent_means$outcome == "positive_numeric_count_given_detection",
      "conditional_positive_numeric_count",
      parent_means$outcome
    )
  )
  parent_tests$outcome <- ifelse(
    parent_tests$outcome == "detection",
    "checklist_reporting",
    ifelse(
      parent_tests$outcome == "positive_numeric_count_given_detection",
      "conditional_positive_numeric_count",
      parent_tests$outcome
    )
  )
  key <- paste(guild_timing$outcome, guild_timing$guild, sep = "\r")
  parent_key <- paste(
    parent_means$outcome, parent_means$guild, sep = "\r"
  )
  index <- match(key, parent_key)
  test_index <- match(guild_timing$outcome, parent_tests$outcome)
  if (
    nrow(guild_timing) != 14L ||
      nrow(parent_means) != 14L ||
      anyDuplicated(key) ||
      anyDuplicated(parent_key) ||
      anyNA(index) ||
      anyNA(test_index)
  ) {
    stop("STAGED_REFIT_GUILD_PARENT_JOIN_GATE: failed",
         call. = FALSE)
  }
  guild_timing$parent_estimate <-
    parent_means$exact_mean_link_contrast[index]
  guild_timing$parent_standard_error <-
    parent_means$exact_standard_error[index]
  guild_timing$parent_p_guild_differences <-
    parent_tests$exact_p_guild_differences[test_index]
  guild_timing$changed_direction <-
    sign(guild_timing$estimate) != sign(guild_timing$parent_estimate)
  guild_timing$parent_interval_excludes_zero <-
    parent_means$exact_interval_excludes_zero[index]
  guild_timing$s1_interval_excludes_zero <-
    guild_timing$conf_low > 0 | guild_timing$conf_high < 0
  guild_timing$changed_interval_significance <-
    guild_timing$parent_interval_excludes_zero !=
      guild_timing$s1_interval_excludes_zero
  guild_timing$changed_omnibus_significance <-
    (guild_timing$parent_p_guild_differences < 0.05) !=
      (guild_timing$p_guild_differences < 0.05)
  guild_timing
}

staged_refit_distance_links_v1 <- function(
    archived_links, extended_links, anchor_lookup) {
  key <- function(x) paste(
    x$analysis_event_token, x$herring_source_token, sep = "\r"
  )
  archived_key <- key(archived_links)
  extended_key <- key(extended_links)
  if (anyDuplicated(archived_key) || anyDuplicated(extended_key) ||
      !all(archived_key %in% extended_key)) {
    stop("STAGED_REFIT_DISTANCE_LINK_RECONCILIATION_GATE: key failure",
         call. = FALSE)
  }
  archived <- staged_refit_reanchor_links_v1(
    archived_links, anchor_lookup
  )
  extended <- staged_refit_reanchor_links_v1(
    extended_links, anchor_lookup
  )
  index <- match(archived_key, extended_key)
  if (anyNA(index) ||
      max(abs(
        as.numeric(archived$distance_km) -
          as.numeric(extended$distance_km[index])
      )) > 0.0011 ||
      any(
        as.integer(archived$event_day) !=
          as.integer(extended$event_day[index])
      )) {
    stop("STAGED_REFIT_DISTANCE_LINK_RECONCILIATION_GATE: value failure",
         call. = FALSE)
  }
  extra <- extended[!extended_key %in% archived_key, , drop = FALSE]
  if (!nrow(extra) ||
      any(as.numeric(extra$distance_km) < 20 |
          as.numeric(extra$distance_km) > 26.0001)) {
    stop("STAGED_REFIT_DISTANCE_EXTENSION_GATE: expected 20-26 km only",
         call. = FALSE)
  }
  archived$link_provenance__ <- "archived_0_20"
  extra$link_provenance__ <- "new_20_26"
  rbind(archived, extra)
}

staged_refit_fit_distance_species_v1 <- function(
    dat, species, taxon_id, checkpoint_dir, run_signature) {
  results <- lapply(
    c("detection", "positive_numeric_count_given_detection"),
    function(outcome) {
      checkpoint <- file.path(
        checkpoint_dir,
        paste0(
          gsub("[^A-Za-z0-9]+", "_", tolower(species)),
          "_", outcome, ".rds"
        )
      )
      cache_signature <- paste(
        run_signature, species, outcome, sep = "|"
      )
      result <- try(
        post_stage4a_fit_distance_band_component_v2(
          dat, outcome, checkpoint, cache_signature
        ),
        silent = TRUE
      )
      if (inherits(result, "try-error")) {
        model_n <- if (outcome == "detection") {
          sum(!is.na(dat$detection))
        } else {
          sum(is.finite(dat$numeric_count) & dat$numeric_count > 0)
        }
        model_n <- .post_stage4a_release_count_v1(model_n)
        definitions <- post_stage4a_distance_band_contrasts_v2(
          c("(Intercept)", post_stage4a_distance_band_terms_v2())
        )
        effects <- do.call(rbind, lapply(definitions, function(definition) {
          data.frame(
            model_version_id = NA_character_,
            analysis_taxon_id = taxon_id,
            unit_label = species,
            region = "SoG",
            outcome = outcome,
            band = definition$band,
            band_label = definition$band_label,
            contrast = definition$contrast,
            contrast_type = definition$contrast_type,
            period = definition$period,
            minimum_day = definition$minimum_day,
            maximum_day = definition$maximum_day,
            estimate = NA_real_,
            standard_error = NA_real_,
            conf_low = NA_real_,
            conf_high = NA_real_,
            ratio = NA_real_,
            ratio_conf_low = NA_real_,
            ratio_conf_high = NA_real_,
            p_value = NA_real_,
            n = model_n,
            status = "failed_distance_fit_no_fallback",
            stringsAsFactors = FALSE
          )
        }))
        result <- list(
          effects = effects,
          diagnostic = data.frame(
            model_version_id = NA_character_,
            analysis_taxon_id = taxon_id,
            unit_label = species,
            region = "SoG",
            outcome = outcome,
            converged = FALSE,
            singular_fit = NA,
            rank_deficient = NA,
            convergence_message = substr(
              gsub("[\r\n]+", " ", as.character(result)),
              1L, 240L
            ),
            n = model_n,
            status = "failed_distance_fit_no_fallback",
            stringsAsFactors = FALSE
          ),
          term_support = data.frame(),
          fixed_effects = data.frame(),
          exposure_covariance = data.frame()
        )
        saveRDS(
          list(cache_signature = cache_signature, result = result),
          checkpoint
        )
      }
      version <- paste0(
        "SOG_STAGED_REFIT_S1_DISTANCE_",
        toupper(gsub("[^A-Za-z0-9]+", "_", species)),
        "_v1"
      )
      for (part in c(
          "effects", "diagnostic", "term_support", "fixed_effects",
          "exposure_covariance"
      )) {
        if (nrow(result[[part]])) {
          result[[part]]$model_version_id <- version
          result[[part]]$analysis_taxon_id <- taxon_id
          result[[part]]$unit_label <- species
        }
      }
      result
    }
  )
  names(results) <- c("detection", "positive_numeric_count_given_detection")
  results
}

staged_refit_distance_analysis_v1 <- function(
    distance_events, states, masks, species_registry, control_denominators,
    checkpoint_dir, run_signature) {
  target_names <- c(
    "Bald Eagle", "Glaucous-winged Gull", "American Robin"
  )
  results <- list()
  for (species in target_names) {
    if (species == "American Robin") {
      dat <- control_denominators[[species]]$data
      if (
        nrow(dat) != nrow(distance_events) ||
          !identical(
            as.character(dat$analysis_event_token),
            as.character(distance_events$analysis_event_token)
          )
      ) {
        stop(
          "STAGED_REFIT_DISTANCE_CONTROL_JOIN_GATE: event order mismatch",
          call. = FALSE
        )
      }
      exposure_terms <- post_stage4a_distance_band_terms_v2()
      dat[exposure_terms] <- distance_events[exposure_terms]
      if ("concurrent_links_0_26" %in% names(distance_events)) {
        dat$concurrent_links_0_26 <-
          distance_events$concurrent_links_0_26
      }
      taxon_id <- control_denominators[[species]]$taxon_id
    } else {
      taxon_id <- species_registry$analysis_taxon_id[
        match(species, species_registry$common_name)
      ]
      if (length(taxon_id) != 1L || is.na(taxon_id)) {
        stop("STAGED_REFIT_DISTANCE_TAXON_GATE: unresolved case species",
             call. = FALSE)
      }
      dat <- stage4a_materialize_taxon(
        distance_events, states, masks, taxon_id
      )
    }
    results[[species]] <- staged_refit_fit_distance_species_v1(
      dat, species, taxon_id, checkpoint_dir, run_signature
    )
  }
  effects <- do.call(rbind, unlist(lapply(
    results, function(x) lapply(x, `[[`, "effects")
  ), recursive = FALSE))
  diagnostics <- do.call(rbind, unlist(lapply(
    results, function(x) lapply(x, `[[`, "diagnostic")
  ), recursive = FALSE))
  effects$stage <- "s1_anchor"
  effects$bh_family_id <- paste(
    gsub("[^A-Za-z0-9]+", "_", tolower(effects$unit_label)),
    effects$outcome,
    effects$period,
    "13_bands",
    sep = "__"
  )
  effects$bh_family_size <- ave(
    effects$p_value,
    effects$bh_family_id,
    FUN = length
  )
  effects$p_value_bh_13 <- ave(
    effects$p_value,
    effects$bh_family_id,
    FUN = function(x) stats::p.adjust(x, method = "BH")
  )
  effects$significant_nominal_0_05 <- effects$p_value < 0.05
  effects$significant_bh_0_05 <- effects$p_value_bh_13 < 0.05
  if (any(effects$bh_family_size != 13L)) {
    stop("STAGED_REFIT_DISTANCE_BH_GATE: expected 13-member families",
         call. = FALSE)
  }
  list(effects = effects, diagnostics = diagnostics)
}

staged_refit_privacy_column_gate_v1 <- function(paths) {
  prohibited <- c(
    "analysis_event_token", "analysis_checklist_id",
    "observer_cluster_token", "location_cluster_token",
    "event_block_token", "herring_source_token",
    "latitude", "longitude", "locality", "coordinates", "source_id",
    "analysis_id"
  )
  failures <- character()
  for (path in paths) {
    if (!file.exists(path) ||
        !grepl("\\.csv$", path, ignore.case = TRUE)) next
    header <- tolower(names(utils::read.csv(
      path, nrows = 1L, check.names = FALSE
    )))
    bad <- intersect(header, prohibited)
    if (length(bad)) {
      failures <- c(failures, paste(path, bad, sep = ":"))
    }
  }
  if (length(failures)) {
    stop(
      "STAGED_REFIT_PRIVACY_COLUMN_GATE: ",
      paste(failures, collapse = "; "),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

staged_refit_parent_hash_snapshot_v1 <- function() {
  directory <- "outputs/post_stage4a_sog_event_study_v1"
  files <- list.files(directory, full.names = TRUE)
  if (!length(files)) {
    stop("STAGED_REFIT_PARENT_IMMUTABILITY_GATE: parent run unavailable",
         call. = FALSE)
  }
  hashes <- vapply(files, .post_stage4a_sha256_v1, character(1L))
  names(hashes) <- gsub("\\\\", "/", files)
  hashes
}

staged_refit_model_issues_v1 <- function(diagnostics) {
  diagnostics[
    diagnostics$status != "completed" |
      diagnostics$singular_fit %in% TRUE |
      diagnostics$converged %in% FALSE,
    c(
      "stage", "analysis_taxon_id", "species", "analysis_role", "outcome",
      "converged", "singular_fit", "rank_deficient",
      "convergence_message", "status"
    ),
    drop = FALSE
  ]
}

staged_refit_output_manifest_v1 <- function(root_dir) {
  files <- list.files(root_dir, recursive = TRUE, full.names = TRUE)
  files <- files[
    !grepl("output_hash_manifest_v1\\.csv$", files, ignore.case = TRUE)
  ]
  data.frame(
    file = gsub("\\\\", "/", files),
    sha256 = vapply(files, .post_stage4a_sha256_v1, character(1L)),
    stringsAsFactors = FALSE
  )
}

staged_refit_write_yaml_lf_v1 <- function(x, path) {
  text <- enc2utf8(yaml::as.yaml(x))
  connection <- file(path, open = "wb")
  on.exit(close(connection), add = TRUE)
  writeBin(charToRaw(text), connection)
  invisible(path)
}

run_post_stage4a_staged_refit_s1_v1 <- function(
    execution_code_commit,
    output_root = "outputs/post_stage4a_staged_refit_v1") {
  started <- Sys.time()
  packages <- c("data.table", "digest", "lme4", "yaml")
  missing <- packages[!vapply(
    packages, requireNamespace, logical(1L), quietly = TRUE
  )]
  if (length(missing)) {
    stop("Missing packages: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }
  authorization <- staged_refit_authorization_gate_v1()
  acknowledgement <-
    authorization$environment_acknowledgement$value
  if (!identical(
      Sys.getenv("POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED"),
      acknowledgement
  )) {
    stop(
      "Production requires the exact author-set staged-refit acknowledgement",
      call. = FALSE
    )
  }
  parent_hashes_before <- staged_refit_parent_hash_snapshot_v1()
  parent_primary <- staged_refit_parent_primary_v1()

  protected_files <- c(
    event_metadata =
      "data/derived/stage4a_protected/stage4a_event_metadata.tsv.gz",
    source_links_archived =
      "data/derived/stage3_phase2_protected/metadata_source_point_links.tsv.gz",
    source_links_extended = paste0(
      "data/derived/",
      "post_stage4a_distance_band_sensitivity_v2_protected/",
      "link_builder/metadata_source_point_links.tsv.gz"
    ),
    reported_states =
      "data/derived/stage4a_protected/stage4a_reported_states.tsv.gz",
    ambiguity_masks =
      "data/derived/stage4a_protected/stage4a_ambiguity_masks.tsv.gz",
    control_extract = paste0(
      "data/derived/",
      "post_stage4a_distance_band_followup_v1_protected/",
      "control_candidate_rows_pre2026.tsv"
    )
  )
  if (!all(file.exists(protected_files))) {
    stop("STAGED_REFIT_PROTECTED_INPUT_GATE: required input unavailable",
         call. = FALSE)
  }
  protected_hashes <- vapply(
    protected_files, .post_stage4a_sha256_v1, character(1L)
  )
  expected_link_hashes <- c(
    source_links_archived =
      "f26197d0a71fd177e77774ec9e5596563c127ec8eb0f948042aff51ad805567b",
    source_links_extended =
      "06a34a4d3880f2dd3a969d9976b901eff855ff7362e86ae40d75a38edd697dc2"
  )
  if (!identical(
      protected_hashes[names(expected_link_hashes)],
      expected_link_hashes
  )) {
    stop("STAGED_REFIT_SOURCE_LINK_HASH_GATE: mismatch", call. = FALSE)
  }

  herring_path <- Sys.getenv("HERRING_EBIRD_V2_HERRING", unset = "")
  anchor_lookup <- staged_refit_build_anchor_lookup_v1(herring_path)
  events_all <- .stage4a_read_gz(protected_files[["event_metadata"]])
  if (nrow(events_all) != 239934L ||
      any(as.integer(events_all$checklist_year) > 2025L)) {
    stop("STAGED_REFIT_EVENT_YEAR_CARDINALITY_GATE: failed",
         call. = FALSE)
  }
  events_all <- .stage4a_prepare_events(events_all)
  selected <- events_all$region == "SoG" &
    events_all$checklist_year >= 2005L &
    events_all$checklist_year <= 2025L
  if (anyNA(selected) || sum(selected) != 217200L) {
    stop("STAGED_REFIT_SOG_POPULATION_GATE: expected 217200 checklists",
         call. = FALSE)
  }
  events <- events_all[selected, , drop = FALSE]
  rm(events_all)
  if (!all(stage4a_effort_eligible(
      events$protocol, events$duration_minutes,
      events$effort_distance_km, events$observer_count
  ))) {
    stop("STAGED_REFIT_EFFORT_GATE: ineligible checklist", call. = FALSE)
  }
  stage4a_validate_folds(events)

  links_archived <- .stage4a_read_gz(
    protected_files[["source_links_archived"]]
  )
  extended_links <- .stage4a_read_gz(
    protected_files[["source_links_extended"]]
  )
  selected_parent_links <- links_archived[
    links_archived$analysis_event_token %in% events$analysis_event_token,
    ,
    drop = FALSE
  ]
  anchored_links <- staged_refit_reanchor_links_v1(
    links_archived, anchor_lookup
  )
  selected_anchored_links <- anchored_links[
    anchored_links$analysis_event_token %in% events$analysis_event_token,
    ,
    drop = FALSE
  ]
  extended_anchored_links <- staged_refit_reanchor_links_v1(
    extended_links, anchor_lookup
  )
  selected_extended_anchored_links <- extended_anchored_links[
    extended_anchored_links$analysis_event_token %in%
      events$analysis_event_token,
    ,
    drop = FALSE
  ]
  audit <- staged_refit_anchor_audit_v1(
    events, selected_parent_links, selected_anchored_links, anchor_lookup,
    distribution_links = selected_extended_anchored_links
  )
  joint <- post_stage4a_add_joint_exposure_v1(events, anchored_links)
  events_s1 <- joint$events
  rm(joint)
  if (nrow(events_s1) != nrow(events) ||
      anyDuplicated(events_s1$analysis_event_token)) {
    stop("STAGED_REFIT_MODEL_ROW_CARDINALITY_GATE: failed", call. = FALSE)
  }

  states_all <- .stage4a_read_gz(protected_files[["reported_states"]])
  masks_all <- .stage4a_read_gz(protected_files[["ambiguity_masks"]])
  if (nrow(states_all) != 1169612L || nrow(masks_all) != 5834L) {
    stop("STAGED_REFIT_SPARSE_STATE_CARDINALITY_GATE: changed",
         call. = FALSE)
  }
  tokens <- events_s1$analysis_event_token
  states <- states_all[
    states_all$analysis_event_token %in% tokens, , drop = FALSE
  ]
  masks <- masks_all[
    masks_all$analysis_event_token %in% tokens, , drop = FALSE
  ]
  rm(states_all, masks_all)

  support_registry <- utils::read.csv(
    "outputs/stage2_design_lock/species_support_summary.csv",
    stringsAsFactors = FALSE
  )
  species_registry <- utils::read.csv(
    "metadata/canonical_species_registry.csv",
    stringsAsFactors = FALSE
  )
  if (anyDuplicated(species_registry$analysis_taxon_id)) {
    stop("STAGED_REFIT_SPECIES_REGISTRY_GATE: duplicate taxon",
         call. = FALSE)
  }
  core_taxa <- support_registry$analysis_taxon_id[
    support_registry$named_species_recommendation == "named_species_core"
  ]
  if (length(core_taxa) != 49L || anyDuplicated(core_taxa)) {
    stop("STAGED_REFIT_SPECIES_FAMILY_GATE: expected fixed 49 species",
         call. = FALSE)
  }
  case_core <- species_registry$analysis_taxon_id[
    species_registry$common_name %in%
      c("Bald Eagle", "Glaucous-winged Gull")
  ]
  if (length(case_core) != 2L || !all(case_core %in% core_taxa)) {
    stop("STAGED_REFIT_PRIORITY_TAXON_GATE: case species unresolved",
         call. = FALSE)
  }
  controls <- staged_refit_load_control_denominators_v1(
    events_s1, protected_files[["control_extract"]]
  )

  protected_dir <- file.path(
    "data", "derived", "post_stage4a_staged_refit_v1", "s1_anchor"
  )
  core_checkpoint_dir <- file.path(protected_dir, "core_checkpoints")
  control_checkpoint_dir <- file.path(protected_dir, "control_checkpoints")
  distance_checkpoint_dir <- file.path(
    protected_dir, "distance_checkpoints"
  )
  for (path in c(
      core_checkpoint_dir, control_checkpoint_dir, distance_checkpoint_dir
  )) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
  output_dir <- file.path(output_root, "s1_anchor")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  code_signature <- paste(
    execution_code_commit,
    .post_stage4a_sha256_v1("R/post_stage4a_staged_refit_v1.R"),
    .post_stage4a_sha256_v1(
      "metadata/post_stage4a_staged_refit_spec_v1.yml"
    ),
    protected_hashes,
    attr(anchor_lookup, "source_hash"),
    sep = "|",
    collapse = "|"
  )
  workers <- post_stage4a_worker_count_v1(length(core_taxa))

  priority_started <- Sys.time()
  priority_core <- staged_refit_parallel_core_v1(
    case_core, events_s1, states, masks, species_registry,
    core_checkpoint_dir, code_signature, workers
  )
  names(priority_core) <- case_core
  priority_controls <- staged_refit_fit_controls_v1(
    controls, control_checkpoint_dir, code_signature
  )
  priority_elapsed <- as.numeric(
    difftime(Sys.time(), priority_started, units = "secs")
  )
  remaining_taxa <- setdiff(core_taxa, case_core)
  full_started <- Sys.time()
  remaining_core <- staged_refit_parallel_core_v1(
    remaining_taxa, events_s1, states, masks, species_registry,
    core_checkpoint_dir, code_signature, workers
  )
  names(remaining_core) <- remaining_taxa
  full_elapsed <- as.numeric(
    difftime(Sys.time(), full_started, units = "secs")
  )
  core_results <- c(priority_core, remaining_core)
  core_results <- core_results[core_taxa]
  core_contrasts <- staged_refit_adjust_bh_v1(
    staged_refit_flatten_models_v1(core_results, "contrasts"),
    "fixed_49_species"
  )
  core_diagnostics <- staged_refit_flatten_models_v1(
    core_results, "diagnostic"
  )
  if (nrow(core_diagnostics) != 98L) {
    stop("STAGED_REFIT_MODEL_COMPONENT_GATE: expected 98 core models",
         call. = FALSE)
  }
  primary <- core_contrasts[
    core_contrasts$comparison == "active_minus_pre14",
    ,
    drop = FALSE
  ]
  if (nrow(primary) != 98L ||
      anyDuplicated(paste(
        primary$analysis_taxon_id, primary$outcome, sep = "\r"
      ))) {
    stop("STAGED_REFIT_PRIMARY_CONTRAST_GATE: expected 49 x 2",
         call. = FALSE)
  }
  control_contrasts <- staged_refit_adjust_bh_v1(
    staged_refit_flatten_models_v1(priority_controls, "contrasts"),
    "negative_controls_2_species"
  )
  control_diagnostics <- staged_refit_flatten_models_v1(
    priority_controls, "diagnostic"
  )
  delta <- staged_refit_delta_vs_parent_v1(primary, parent_primary)
  guild_timing <- staged_refit_augment_guild_parent_v1(
    staged_refit_guild_timing_v1(core_contrasts, species_registry)
  )

  distance_links <- staged_refit_distance_links_v1(
    links_archived, extended_links, anchor_lookup
  )
  distance_joint <- post_stage4a_add_distance_band_exposure_v2(
    events, distance_links
  )
  distance_results <- staged_refit_distance_analysis_v1(
    distance_joint$events,
    states,
    masks,
    species_registry,
    controls,
    distance_checkpoint_dir,
    code_signature
  )

  .post_stage4a_write_csv_v1(
    audit$anchor_audit,
    file.path(output_dir, "anchor_shift_audit.csv")
  )
  .post_stage4a_write_csv_v1(
    audit$migration,
    file.path(output_dir, "link_period_migration.csv")
  )
  .post_stage4a_write_csv_v1(
    primary,
    file.path(output_dir, "estimates_49x2.csv")
  )
  .post_stage4a_write_csv_v1(
    delta,
    file.path(output_dir, "delta_vs_parent.csv")
  )
  .post_stage4a_write_csv_v1(
    guild_timing,
    file.path(output_dir, "guild_timing.csv")
  )
  .post_stage4a_write_csv_v1(
    distance_results$effects,
    file.path(output_dir, "distance_bands_3species.csv")
  )
  .post_stage4a_write_csv_v1(
    control_contrasts,
    file.path(output_root, "negative_controls_all_stages.csv")
  )

  output_paths <- c(
    file.path(output_dir, c(
      "anchor_shift_audit.csv", "link_period_migration.csv",
      "estimates_49x2.csv", "delta_vs_parent.csv", "guild_timing.csv",
      "distance_bands_3species.csv"
    )),
    file.path(output_root, "negative_controls_all_stages.csv")
  )
  staged_refit_privacy_column_gate_v1(output_paths)

  parent_hashes_after <- staged_refit_parent_hash_snapshot_v1()
  if (!identical(parent_hashes_before, parent_hashes_after)) {
    stop("STAGED_REFIT_PARENT_IMMUTABILITY_GATE: parent run changed",
         call. = FALSE)
  }
  model_issues <- staged_refit_model_issues_v1(rbind(
    core_diagnostics, control_diagnostics
  ))
  distance_issues <- distance_results$diagnostics[
    distance_results$diagnostics$status != "completed" |
      distance_results$diagnostics$singular_fit %in% TRUE |
      distance_results$diagnostics$converged %in% FALSE,
    ,
    drop = FALSE
  ]
  headline <- do.call(rbind, lapply(
    unique(primary$outcome),
    function(outcome_now) {
      x <- primary[primary$outcome == outcome_now, , drop = FALSE]
      data.frame(
        outcome = outcome_now,
        positive_bh_q_lt_0_05 = sum(
          x$estimate > 0 & x$q_value < 0.05, na.rm = TRUE
        ),
        negative_bh_q_lt_0_05 = sum(
          x$estimate < 0 & x$q_value < 0.05, na.rm = TRUE
        ),
        estimable = sum(
          is.finite(x$estimate) & is.finite(x$standard_error)
        ),
        stringsAsFactors = FALSE
      )
    }
  ))
  execution <- list(
    execution_version = "post_stage4a_staged_refit_execution_v1",
    completed_stages = list("s1_anchor"),
    analysis_status = "post_result_ecologically_motivated_refinement",
    authorization_record =
      "metadata/post_stage4a_staged_refit_authorization_v1.yml",
    execution_code_commit = execution_code_commit,
    executed_at_utc = format(
      as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"
    ),
    elapsed_seconds = as.numeric(
      difftime(Sys.time(), started, units = "secs")
    ),
    stage_timings_seconds = list(
      priority_case_species_and_controls = priority_elapsed,
      remaining_fixed_family = full_elapsed
    ),
    random_seed = "none_models_are_deterministic",
    engines = list(
      checklist_reporting = "lme4::glmer binomial nAGQ=0",
      conditional_positive_numeric_count = "lme4::lmer REML"
    ),
    r_version = R.version.string,
    package_versions = as.list(vapply(
      packages, function(x) as.character(utils::packageVersion(x)),
      character(1L)
    )),
    workers = workers,
    population = list(
      region = "SoG",
      years = c(2005L, 2025L),
      eligible_checklists = nrow(events_s1),
      fixed_family_species = length(core_taxa),
      negative_controls = names(controls),
      records_2026_plus_read = 0L
    ),
    joins = list(
      source_links_to_anchor_lookup =
        "many_to_one_PASS_no_link_row_change",
      source_links_to_checklists =
        "many_to_one_then_aggregate_to_one_checklist_PASS",
      control_ebd_reports_to_source_crosswalk =
        "many_to_one_PASS_no_join_expansion",
      stage1_to_published_parent =
        "one_to_one_98_rows_PASS",
      species_to_guild = "many_species_to_one_guild_PASS",
      archived_to_extended_distance_links =
        "one_to_one_archived_subset_PASS"
    ),
    headline_primary_contrast = lapply(
      seq_len(nrow(headline)),
      function(i) as.list(headline[i, , drop = FALSE])
    ),
    model_issues = lapply(
      seq_len(nrow(model_issues)),
      function(i) as.list(model_issues[i, , drop = FALSE])
    ),
    distance_model_issues = lapply(
      seq_len(nrow(distance_issues)),
      function(i) as.list(distance_issues[i, , drop = FALSE])
    ),
    protected_input_hashes = as.list(protected_hashes),
    herring_source_hash = attr(anchor_lookup, "source_hash"),
    published_parent_contrast_source =
      attr(parent_primary, "source_path"),
    published_parent_contrast_hash =
      attr(parent_primary, "source_hash"),
    historical_parent_output_hashes = as.list(parent_hashes_after),
    historical_parent_outputs_modified = FALSE,
    protected_rows_released = 0L,
    privacy_column_gate = "PASS",
    stage1_gate = "PASS_PENDING_HUMAN_STAGE1_REVIEW"
  )
  staged_refit_write_yaml_lf_v1(
    execution, file.path(output_root, "execution_record_v1.yml")
  )
  manifest <- staged_refit_output_manifest_v1(output_root)
  .post_stage4a_write_csv_v1(
    manifest, file.path(output_root, "output_hash_manifest_v1.csv")
  )
  message("POST_STAGE4A_STAGED_REFIT_S1_GATE=PASS_PENDING_HUMAN_STAGE1_REVIEW")
  invisible(list(
    primary = primary,
    delta = delta,
    guild_timing = guild_timing,
    controls = control_contrasts,
    distance = distance_results$effects,
    audit = audit
  ))
}
