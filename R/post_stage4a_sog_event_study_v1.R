post_stage4a_period_spec_v1 <- function() {
  data.frame(
    period = c("baseline", "early_pre", "immediate_pre", "spawn_start",
               "early_egg", "late_egg"),
    minimum_day = c(-28L, -14L, -7L, 0L, 4L, 15L),
    maximum_day = c(-15L, -8L, -1L, 3L, 14L, 28L),
    duration_days = c(14L, 7L, 7L, 4L, 11L, 14L),
    stringsAsFactors = FALSE
  )
}

post_stage4a_exposure_terms_v1 <- function() {
  periods <- post_stage4a_period_spec_v1()$period
  as.vector(outer(c("near", "reference"), periods,
                  function(zone, period) paste("es", zone, period, sep = "_")))
}

.post_stage4a_release_count_v1 <- function(x, threshold = 20L) {
  ifelse(is.finite(x) & x > 0 & x < threshold, NA_real_, x)
}

.post_stage4a_require_fields_v1 <- function(x, required, label) {
  missing <- setdiff(required, names(x))
  if (length(missing)) {
    stop(label, " is missing required fields: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }
  invisible(TRUE)
}

post_stage4a_classify_links_v1 <- function(links) {
  .post_stage4a_require_fields_v1(
    links,
    c("analysis_event_token", "event_day", "distance_km"),
    "event-study link table"
  )
  event_day <- suppressWarnings(as.integer(links$event_day))
  distance_km <- suppressWarnings(as.numeric(links$distance_km))
  if (anyNA(event_day) || anyNA(distance_km) ||
      any(distance_km < 0 | distance_km > 20.0001)) {
    stop("POST_STAGE4A_EVENT_STUDY_LINK_RANGE_GATE: invalid day or distance",
         call. = FALSE)
  }
  period <- rep(NA_character_, length(event_day))
  spec <- post_stage4a_period_spec_v1()
  for (i in seq_len(nrow(spec))) {
    use <- event_day >= spec$minimum_day[[i]] &
      event_day <= spec$maximum_day[[i]]
    period[use] <- spec$period[[i]]
  }
  zone <- ifelse(distance_km < 5, "near", "reference")
  term <- ifelse(
    is.na(period), NA_character_,
    paste("es", zone, period, sep = "_")
  )
  data.frame(
    analysis_event_token = as.character(links$analysis_event_token),
    period = period,
    zone = zone,
    term = term,
    stringsAsFactors = FALSE
  )
}

post_stage4a_add_joint_exposure_v1 <- function(events, links) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("data.table is required for joint exposure construction", call. = FALSE)
  }
  event_required <- c(
    "analysis_event_token", "event_block_token", "region", "checklist_year",
    "concurrent_links"
  )
  link_required <- c(
    "analysis_event_token", "region", "checklist_year", "event_day",
    "distance_km"
  )
  .post_stage4a_require_fields_v1(events, event_required, "event metadata")
  .post_stage4a_require_fields_v1(links, link_required, "source-point links")
  if (anyDuplicated(events$analysis_event_token)) {
    stop("POST_STAGE4A_EVENT_STUDY_EVENT_CARDINALITY_GATE: duplicate event token",
         call. = FALSE)
  }

  event_tokens <- as.character(events$analysis_event_token)
  selected_links <- links[as.character(links$analysis_event_token) %in% event_tokens,
                          link_required, drop = FALSE]
  link_match <- match(selected_links$analysis_event_token, event_tokens)
  if (anyNA(link_match)) {
    stop("POST_STAGE4A_EVENT_STUDY_LINK_JOIN_GATE: unmatched selected link",
         call. = FALSE)
  }
  if (!all(as.integer(selected_links$checklist_year) ==
           as.integer(events$checklist_year[link_match]))) {
    stop("POST_STAGE4A_EVENT_STUDY_LINK_JOIN_GATE: checklist year disagreement",
         call. = FALSE)
  }

  link_counts <- table(selected_links$analysis_event_token)
  observed_link_counts <- as.integer(link_counts[event_tokens])
  observed_link_counts[is.na(observed_link_counts)] <- 0L
  expected_link_counts <- as.integer(events$concurrent_links)
  if (!identical(observed_link_counts, expected_link_counts)) {
    stop("POST_STAGE4A_EVENT_STUDY_LINK_CARDINALITY_GATE: concurrent-link totals changed",
         call. = FALSE)
  }

  classified <- post_stage4a_classify_links_v1(selected_links)
  classified <- classified[!is.na(classified$term), , drop = FALSE]
  terms <- post_stage4a_exposure_terms_v1()
  if (!all(classified$term %in% terms)) {
    stop("POST_STAGE4A_EVENT_STUDY_TERM_GATE: unregistered joint term",
         call. = FALSE)
  }

  counts <- data.table::as.data.table(classified)[
    , .(exposure_links = .N),
    by = .(analysis_event_token, term)
  ]
  wide <- data.table::dcast(
    counts,
    analysis_event_token ~ term,
    value.var = "exposure_links",
    fill = 0L
  )
  event_dt <- data.table::as.data.table(data.table::copy(events))
  event_dt[, event_study_row_order__ := .I]
  joined <- merge(
    event_dt, wide,
    by = "analysis_event_token",
    all.x = TRUE,
    sort = FALSE
  )
  data.table::setorder(joined, event_study_row_order__)
  joined[, event_study_row_order__ := NULL]
  if (nrow(joined) != nrow(events) ||
      anyDuplicated(joined$analysis_event_token)) {
    stop("POST_STAGE4A_EVENT_STUDY_AGGREGATION_GATE: model-row cardinality changed",
         call. = FALSE)
  }
  for (term in terms) {
    if (!term %in% names(joined)) joined[, (term) := 0L]
    data.table::set(
      joined,
      which(is.na(joined[[term]])),
      term,
      0L
    )
    joined[, (term) := as.integer(get(term))]
  }

  target_links <- rowSums(as.data.frame(joined[, ..terms]))
  if (any(target_links > joined$concurrent_links)) {
    stop("POST_STAGE4A_EVENT_STUDY_JOINT_EXPOSURE_GATE: joint totals exceed links",
         call. = FALSE)
  }

  support <- do.call(rbind, lapply(terms, function(term) {
    pieces <- strsplit(sub("^es_", "", term), "_", fixed = TRUE)[[1L]]
    zone <- pieces[[1L]]
    period <- paste(pieces[-1L], collapse = "_")
    use <- joined[[term]] > 0L
    data.frame(
      term = term,
      zone = zone,
      period = period,
      exposed_checklists = .post_stage4a_release_count_v1(sum(use)),
      exposure_links = .post_stage4a_release_count_v1(sum(joined[[term]])),
      event_blocks = .post_stage4a_release_count_v1(
        length(unique(joined$event_block_token[use]))
      ),
      checklist_years = .post_stage4a_release_count_v1(
        length(unique(joined$checklist_year[use]))
      ),
      stringsAsFactors = FALSE
    )
  }))
  list(events = as.data.frame(joined), support = support)
}

post_stage4a_formula_v1 <- function(response) {
  fixed <- c(
    post_stage4a_exposure_terms_v1(),
    "factor(checklist_year)", "protocol", "log_duration",
    "log_effort_distance", "observer_count"
  )
  stats::as.formula(paste(
    response, "~", paste(fixed, collapse = " + "),
    "+ (1 | event_block_token) + (1 | observer_cluster_token) +",
    "(1 | location_cluster_token)"
  ))
}

.post_stage4a_model_messages_v1 <- function(
    optimizer_code, engine_messages, singular_fit) {
  messages <- if (is.null(engine_messages)) character() else
    as.character(engine_messages)
  singular_notice <- grepl("boundary (singular) fit", messages, fixed = TRUE)
  blocking <- messages[!(singular_fit & singular_notice)]
  optimizer_pass <- is.null(optimizer_code) || all(optimizer_code == 0L)
  text <- if (!length(messages)) "" else {
    substr(gsub("[\r\n]+", " ", paste(messages, collapse = "; ")), 1L, 240L)
  }
  if (!optimizer_pass && !nzchar(text)) {
    text <- paste0("optimizer_code_", paste(optimizer_code, collapse = "_"))
  }
  list(converged = optimizer_pass && !length(blocking), message = text)
}

.post_stage4a_contrast_vector_v1 <- function(coefficient_names, weights) {
  vector <- stats::setNames(rep(0, length(coefficient_names)), coefficient_names)
  if (!all(names(weights) %in% coefficient_names)) return(NULL)
  vector[names(weights)] <- as.numeric(weights)
  vector
}

post_stage4a_contrast_definitions_v1 <- function(coefficient_names) {
  term <- function(zone, period) paste("es", zone, period, sep = "_")
  spatial <- function(period) {
    stats::setNames(c(1, -1), c(term("near", period),
                                term("reference", period)))
  }
  did <- function(period) {
    stats::setNames(
      c(1, -1, -1, 1),
      c(term("near", period), term("reference", period),
        term("near", "baseline"), term("reference", "baseline"))
    )
  }
  combine <- function(...) {
    pieces <- list(...)
    result <- numeric()
    for (piece in pieces) {
      for (name in names(piece)) {
        result[[name]] <- if (name %in% names(result)) result[[name]] +
          piece[[name]] else piece[[name]]
      }
    }
    result
  }
  scale_weights <- function(x, scale) x * scale

  periods <- post_stage4a_period_spec_v1()$period
  rows <- lapply(periods, function(period) {
    list(
      contrast = paste0("near_minus_reference_", period),
      contrast_type = "near_minus_reference",
      ecological_period = period,
      primary_estimand = FALSE,
      weights = spatial(period)
    )
  })
  nonbaseline <- setdiff(periods, "baseline")
  rows <- c(rows, lapply(nonbaseline, function(period) {
    list(
      contrast = paste0("did_", period),
      contrast_type = "difference_in_differences",
      ecological_period = period,
      primary_estimand = FALSE,
      weights = did(period)
    )
  }))
  rows[[length(rows) + 1L]] <- list(
    contrast = "did_pre_14_day",
    contrast_type = "duration_weighted_difference_in_differences",
    ecological_period = "pre_14_day",
    primary_estimand = FALSE,
    weights = combine(
      scale_weights(did("early_pre"), 0.5),
      scale_weights(did("immediate_pre"), 0.5)
    )
  )
  rows[[length(rows) + 1L]] <- list(
    contrast = "did_pre_7_day",
    contrast_type = "difference_in_differences",
    ecological_period = "pre_7_day",
    primary_estimand = FALSE,
    weights = did("immediate_pre")
  )
  rows[[length(rows) + 1L]] <- list(
    contrast = "did_active_0_14_day",
    contrast_type = "duration_weighted_difference_in_differences",
    ecological_period = "active_0_14_day",
    primary_estimand = TRUE,
    weights = combine(
      scale_weights(did("spawn_start"), 4 / 15),
      scale_weights(did("early_egg"), 11 / 15)
    )
  )
  rows[[length(rows) + 1L]] <- list(
    contrast = "active_minus_pre_14_day",
    contrast_type = "duration_weighted_difference_in_differences",
    ecological_period = "active_minus_pre_14_day",
    primary_estimand = TRUE,
    weights = combine(
      scale_weights(did("spawn_start"), 4 / 15),
      scale_weights(did("early_egg"), 11 / 15),
      scale_weights(did("early_pre"), -0.5),
      scale_weights(did("immediate_pre"), -0.5)
    )
  )
  active_minus_pre_weights <- rows[[length(rows)]]$weights
  if (!(abs(active_minus_pre_weights[["es_near_baseline"]]) < 1e-12 &&
        abs(active_minus_pre_weights[["es_reference_baseline"]]) < 1e-12)) {
    stop(
      "POST_STAGE4A_EVENT_STUDY_CONTRAST_WEIGHT_GATE: ",
      "active_minus_pre_14_day must carry zero weight on both baseline terms",
      call. = FALSE
    )
  }
  for (i in seq_along(rows)) {
    rows[[i]]$vector <- .post_stage4a_contrast_vector_v1(
      coefficient_names, rows[[i]]$weights
    )
  }
  rows
}

.post_stage4a_model_summary_path_v1 <- function(dir, taxon_id, outcome) {
  file.path(dir, paste(taxon_id, outcome, "model_summary_v1.rds", sep = "_"))
}

.post_stage4a_write_model_summary_v1 <- function(
    dir, taxon_id, unit_label, analysis_role, outcome, status,
    beta = NULL, covariance = NULL, gradient = NULL) {
  if (is.null(dir)) return(invisible(NULL))
  summary_object <- list(
    model_version_id = "SOG_EVENT_STUDY_v1",
    analysis_taxon_id = taxon_id,
    unit_label = unit_label,
    analysis_role = analysis_role,
    region = "SoG",
    outcome = outcome,
    status = status,
    fixed_effects = beta,
    covariance = covariance,
    gradient_check = gradient
  )
  saveRDS(
    summary_object,
    .post_stage4a_model_summary_path_v1(dir, taxon_id, outcome)
  )
  invisible(NULL)
}

.post_stage4a_gradient_check_v1 <- function(fit, devfun_factory) {
  unavailable <- function(note) {
    list(max_abs_gradient = NA_real_, gradient_check_status = note,
         devfun_reference_deviation = NA_real_)
  }
  if (!identical(
    Sys.getenv("POST_STAGE4A_EVENT_STUDY_GRADIENT_CHECK", unset = "1"), "1"
  )) {
    return(unavailable("gradient_check_disabled"))
  }
  if (!requireNamespace("numDeriv", quietly = TRUE)) {
    return(unavailable("numDeriv_unavailable"))
  }
  devfun <- try(devfun_factory(), silent = TRUE)
  if (inherits(devfun, "try-error") || !is.function(devfun)) {
    return(unavailable("devfun_unavailable"))
  }
  ## The optimised criterion, on the same scale the deviance function
  ## returns. Note stats::deviance() is NOT this quantity for a glmer fit
  ## (it returns the sum of squared deviance residuals instead), so using it
  ## here would spuriously fail every binomial component.
  reference <- try(-2 * as.numeric(stats::logLik(fit)), silent = TRUE)
  if (inherits(reference, "try-error") || length(reference) != 1L ||
      !is.finite(reference)) {
    return(unavailable("reference_criterion_unavailable"))
  }
  theta <- as.numeric(lme4::getME(fit, "theta"))
  beta <- as.numeric(lme4::fixef(fit))
  ## lmer, and glmer at nAGQ = 0, profile the fixed effects out of the
  ## deviance function, so it takes theta alone. glmer at nAGQ >= 1 takes
  ## c(theta, beta). Choose deterministically rather than by trial, so a
  ## wrong-length call never reaches lme4.
  nAGQ <- tryCatch(as.integer(fit@devcomp$dims[["nAGQ"]]), error = function(e) NA_integer_)
  profiled <- lme4::isREML(fit) || is.na(nAGQ) || nAGQ < 1L
  candidates <- if (profiled) {
    list(theta = theta, theta_beta = c(theta, beta))
  } else {
    list(theta_beta = c(theta, beta), theta = theta)
  }
  best_name <- NA_character_
  best_pars <- NULL
  best_deviation <- Inf
  for (name in names(candidates)) {
    value <- try(
      suppressMessages(suppressWarnings(devfun(candidates[[name]]))),
      silent = TRUE
    )
    if (inherits(value, "try-error") || length(value) != 1L ||
        !is.finite(value)) {
      next
    }
    deviation <- abs(value - reference) / max(1, abs(reference))
    if (deviation < best_deviation) {
      best_deviation <- deviation
      best_pars <- candidates[[name]]
      best_name <- name
    }
    if (best_deviation <= 1e-6) break
  }
  if (is.null(best_pars)) return(unavailable("devfun_not_evaluable"))
  if (best_deviation > 1e-6) {
    result <- unavailable("devfun_reference_mismatch")
    result$devfun_reference_deviation <- best_deviation
    return(result)
  }
  gradient <- try(
    numDeriv::grad(devfun, best_pars, method = "Richardson"),
    silent = TRUE
  )
  if (inherits(gradient, "try-error") || !all(is.finite(gradient))) {
    return(unavailable("gradient_not_computable"))
  }
  list(
    max_abs_gradient = max(abs(gradient)),
    gradient_check_status = paste0("computed_", best_name),
    devfun_reference_deviation = best_deviation
  )
}

.post_stage4a_empty_fit_v1 <- function(
    taxon_id, unit_label, analysis_role, outcome, n, status) {
  definitions <- post_stage4a_contrast_definitions_v1(
    c("(Intercept)", post_stage4a_exposure_terms_v1())
  )
  effect <- do.call(rbind, lapply(definitions, function(definition) {
    data.frame(
      model_version_id = "SOG_EVENT_STUDY_v1",
      analysis_taxon_id = taxon_id,
      unit_label = unit_label,
      analysis_role = analysis_role,
      region = "SoG",
      outcome = outcome,
      contrast = definition$contrast,
      contrast_type = definition$contrast_type,
      ecological_period = definition$ecological_period,
      primary_estimand = definition$primary_estimand,
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
      status = status,
      stringsAsFactors = FALSE
    )
  }))
  diagnostic <- data.frame(
    model_version_id = "SOG_EVENT_STUDY_v1",
    analysis_taxon_id = taxon_id,
    unit_label = unit_label,
    analysis_role = analysis_role,
    region = "SoG",
    outcome = outcome,
    converged = FALSE,
    singular_fit = NA,
    rank_deficient = NA,
    convergence_message = status,
    max_abs_gradient = NA_real_,
    gradient_check_status = "not_fitted",
    devfun_reference_deviation = NA_real_,
    n = .post_stage4a_release_count_v1(n),
    status = status,
    stringsAsFactors = FALSE
  )
  list(effect = effect, diagnostic = diagnostic, term_support = data.frame())
}

post_stage4a_fit_one_v1 <- function(
    dat, taxon_id, unit_label, analysis_role, outcome,
    checkpoint_path, cache_signature, model_summary_dir = NULL,
    nAGQ = 0L) {
  nAGQ <- as.integer(nAGQ)
  if (length(nAGQ) != 1L || is.na(nAGQ) || nAGQ < 0L) {
    stop("POST_STAGE4A_EVENT_STUDY_NAGQ_GATE: nAGQ must be a non-negative integer",
         call. = FALSE)
  }
  if (nAGQ > 1L) {
    ## lme4 supports adaptive Gauss-Hermite quadrature only for a single
    ## scalar random effect; this model carries three crossed random
    ## intercepts, so Laplace (nAGQ = 1) is the highest available order.
    stop("POST_STAGE4A_EVENT_STUDY_NAGQ_GATE: nAGQ > 1 is unavailable for ",
         "three crossed random intercepts", call. = FALSE)
  }
  summary_ready <- is.null(model_summary_dir) || file.exists(
    .post_stage4a_model_summary_path_v1(model_summary_dir, taxon_id, outcome)
  )
  if (file.exists(checkpoint_path) && summary_ready) {
    cached <- readRDS(checkpoint_path)
    if (identical(cached$cache_signature, cache_signature)) return(cached$result)
  }
  if (outcome == "detection") {
    use <- !is.na(dat$detection)
    response <- "detection"
  } else if (outcome == "positive_numeric_count_given_detection") {
    use <- is.finite(dat$numeric_count) & dat$numeric_count > 0
    response <- "log_count"
  } else {
    stop("POST_STAGE4A_EVENT_STUDY_OUTCOME_GATE: unsupported outcome",
         call. = FALSE)
  }
  d <- dat[use, , drop = FALSE]
  if (outcome == "positive_numeric_count_given_detection") {
    d$log_count <- log(d$numeric_count)
  }
  terms <- post_stage4a_exposure_terms_v1()
  term_support <- data.frame(
    model_version_id = "SOG_EVENT_STUDY_v1",
    analysis_taxon_id = taxon_id,
    unit_label = unit_label,
    analysis_role = analysis_role,
    region = "SoG",
    outcome = outcome,
    term = terms,
    exposed_model_rows = vapply(
      terms, function(term) sum(d[[term]] > 0L), integer(1L)
    ),
    stringsAsFactors = FALSE
  )
  term_support$exposed_model_rows <- .post_stage4a_release_count_v1(
    term_support$exposed_model_rows
  )
  insufficient_terms <- is.na(term_support$exposed_model_rows) |
    term_support$exposed_model_rows < 20L
  response_values <- if (response %in% names(d)) d[[response]] else numeric()
  if (nrow(d) < 20L || length(unique(response_values)) < 2L ||
      any(insufficient_terms)) {
    result <- .post_stage4a_empty_fit_v1(
      taxon_id, unit_label, analysis_role, outcome, nrow(d),
      "failed_insufficient_support"
    )
    result$term_support <- term_support
    .post_stage4a_write_model_summary_v1(
      model_summary_dir, taxon_id, unit_label, analysis_role, outcome,
      "failed_insufficient_support"
    )
    saveRDS(list(cache_signature = cache_signature, result = result),
            checkpoint_path)
    return(result)
  }

  formula <- post_stage4a_formula_v1(response)
  fit <- try(
    if (outcome == "detection") {
      lme4::glmer(
        formula, data = d, family = stats::binomial(), nAGQ = nAGQ,
        control = lme4::glmerControl(
          optimizer = "nloptwrap",
          calc.derivs = FALSE,
          optCtrl = list(maxeval = 10000L)
        )
      )
    } else {
      lme4::lmer(
        formula, data = d, REML = TRUE,
        control = lme4::lmerControl(
          optimizer = "nloptwrap",
          calc.derivs = FALSE,
          optCtrl = list(maxeval = 10000L)
        )
      )
    },
    silent = TRUE
  )
  if (inherits(fit, "try-error")) {
    result <- .post_stage4a_empty_fit_v1(
      taxon_id, unit_label, analysis_role, outcome, nrow(d),
      "failed_numerical_fit_no_fallback"
    )
    result$term_support <- term_support
    .post_stage4a_write_model_summary_v1(
      model_summary_dir, taxon_id, unit_label, analysis_role, outcome,
      "failed_numerical_fit_no_fallback"
    )
    saveRDS(list(cache_signature = cache_signature, result = result),
            checkpoint_path)
    return(result)
  }

  beta <- lme4::fixef(fit)
  covariance <- as.matrix(stats::vcov(fit))
  gradient_check <- .post_stage4a_gradient_check_v1(
    fit,
    function() {
      if (outcome == "detection") {
        lme4::glmer(
          formula, data = d, family = stats::binomial(), nAGQ = nAGQ,
          control = lme4::glmerControl(
            optimizer = "nloptwrap",
            calc.derivs = FALSE,
            optCtrl = list(maxeval = 10000L)
          ),
          devFunOnly = TRUE
        )
      } else {
        lme4::lmer(
          formula, data = d, REML = TRUE,
          control = lme4::lmerControl(
            optimizer = "nloptwrap",
            calc.derivs = FALSE,
            optCtrl = list(maxeval = 10000L)
          ),
          devFunOnly = TRUE
        )
      }
    }
  )
  singular_fit <- lme4::isSingular(fit, tol = 1e-4)
  classification <- .post_stage4a_model_messages_v1(
    fit@optinfo$conv$opt,
    fit@optinfo$conv$lme4$messages,
    singular_fit
  )
  rank_deficient <- length(beta) <
    ncol(stats::model.matrix(lme4::nobars(formula), d))
  model_status <- if (!classification$converged) {
    "failed_convergence"
  } else if (singular_fit) {
    "completed_with_singular_warning"
  } else if (rank_deficient) {
    "completed_with_rank_deficiency_warning"
  } else {
    "completed"
  }

  definitions <- post_stage4a_contrast_definitions_v1(names(beta))
  effects <- do.call(rbind, lapply(definitions, function(definition) {
    vector <- definition$vector
    if (is.null(vector)) {
      estimate <- standard_error <- p_value <- NA_real_
      status <- "failed_contrast_geometry"
    } else {
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
      status <- if (is.finite(estimate) && is.finite(standard_error) &&
                    standard_error > 0) model_status else
        "failed_contrast_geometry"
    }
    conf_low <- estimate - 1.959963984540054 * standard_error
    conf_high <- estimate + 1.959963984540054 * standard_error
    data.frame(
      model_version_id = "SOG_EVENT_STUDY_v1",
      analysis_taxon_id = taxon_id,
      unit_label = unit_label,
      analysis_role = analysis_role,
      region = "SoG",
      outcome = outcome,
      contrast = definition$contrast,
      contrast_type = definition$contrast_type,
      ecological_period = definition$ecological_period,
      primary_estimand = definition$primary_estimand,
      estimate = estimate,
      standard_error = standard_error,
      conf_low = conf_low,
      conf_high = conf_high,
      ratio = exp(estimate),
      ratio_conf_low = exp(conf_low),
      ratio_conf_high = exp(conf_high),
      p_value = p_value,
      q_value = NA_real_,
      n = .post_stage4a_release_count_v1(nrow(d)),
      status = status,
      stringsAsFactors = FALSE
    )
  }))
  diagnostic <- data.frame(
    model_version_id = "SOG_EVENT_STUDY_v1",
    analysis_taxon_id = taxon_id,
    unit_label = unit_label,
    analysis_role = analysis_role,
    region = "SoG",
    outcome = outcome,
    converged = classification$converged,
    singular_fit = singular_fit,
    rank_deficient = rank_deficient,
    convergence_message = classification$message,
    max_abs_gradient = gradient_check$max_abs_gradient,
    gradient_check_status = gradient_check$gradient_check_status,
    devfun_reference_deviation = gradient_check$devfun_reference_deviation,
    n = .post_stage4a_release_count_v1(nrow(d)),
    status = model_status,
    stringsAsFactors = FALSE
  )
  result <- list(
    effect = effects,
    diagnostic = diagnostic,
    term_support = term_support
  )
  .post_stage4a_write_model_summary_v1(
    model_summary_dir, taxon_id, unit_label, analysis_role, outcome,
    model_status,
    beta = beta, covariance = covariance, gradient = gradient_check
  )
  saveRDS(list(cache_signature = cache_signature, result = result),
          checkpoint_path)
  result
}

post_stage4a_adjust_multiplicity_v1 <- function(effects) {
  effects$multiplicity_family <- paste(
    effects$analysis_role,
    effects$outcome,
    effects$contrast,
    sep = "__"
  )
  effects$q_value <- NA_real_
  for (family in unique(effects$multiplicity_family)) {
    index <- which(
      effects$multiplicity_family == family &
      is.finite(effects$p_value)
    )
    effects$q_value[index] <- stats::p.adjust(
      effects$p_value[index], method = "BH"
    )
  }
  effects
}

post_stage4a_worker_count_v1 <- function(maximum) {
  requested <- suppressWarnings(as.integer(Sys.getenv(
    "POST_STAGE4A_SOG_EVENT_STUDY_WORKERS",
    unset = "4"
  )))
  if (length(requested) != 1L || is.na(requested) || requested < 1L) {
    stop("POST_STAGE4A_EVENT_STUDY_WORKER_GATE: workers must be a positive integer",
         call. = FALSE)
  }
  min(requested, as.integer(maximum))
}

.post_stage4a_sha256_v1 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

.post_stage4a_write_csv_v1 <- function(x, path) {
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  utils::write.table(
    x, con, sep = ",", row.names = FALSE, col.names = TRUE,
    na = "", qmethod = "double", eol = "\n"
  )
}

.post_stage4a_write_yaml_v1 <- function(x, path) {
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  writeChar(yaml::as.yaml(x), con, eos = NULL)
}

post_stage4a_fit_taxon_v1 <- function(
    events, states, masks, taxon_id, species_registry, comparator_taxa,
    checkpoint_dir, code_signature, model_summary_dir = NULL,
    nAGQ = 0L) {
  unit_label <- species_registry$common_name[
    match(taxon_id, species_registry$analysis_taxon_id)
  ]
  if (length(unit_label) != 1L || is.na(unit_label) || !nzchar(unit_label)) {
    stop("POST_STAGE4A_EVENT_STUDY_TAXON_NAME_GATE: unresolved taxon",
         call. = FALSE)
  }
  analysis_role <- if (taxon_id %in% comparator_taxa) {
    "specificity_comparator"
  } else {
    "core_species"
  }
  denominator <- stage4a_materialize_taxon(
    events, states, masks, taxon_id
  )
  outcomes <- if (analysis_role == "specificity_comparator") {
    "detection"
  } else {
    c("detection", "positive_numeric_count_given_detection")
  }
  lapply(outcomes, function(outcome) {
    checkpoint <- file.path(
      checkpoint_dir,
      paste(taxon_id, outcome, "rds", sep = "_")
    )
    post_stage4a_fit_one_v1(
      denominator, taxon_id, unit_label, analysis_role, outcome,
      checkpoint, code_signature, model_summary_dir, nAGQ
    )
  })
}

.post_stage4a_frozen_release_dir_v1 <-
  "outputs/post_stage4a_sog_event_study_v1"

.post_stage4a_guard_frozen_outputs_v1 <- function(output_dir) {
  normalise <- function(path) {
    sub("/+$", "", gsub("\\\\", "/", path))
  }
  if (identical(normalise(output_dir),
                normalise(.post_stage4a_frozen_release_dir_v1))) {
    stop(
      "POST_STAGE4A_EVENT_STUDY_FROZEN_OUTPUT_GATE: ",
      "the v1 release directory is hash-locked; write refits to a new ",
      "versioned output directory instead",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

.post_stage4a_require_authorization_v1 <- function() {
  acknowledgement <- "through_2025_post_result_refinement_v1"
  if (!identical(Sys.getenv("POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED"),
                 acknowledgement)) {
    stop(
      "Production requires the exact post-Stage 4A event-study acknowledgement",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

post_stage4a_prepare_event_study_inputs_v1 <- function() {
  packages <- c("data.table", "digest", "lme4", "yaml")
  missing <- packages[!vapply(
    packages, requireNamespace, logical(1L), quietly = TRUE
  )]
  if (length(missing)) {
    stop("Missing packages: ", paste(missing, collapse = ", "), call. = FALSE)
  }

  protected_files <- c(
    event_metadata =
      "data/derived/stage4a_protected/stage4a_event_metadata.tsv.gz",
    source_links =
      "data/derived/stage3_phase2_protected/metadata_source_point_links.tsv.gz",
    reported_states =
      "data/derived/stage4a_protected/stage4a_reported_states.tsv.gz",
    ambiguity_masks =
      "data/derived/stage4a_protected/stage4a_ambiguity_masks.tsv.gz"
  )
  if (!all(file.exists(protected_files))) {
    stop("Protected through-2025 event-study inputs are unavailable",
         call. = FALSE)
  }
  source_link_hash <- .post_stage4a_sha256_v1(
    protected_files[["source_links"]]
  )
  if (!identical(
      source_link_hash,
      "f26197d0a71fd177e77774ec9e5596563c127ec8eb0f948042aff51ad805567b"
  )) {
    stop("POST_STAGE4A_EVENT_STUDY_SOURCE_LINK_HASH_GATE: mismatch",
         call. = FALSE)
  }
  protected_hashes <- vapply(
    protected_files, .post_stage4a_sha256_v1, character(1L)
  )

  events_all <- .stage4a_read_gz(protected_files[["event_metadata"]])
  if (nrow(events_all) != 239934L) {
    stop("POST_STAGE4A_EVENT_STUDY_EVENT_CARDINALITY_GATE: expected 239934 rows",
         call. = FALSE)
  }
  if (any(as.integer(events_all$checklist_year) > 2025L)) {
    stop("POST_STAGE4A_EVENT_STUDY_YEAR_GATE: 2026+ data encountered",
         call. = FALSE)
  }
  events_all <- .stage4a_prepare_events(events_all)
  selected <- events_all$region == "SoG" &
    events_all$checklist_year >= 2005L &
    events_all$checklist_year <= 2025L
  if (anyNA(selected) || sum(selected) != 217200L) {
    stop("POST_STAGE4A_EVENT_STUDY_SOG_SCOPE_GATE: expected 217200 events",
         call. = FALSE)
  }
  events <- events_all[selected, , drop = FALSE]
  rm(events_all)
  if (!all(stage4a_effort_eligible(
      events$protocol, events$duration_minutes,
      events$effort_distance_km, events$observer_count))) {
    stop("POST_STAGE4A_EVENT_STUDY_EFFORT_GATE: ineligible checklist",
         call. = FALSE)
  }
  stage4a_validate_folds(events)

  links <- .stage4a_read_gz(protected_files[["source_links"]])
  joint <- post_stage4a_add_joint_exposure_v1(events, links)
  events <- joint$events
  support <- joint$support
  rm(links, joint)

  states_all <- .stage4a_read_gz(protected_files[["reported_states"]])
  masks_all <- .stage4a_read_gz(protected_files[["ambiguity_masks"]])
  if (nrow(states_all) != 1169612L || nrow(masks_all) != 5834L) {
    stop("POST_STAGE4A_EVENT_STUDY_SPARSE_STATE_CARDINALITY_GATE: changed",
         call. = FALSE)
  }
  selected_tokens <- events$analysis_event_token
  states <- states_all[
    states_all$analysis_event_token %in% selected_tokens, , drop = FALSE
  ]
  masks <- masks_all[
    masks_all$analysis_event_token %in% selected_tokens, , drop = FALSE
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
  roles <- utils::read.csv(
    "metadata/post_stage4a_sog_event_study_species_roles_v1.csv",
    stringsAsFactors = FALSE
  )
  core_taxa <- support_registry$analysis_taxon_id[which(
    support_registry$named_species_recommendation == "named_species_core"
  )]
  comparator_taxa <- roles$analysis_taxon_id[
    roles$presentation_role == "supplementary_specificity_comparator"
  ]
  if (length(core_taxa) != 49L || length(comparator_taxa) != 2L ||
      anyDuplicated(c(core_taxa, comparator_taxa))) {
    stop("POST_STAGE4A_EVENT_STUDY_TAXON_GATE: taxon scope changed",
         call. = FALSE)
  }
  main_taxa <- roles$analysis_taxon_id[
    roles$presentation_role == "main_ecological_panel"
  ]
  if (length(main_taxa) != 11L || !all(main_taxa %in% core_taxa)) {
    stop("POST_STAGE4A_EVENT_STUDY_MAIN_PANEL_GATE: expected 11 core taxa",
         call. = FALSE)
  }

  list(
    events = events,
    states = states,
    masks = masks,
    support = support,
    species_registry = species_registry,
    core_taxa = core_taxa,
    comparator_taxa = comparator_taxa,
    main_taxa = main_taxa,
    protected_hashes = protected_hashes
  )
}

run_post_stage4a_sog_event_study_v1 <- function(
    execution_code_commit,
    output_dir = "outputs/post_stage4a_sog_event_study_v1_1",
    model_summary_dir =
      "outputs/post_stage4a_sog_event_study_model_summaries_v1") {
  .post_stage4a_guard_frozen_outputs_v1(output_dir)
  .post_stage4a_require_authorization_v1()
  prepared <- post_stage4a_prepare_event_study_inputs_v1()
  events <- prepared$events
  states <- prepared$states
  masks <- prepared$masks
  support <- prepared$support
  species_registry <- prepared$species_registry
  core_taxa <- prepared$core_taxa
  comparator_taxa <- prepared$comparator_taxa
  main_taxa <- prepared$main_taxa
  protected_hashes <- prepared$protected_hashes
  rm(prepared)
  protected_dir <- "data/derived/post_stage4a_sog_event_study_v1"
  checkpoint_dir <- file.path(protected_dir, "checkpoints")
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  if (!is.null(model_summary_dir)) {
    dir.create(model_summary_dir, recursive = TRUE, showWarnings = FALSE)
  }
  code_signature <- paste(
    execution_code_commit,
    protected_hashes,
    .post_stage4a_sha256_v1(
      "metadata/post_stage4a_sog_event_study_spec_v1.yml"
    ),
    sep = "|",
    collapse = "|"
  )

  all_taxa <- c(core_taxa, comparator_taxa)
  workers <- post_stage4a_worker_count_v1(length(all_taxa))
  fit_one_taxon <- function(taxon_id) {
    post_stage4a_fit_taxon_v1(
      events, states, masks, taxon_id, species_registry, comparator_taxa,
      checkpoint_dir, code_signature, model_summary_dir
    )
  }
  if (workers == 1L) {
    results_by_taxon <- lapply(all_taxa, fit_one_taxon)
  } else {
    cluster <- parallel::makePSOCKcluster(workers)
    results_by_taxon <- tryCatch({
      parallel::clusterEvalQ(cluster, {
        Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
        source(file.path("R", "stage4a_core.R"), local = FALSE)
        source(file.path("R", "stage4a_production.R"), local = FALSE)
        source(
          file.path("R", "post_stage4a_sog_event_study_v1.R"),
          local = FALSE
        )
        NULL
      })
      parallel::clusterExport(
        cluster,
        c(
          "events", "states", "masks", "species_registry",
          "comparator_taxa", "checkpoint_dir", "code_signature",
          "model_summary_dir"
        ),
        envir = environment()
      )
      parallel::parLapply(cluster, all_taxa, function(taxon_id) {
        post_stage4a_fit_taxon_v1(
          events, states, masks, taxon_id, species_registry, comparator_taxa,
          checkpoint_dir, code_signature, model_summary_dir
        )
      })
    }, finally = {
      parallel::stopCluster(cluster)
    })
  }
  results <- unlist(results_by_taxon, recursive = FALSE)

  effects <- do.call(rbind, lapply(results, `[[`, "effect"))
  diagnostics <- do.call(rbind, lapply(results, `[[`, "diagnostic"))
  term_support <- do.call(rbind, lapply(results, `[[`, "term_support"))
  effects <- post_stage4a_adjust_multiplicity_v1(effects)
  main_panel <- effects[
    effects$analysis_taxon_id %in% main_taxa &
      effects$contrast %in% c(
        "did_pre_14_day", "did_pre_7_day", "did_spawn_start",
        "did_early_egg", "did_late_egg", "did_active_0_14_day"
      ),
    , drop = FALSE
  ]
  comparators <- effects[
    effects$analysis_role == "specificity_comparator", , drop = FALSE
  ]

  .post_stage4a_write_csv_v1(
    effects, file.path(output_dir, "effect_estimates_v1.csv")
  )
  .post_stage4a_write_csv_v1(
    diagnostics, file.path(output_dir, "model_diagnostics_v1.csv")
  )
  .post_stage4a_write_csv_v1(
    term_support, file.path(output_dir, "model_term_support_v1.csv")
  )
  .post_stage4a_write_csv_v1(
    support, file.path(output_dir, "joint_exposure_support_v1.csv")
  )
  .post_stage4a_write_csv_v1(
    main_panel, file.path(output_dir, "main_species_panel_v1.csv")
  )
  .post_stage4a_write_csv_v1(
    comparators, file.path(output_dir, "specificity_comparators_v1.csv")
  )
  active_minus_pre <- effects[
    effects$contrast == "active_minus_pre_14_day", , drop = FALSE
  ]
  if (!nrow(active_minus_pre)) {
    stop("POST_STAGE4A_EVENT_STUDY_CONTRAST_ARCHIVE_GATE: ",
         "active_minus_pre_14_day produced no rows", call. = FALSE)
  }
  .post_stage4a_write_csv_v1(
    active_minus_pre, file.path(output_dir, "active_minus_pre_contrasts_v1.csv")
  )

  status_counts <- as.list(table(diagnostics$status))
  gradient_counts <- as.list(table(diagnostics$gradient_check_status))
  gradient_values <- suppressWarnings(as.numeric(
    diagnostics$max_abs_gradient
  ))
  gradient_values <- gradient_values[is.finite(gradient_values)]
  execution_record <- list(
    execution_version = "post_stage4a_sog_event_study_v1",
    executed_at_utc = format(
      as.POSIXct(Sys.time(), tz = "UTC"),
      "%Y-%m-%dT%H:%M:%SZ"
    ),
    execution_code_commit = execution_code_commit,
    analysis_status = "post_result_ecologically_motivated_refinement",
    historical_stage4a_outputs_modified = FALSE,
    region = "SoG",
    years = c(2005L, 2025L),
    eligible_checklists = nrow(events),
    core_species = length(core_taxa),
    main_panel_species = length(main_taxa),
    specificity_comparators = length(comparator_taxa),
    parallel_workers = workers,
    model_components = nrow(diagnostics),
    model_status_counts = status_counts,
    gradient_check_status_counts = gradient_counts,
    gradient_components_checked = length(gradient_values),
    max_abs_gradient_overall = if (length(gradient_values)) {
      max(gradient_values)
    } else {
      NA_real_
    },
    active_minus_pre_contrast_archived = TRUE,
    model_summary_dir = if (is.null(model_summary_dir)) {
      "not_written"
    } else {
      gsub("\\\\", "/", model_summary_dir)
    },
    protected_input_hashes = as.list(protected_hashes),
    source_link_hash_gate = "PASS",
    concurrent_link_joint_pairing_gate = "PASS",
    records_2026_plus_read = 0L,
    comments_read = 0L,
    shoreline_fields_read = 0L,
    full_event_taxon_grid_expanded = FALSE,
    final_gate = "PASS_PENDING_HUMAN_POST_STAGE4A_EVENT_STUDY_REVIEW"
  )
  .post_stage4a_write_yaml_v1(
    execution_record,
    file.path(output_dir, "execution_record_v1.yml")
  )

  output_files <- file.path(
    output_dir,
    c(
      "effect_estimates_v1.csv",
      "model_diagnostics_v1.csv",
      "model_term_support_v1.csv",
      "joint_exposure_support_v1.csv",
      "main_species_panel_v1.csv",
      "specificity_comparators_v1.csv",
      "active_minus_pre_contrasts_v1.csv",
      "execution_record_v1.yml"
    )
  )
  manifest <- data.frame(
    file = gsub("\\\\", "/", output_files),
    sha256 = vapply(
      output_files, .post_stage4a_sha256_v1, character(1L)
    ),
    stringsAsFactors = FALSE
  )
  .post_stage4a_write_csv_v1(
    manifest, file.path(output_dir, "output_hash_manifest_v1.csv")
  )
  message(
    "POST_STAGE4A_SOG_EVENT_STUDY_GATE=",
    "PASS_PENDING_HUMAN_POST_STAGE4A_EVENT_STUDY_REVIEW"
  )
  invisible(list(
    effects = effects,
    diagnostics = diagnostics,
    support = support
  ))
}
