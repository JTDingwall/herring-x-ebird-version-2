editorial_release_count_v1 <- function(x, threshold = 20L) {
  ifelse(is.finite(x) & x > 0 & x < threshold, NA_real_, x)
}

editorial_write_csv_v1 <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  utils::write.table(
    x, con, sep = ",", row.names = FALSE, col.names = TRUE, na = "",
    qmethod = "double", eol = "\n"
  )
}

editorial_sha256_v1 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

editorial_contrast_weights_v1 <- function() {
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
  active <- combine((4 / 15) * did("spawn_start"), (11 / 15) * did("early_egg"))
  pre14 <- combine(0.5 * did("early_pre"), 0.5 * did("immediate_pre"))
  pre7 <- did("immediate_pre")
  list(
    did_active_0_14_day = active,
    did_pre_14_day = pre14,
    did_pre_7_day = pre7,
    active_minus_pre14 = combine(active, -pre14),
    active_minus_pre7 = combine(active, -pre7)
  )
}

editorial_vector_v1 <- function(coefficient_names, weights) {
  if (!all(names(weights) %in% coefficient_names)) return(NULL)
  out <- stats::setNames(rep(0, length(coefficient_names)), coefficient_names)
  out[names(weights)] <- weights
  out
}

editorial_wald_v1 <- function(beta, covariance, weights) {
  vector <- editorial_vector_v1(names(beta), weights)
  if (is.null(vector)) {
    return(c(estimate = NA_real_, standard_error = NA_real_,
             conf_low = NA_real_, conf_high = NA_real_, p_value = NA_real_))
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

editorial_compound_effects_v1 <- function(
    beta, covariance, taxon_id, unit_label, outcome, n, model_status) {
  weights <- editorial_contrast_weights_v1()
  components <- lapply(weights, editorial_wald_v1, beta = beta,
                       covariance = covariance)
  active_vector <- editorial_vector_v1(names(beta), weights$did_active_0_14_day)
  pre14_vector <- editorial_vector_v1(names(beta), weights$did_pre_14_day)
  pre7_vector <- editorial_vector_v1(names(beta), weights$did_pre_7_day)
  covariance_for <- function(x, y) {
    if (is.null(x) || is.null(y)) return(NA_real_)
    drop(t(x) %*% covariance %*% y)
  }
  rows <- lapply(c("active_minus_pre14", "active_minus_pre7"), function(name) {
    x <- components[[name]]
    pre_name <- if (name == "active_minus_pre14") "did_pre_14_day" else
      "did_pre_7_day"
    pre_vector <- if (name == "active_minus_pre14") pre14_vector else pre7_vector
    data.frame(
      analysis_version = "editorial_requested_analysis_v1",
      analysis_taxon_id = taxon_id,
      species = unit_label,
      outcome = outcome,
      comparison = name,
      primary_comparison = name == "active_minus_pre14",
      active_estimate = components$did_active_0_14_day[["estimate"]],
      active_standard_error =
        components$did_active_0_14_day[["standard_error"]],
      pre_estimate = components[[pre_name]][["estimate"]],
      pre_standard_error = components[[pre_name]][["standard_error"]],
      active_pre_covariance = covariance_for(active_vector, pre_vector),
      estimate = x[["estimate"]],
      standard_error = x[["standard_error"]],
      conf_low = x[["conf_low"]],
      conf_high = x[["conf_high"]],
      ratio = exp(x[["estimate"]]),
      ratio_conf_low = exp(x[["conf_low"]]),
      ratio_conf_high = exp(x[["conf_high"]]),
      p_value = x[["p_value"]],
      q_value = NA_real_,
      n = editorial_release_count_v1(n),
      full_covariance_used = TRUE,
      status = if (all(is.finite(x[c("estimate", "standard_error")])) &&
                       x[["standard_error"]] > 0) model_status else
        "failed_contrast_geometry",
      stringsAsFactors = FALSE
    )
  })
  list(contrasts = do.call(rbind, rows), components = components)
}

editorial_empty_model_v1 <- function(
    taxon_id, unit_label, outcome, n, status, term_support = NULL) {
  contrast_rows <- do.call(rbind, lapply(
    c("active_minus_pre14", "active_minus_pre7"),
    function(comparison) {
      data.frame(
        analysis_version = "editorial_requested_analysis_v1",
        analysis_taxon_id = taxon_id,
        species = unit_label,
        outcome = outcome,
        comparison = comparison,
        primary_comparison = comparison == "active_minus_pre14",
        active_estimate = NA_real_,
        active_standard_error = NA_real_,
        pre_estimate = NA_real_,
        pre_standard_error = NA_real_,
        active_pre_covariance = NA_real_,
        estimate = NA_real_,
        standard_error = NA_real_,
        conf_low = NA_real_,
        conf_high = NA_real_,
        ratio = NA_real_,
        ratio_conf_low = NA_real_,
        ratio_conf_high = NA_real_,
        p_value = NA_real_,
        q_value = NA_real_,
        n = editorial_release_count_v1(n),
        full_covariance_used = TRUE,
        status = status,
        stringsAsFactors = FALSE
      )
    }
  ))
  diagnostics <- data.frame(
    analysis_version = "editorial_requested_analysis_v1",
    analysis_taxon_id = taxon_id,
    species = unit_label,
    outcome = outcome,
    engine = if (outcome == "conditional_positive_numeric_count") {
      "lme4_lmer_REML"
    } else {
      "lme4_glmer_nAGQ0"
    },
    n = editorial_release_count_v1(n),
    event_blocks = NA_real_,
    observer_clusters = NA_real_,
    generalized_locations = NA_real_,
    converged = FALSE,
    singular_fit = NA,
    rank_deficient = NA,
    optimizer_code = NA_character_,
    convergence_message = status,
    maximum_absolute_gradient = NA_real_,
    event_block_variance = NA_real_,
    observer_variance = NA_real_,
    location_variance = NA_real_,
    residual_variance = NA_real_,
    reproduction_max_abs_estimate_difference = NA_real_,
    status = status,
    stringsAsFactors = FALSE
  )
  list(
    contrasts = contrast_rows,
    diagnostics = diagnostics,
    term_support = term_support,
    beta = numeric(),
    covariance = matrix(numeric(), 0, 0),
    sigma = NA_real_,
    predictions = data.frame()
  )
}

editorial_term_support_v1 <- function(d, taxon_id, unit_label, outcome) {
  terms <- post_stage4a_exposure_terms_v1()
  out <- data.frame(
    analysis_taxon_id = taxon_id,
    species = unit_label,
    outcome = outcome,
    term = terms,
    exposed_rows = vapply(terms, function(term) sum(d[[term]] > 0L), integer(1L)),
    stringsAsFactors = FALSE
  )
  if (outcome == "finite_numeric_vs_x") {
    out$finite_numeric_rows <- vapply(
      terms, function(term) sum(d[[term]] > 0L & d$model_response == 1L),
      integer(1L)
    )
    out$unquantified_x_rows <- vapply(
      terms, function(term) sum(d[[term]] > 0L & d$model_response == 0L),
      integer(1L)
    )
  } else {
    out$finite_numeric_rows <- NA_integer_
    out$unquantified_x_rows <- NA_integer_
  }
  for (name in c("exposed_rows", "finite_numeric_rows", "unquantified_x_rows")) {
    out[[name]] <- editorial_release_count_v1(out[[name]])
  }
  out
}

editorial_formula_v1 <- function(response) {
  post_stage4a_formula_v1(response)
}

editorial_base_design_v1 <- function(events) {
  fixed <- c(
    post_stage4a_exposure_terms_v1(),
    "factor(checklist_year)", "protocol", "log_duration",
    "log_effort_distance", "observer_count"
  )
  stats::model.matrix(
    stats::as.formula(paste("~", paste(fixed, collapse = " + "))),
    data = events
  )
}

editorial_scenario_values_v1 <- function() {
  zero <- stats::setNames(rep(0, length(post_stage4a_exposure_terms_v1())),
                          post_stage4a_exposure_terms_v1())
  make <- function(...) {
    out <- zero
    values <- list(...)
    for (value in values) out[[names(value)]] <- unname(value)
    out
  }
  list(
    baseline_near = make(es_near_baseline = 1),
    baseline_reference = make(es_reference_baseline = 1),
    pre14_near = make(
      es_near_early_pre = 0.5, es_near_immediate_pre = 0.5
    ),
    pre14_reference = make(
      es_reference_early_pre = 0.5,
      es_reference_immediate_pre = 0.5
    ),
    active_near = make(
      es_near_spawn_start = 4 / 15, es_near_early_egg = 11 / 15
    ),
    active_reference = make(
      es_reference_spawn_start = 4 / 15,
      es_reference_early_egg = 11 / 15
    )
  )
}

editorial_standardized_vector_v1 <- function(beta_names, exposure_values) {
  x <- stats::setNames(rep(0, length(beta_names)), beta_names)
  if ("(Intercept)" %in% beta_names) x[["(Intercept)"]] <- 1
  present <- names(exposure_values)[names(exposure_values) %in% beta_names]
  x[present] <- exposure_values[present]
  year_name <- "factor(checklist_year)2020"
  if (year_name %in% beta_names) x[[year_name]] <- 1
  if ("log_duration" %in% beta_names) x[["log_duration"]] <- log(60)
  if ("log_effort_distance" %in% beta_names) {
    x[["log_effort_distance"]] <- 0
  }
  if ("observer_count" %in% beta_names) x[["observer_count"]] <- 1
  x
}

editorial_mvn_draws_v1 <- function(beta, covariance, draws, seed) {
  covariance <- (covariance + t(covariance)) / 2
  decomposition <- eigen(covariance, symmetric = TRUE)
  values <- pmax(decomposition$values, 0)
  transform <- decomposition$vectors %*%
    diag(sqrt(values), nrow = length(values))
  set.seed(seed)
  z <- matrix(stats::rnorm(draws * length(beta)), nrow = draws)
  sweep(z %*% t(transform), 2L, beta, "+")
}

editorial_prediction_scale_v1 <- function(eta, outcome, sigma) {
  if (outcome == "checklist_reporting") {
    stats::plogis(eta)
  } else {
    exp(eta + 0.5 * sigma^2)
  }
}

editorial_prediction_derivative_v1 <- function(eta, outcome, sigma) {
  if (outcome == "checklist_reporting") {
    p <- stats::plogis(eta)
    p * (1 - p)
  } else {
    exp(eta + 0.5 * sigma^2)
  }
}

editorial_prediction_contrasts_v1 <- function(values) {
  differences <- c(
    baseline = values[["baseline_near"]] - values[["baseline_reference"]],
    pre14 = values[["pre14_near"]] - values[["pre14_reference"]],
    active = values[["active_near"]] - values[["active_reference"]]
  )
  c(
    values,
    baseline_near_reference = differences[["baseline"]],
    pre14_near_reference = differences[["pre14"]],
    active_near_reference = differences[["active"]],
    pre14_baseline_adjusted = differences[["pre14"]] - differences[["baseline"]],
    active_baseline_adjusted = differences[["active"]] - differences[["baseline"]],
    active_minus_pre14 = differences[["active"]] - differences[["pre14"]]
  )
}

editorial_prediction_gradients_v1 <- function(gradients) {
  differences <- list(
    baseline = gradients$baseline_near - gradients$baseline_reference,
    pre14 = gradients$pre14_near - gradients$pre14_reference,
    active = gradients$active_near - gradients$active_reference
  )
  c(
    gradients,
    list(
      baseline_near_reference = differences$baseline,
      pre14_near_reference = differences$pre14,
      active_near_reference = differences$active,
      pre14_baseline_adjusted = differences$pre14 - differences$baseline,
      active_baseline_adjusted = differences$active - differences$baseline,
      active_minus_pre14 = differences$active - differences$pre14
    )
  )
}

editorial_predictions_v1 <- function(
    beta, covariance, sigma, outcome, taxon_id, unit_label, base_design,
    simulation_draws = 2000L) {
  if (!outcome %in% c(
      "checklist_reporting", "conditional_positive_numeric_count")) {
    return(data.frame())
  }
  scenarios <- editorial_scenario_values_v1()
  beta_names <- names(beta)
  base <- base_design[, beta_names, drop = FALSE]
  exposure_names <- intersect(post_stage4a_exposure_terms_v1(), beta_names)
  base[, exposure_names] <- 0

  standardized_x <- lapply(
    scenarios, editorial_standardized_vector_v1, beta_names = beta_names
  )
  standardized_point <- vapply(
    standardized_x,
    function(x) editorial_prediction_scale_v1(
      sum(x * beta), outcome = outcome, sigma = sigma
    ),
    numeric(1L)
  )
  seed <- 1701L + sum(utf8ToInt(paste(taxon_id, outcome)))
  draws <- editorial_mvn_draws_v1(
    beta, covariance, simulation_draws, seed
  )
  standardized_draw_values <- vapply(
    standardized_x,
    function(x) {
      editorial_prediction_scale_v1(
        drop(draws %*% x), outcome = outcome, sigma = sigma
      )
    },
    numeric(simulation_draws)
  )
  standardized_all <- editorial_prediction_contrasts_v1(standardized_point)
  standardized_draw_all <- apply(
    standardized_draw_values, 1L, function(x) {
      editorial_prediction_contrasts_v1(
        stats::setNames(x, names(standardized_point))
      )
    }
  )
  if (is.vector(standardized_draw_all)) {
    standardized_draw_all <- matrix(
      standardized_draw_all, ncol = simulation_draws
    )
  }
  standardized_rows <- do.call(rbind, lapply(
    names(standardized_all), function(quantity) {
      values <- standardized_draw_all[quantity, ]
      data.frame(
        analysis_taxon_id = taxon_id,
        species = unit_label,
        outcome = outcome,
        prediction_configuration = "standardized_one_additional_link",
        quantity = quantity,
        estimate = standardized_all[[quantity]],
        conf_low = unname(stats::quantile(values, 0.025, na.rm = TRUE)),
        conf_high = unname(stats::quantile(values, 0.975, na.rm = TRUE)),
        interval_method = paste0(
          "joint_fixed_effect_covariance_simulation_", simulation_draws, "_draws"
        ),
        random_effect_handling = "all_random_intercepts_set_to_zero",
        covariate_handling =
          "year_2020_stationary_60min_0km_1observer_other_links_zero",
        population =
          "eligible_SoG_complete_checklists_2005_2025_standardized_profile",
        stringsAsFactors = FALSE
      )
    }
  ))

  observed_values <- list()
  observed_gradients <- list()
  base_eta <- drop(base %*% beta)
  for (name in names(scenarios)) {
    exposure <- scenarios[[name]][exposure_names]
    shift <- sum(exposure * beta[exposure_names])
    eta <- base_eta + shift
    value <- editorial_prediction_scale_v1(eta, outcome, sigma)
    derivative <- editorial_prediction_derivative_v1(eta, outcome, sigma)
    gradient <- drop(crossprod(derivative, base)) / nrow(base)
    gradient[exposure_names] <- mean(derivative) * exposure
    observed_values[[name]] <- mean(value)
    observed_gradients[[name]] <- gradient
  }
  observed_all <- editorial_prediction_contrasts_v1(
    unlist(observed_values, use.names = TRUE)
  )
  observed_gradient_all <- editorial_prediction_gradients_v1(observed_gradients)
  observed_rows <- do.call(rbind, lapply(names(observed_all), function(quantity) {
    gradient <- observed_gradient_all[[quantity]]
    variance <- drop(t(gradient) %*% covariance %*% gradient)
    standard_error <- if (is.finite(variance) && variance >= 0) {
      sqrt(variance)
    } else {
      NA_real_
    }
    z <- 1.959963984540054
    data.frame(
      analysis_taxon_id = taxon_id,
      species = unit_label,
      outcome = outcome,
      prediction_configuration = "observed_covariate_standardization",
      quantity = quantity,
      estimate = observed_all[[quantity]],
      conf_low = observed_all[[quantity]] - z * standard_error,
      conf_high = observed_all[[quantity]] + z * standard_error,
      interval_method = "full_distribution_first_order_delta_fixed_effect_vcov",
      random_effect_handling = "all_random_intercepts_set_to_zero",
      covariate_handling =
        "full_observed_covariate_distribution_all_other_links_zero",
      population = "eligible_SoG_complete_checklists_2005_2025",
      stringsAsFactors = FALSE
    )
  }))
  rbind(standardized_rows, observed_rows)
}

editorial_random_variances_v1 <- function(fit) {
  vc <- as.data.frame(lme4::VarCorr(fit))
  get_variance <- function(group) {
    value <- vc$vcov[vc$grp == group & is.na(vc$var2)]
    if (length(value)) value[[1L]] else NA_real_
  }
  c(
    event_block_variance = get_variance("event_block_token"),
    observer_variance = get_variance("observer_cluster_token"),
    location_variance = get_variance("location_cluster_token"),
    residual_variance = if ("Residual" %in% vc$grp) {
      get_variance("Residual")
    } else {
      NA_real_
    }
  )
}

editorial_fit_model_v1 <- function(
    dat, outcome, taxon_id, unit_label, checkpoint_path, cache_signature,
    base_design, frozen_effects) {
  if (file.exists(checkpoint_path)) {
    cached <- readRDS(checkpoint_path)
    if (identical(cached$cache_signature, cache_signature)) {
      return(cached$result)
    }
  }
  if (outcome == "checklist_reporting") {
    use <- !is.na(dat$detection)
    response <- "model_response"
    dat$model_response <- dat$detection
  } else if (outcome == "conditional_positive_numeric_count") {
    use <- is.finite(dat$numeric_count) & dat$numeric_count > 0
    response <- "model_response"
    dat$model_response <- log(dat$numeric_count)
  } else if (outcome == "finite_numeric_vs_x") {
    use <- !is.na(dat$detection) & dat$detection == 1L &
      !dat$ambiguity_flag & dat$count_type %in% c("numeric", "unquantified_X")
    response <- "model_response"
    dat$model_response <- ifelse(dat$count_type == "numeric", 1L, 0L)
  } else {
    stop("Unsupported editorial outcome: ", outcome, call. = FALSE)
  }
  d <- dat[use, , drop = FALSE]
  support <- editorial_term_support_v1(d, taxon_id, unit_label, outcome)
  exposed <- support$exposed_rows
  insufficient <- nrow(d) < 20L || any(is.na(exposed) | exposed < 20L) ||
    length(unique(d$model_response)) < 2L
  if (outcome == "finite_numeric_vs_x") {
    class_counts <- table(d$model_response)
    insufficient <- insufficient || length(class_counts) < 2L ||
      any(class_counts < 20L)
  }
  grouping_levels <- c(
    event_block_token = length(unique(d$event_block_token)),
    observer_cluster_token = length(unique(d$observer_cluster_token)),
    location_cluster_token = length(unique(d$location_cluster_token))
  )
  insufficient <- insufficient || any(grouping_levels < 2L)
  if (insufficient) {
    result <- editorial_empty_model_v1(
      taxon_id, unit_label, outcome, nrow(d),
      "failed_insufficient_support", support
    )
    saveRDS(list(cache_signature = cache_signature, result = result),
            checkpoint_path)
    return(result)
  }

  formula <- editorial_formula_v1(response)
  fit <- try(
    if (outcome %in% c("checklist_reporting", "finite_numeric_vs_x")) {
      lme4::glmer(
        formula, data = d, family = stats::binomial(), nAGQ = 0L,
        control = lme4::glmerControl(
          optimizer = "nloptwrap", calc.derivs = TRUE,
          optCtrl = list(maxeval = 10000L)
        )
      )
    } else {
      lme4::lmer(
        formula, data = d, REML = TRUE,
        control = lme4::lmerControl(
          optimizer = "nloptwrap", calc.derivs = TRUE,
          optCtrl = list(maxeval = 10000L)
        )
      )
    },
    silent = TRUE
  )
  if (inherits(fit, "try-error")) {
    result <- editorial_empty_model_v1(
      taxon_id, unit_label, outcome, nrow(d),
      "failed_numerical_fit_no_fallback", support
    )
    result$diagnostics$convergence_message <- substr(
      gsub("[\r\n]+", " ", as.character(fit)), 1L, 240L
    )
    saveRDS(list(cache_signature = cache_signature, result = result),
            checkpoint_path)
    return(result)
  }

  beta <- lme4::fixef(fit)
  covariance <- as.matrix(stats::vcov(fit))
  singular <- lme4::isSingular(fit, tol = 1e-4)
  optimizer_code <- fit@optinfo$conv$opt
  classification <- .post_stage4a_model_messages_v1(
    optimizer_code, fit@optinfo$conv$lme4$messages, singular
  )
  converged <- classification$converged
  rank_deficient <- length(beta) < ncol(stats::model.matrix(
    lme4::nobars(formula), d
  ))
  status <- if (!converged) {
    "failed_convergence"
  } else if (singular) {
    "completed_with_singular_warning"
  } else if (rank_deficient) {
    "completed_with_rank_deficiency_warning"
  } else {
    "completed"
  }
  effects <- editorial_compound_effects_v1(
    beta, covariance, taxon_id, unit_label, outcome, nrow(d), status
  )
  gradients <- fit@optinfo$derivs$gradient
  random_variances <- editorial_random_variances_v1(fit)

  frozen_outcome <- if (outcome == "checklist_reporting") {
    "detection"
  } else if (outcome == "conditional_positive_numeric_count") {
    "positive_numeric_count_given_detection"
  } else {
    NA_character_
  }
  reproduction_difference <- NA_real_
  if (!is.na(frozen_outcome)) {
    current <- c(
      did_active_0_14_day =
        effects$components$did_active_0_14_day[["estimate"]],
      did_pre_14_day = effects$components$did_pre_14_day[["estimate"]],
      did_pre_7_day = effects$components$did_pre_7_day[["estimate"]]
    )
    historical <- frozen_effects[
      frozen_effects$analysis_taxon_id == taxon_id &
        frozen_effects$outcome == frozen_outcome &
        frozen_effects$contrast %in% names(current),
      c("contrast", "estimate"), drop = FALSE
    ]
    if (nrow(historical) == length(current)) {
      expected <- stats::setNames(
        as.numeric(historical$estimate), historical$contrast
      )
      reproduction_difference <- max(abs(current[names(expected)] - expected))
    }
  }
  diagnostics <- data.frame(
    analysis_version = "editorial_requested_analysis_v1",
    analysis_taxon_id = taxon_id,
    species = unit_label,
    outcome = outcome,
    engine = if (outcome == "conditional_positive_numeric_count") {
      "lme4_lmer_REML"
    } else {
      "lme4_glmer_nAGQ0"
    },
    n = editorial_release_count_v1(nrow(d)),
    event_blocks = editorial_release_count_v1(grouping_levels[[1L]]),
    observer_clusters = editorial_release_count_v1(grouping_levels[[2L]]),
    generalized_locations = editorial_release_count_v1(grouping_levels[[3L]]),
    converged = converged,
    singular_fit = singular,
    rank_deficient = rank_deficient,
    optimizer_code = if (is.null(optimizer_code)) "" else
      paste(optimizer_code, collapse = "|"),
    convergence_message = classification$message,
    maximum_absolute_gradient = if (is.null(gradients)) NA_real_ else
      max(abs(gradients)),
    event_block_variance = random_variances[["event_block_variance"]],
    observer_variance = random_variances[["observer_variance"]],
    location_variance = random_variances[["location_variance"]],
    residual_variance = random_variances[["residual_variance"]],
    reproduction_max_abs_estimate_difference = reproduction_difference,
    status = status,
    stringsAsFactors = FALSE
  )
  sigma <- if (outcome == "conditional_positive_numeric_count") {
    stats::sigma(fit)
  } else {
    0
  }
  predictions <- editorial_predictions_v1(
    beta, covariance, sigma, outcome, taxon_id, unit_label, base_design
  )
  result <- list(
    contrasts = effects$contrasts,
    diagnostics = diagnostics,
    term_support = support,
    beta = beta,
    covariance = covariance,
    sigma = sigma,
    predictions = predictions
  )
  saveRDS(list(cache_signature = cache_signature, result = result),
          checkpoint_path)
  result
}

editorial_observed_summaries_v1 <- function(
    dat, taxon_id, unit_label, period_zone_support) {
  rows <- vector("list", nrow(period_zone_support))
  for (i in seq_len(nrow(period_zone_support))) {
    support <- period_zone_support[i, , drop = FALSE]
    term <- support$term[[1L]]
    use <- dat[[term]] > 0L
    reported <- use & dat$detection == 1L & !is.na(dat$detection)
    finite <- reported & dat$count_type == "numeric" &
      is.finite(dat$numeric_count) & dat$numeric_count > 0
    x <- reported & dat$count_type == "unquantified_X"
    lower <- reported & dat$count_type == "lower_bound"
    other <- reported & !(finite | x | lower)
    denominator <- sum(use)
    numerator <- sum(reported, na.rm = TRUE)
    suppress_report <- numerator > 0L && numerator < 20L
    finite_values <- dat$numeric_count[finite]
    rows[[i]] <- data.frame(
      analysis_taxon_id = taxon_id,
      species = unit_label,
      period = support$period,
      zone = support$zone,
      checklist_denominator = denominator,
      event_links = support$event_links,
      source_events = support$source_events,
      reported_checklists = if (suppress_report) NA_real_ else numerator,
      reporting_proportion = if (suppress_report) NA_real_ else
        numerator / denominator,
      finite_numeric_reports = editorial_release_count_v1(sum(finite)),
      unquantified_x_reports = editorial_release_count_v1(sum(x)),
      lower_bound_reports = editorial_release_count_v1(sum(lower)),
      other_reported_states = editorial_release_count_v1(sum(other)),
      finite_numeric_proportion_among_reports =
        if (suppress_report || sum(finite) < 20L) NA_real_ else
          sum(finite) / numerator,
      x_proportion_among_reports =
        if (suppress_report || sum(x) < 20L) NA_real_ else sum(x) / numerator,
      positive_finite_count_q25 =
        if (length(finite_values) < 20L) NA_real_ else
          unname(stats::quantile(finite_values, 0.25)),
      positive_finite_count_median =
        if (length(finite_values) < 20L) NA_real_ else
          stats::median(finite_values),
      positive_finite_count_q75 =
        if (length(finite_values) < 20L) NA_real_ else
          unname(stats::quantile(finite_values, 0.75)),
      observed_unadjusted = TRUE,
      suppressed_below_20 = suppress_report,
      stringsAsFactors = FALSE
    )
  }
  do.call(rbind, rows)
}

editorial_finite_x_summary_v1 <- function(dat, taxon_id, unit_label) {
  reported <- dat$detection == 1L & !is.na(dat$detection)
  finite <- reported & !dat$ambiguity_flag & dat$count_type == "numeric" &
    is.finite(dat$numeric_count) & dat$numeric_count > 0
  x <- reported & !dat$ambiguity_flag & dat$count_type == "unquantified_X"
  eligible <- finite | x
  data.frame(
    analysis_taxon_id = taxon_id,
    species = unit_label,
    reported_occurrences = editorial_release_count_v1(sum(reported)),
    finite_vs_x_denominator = editorial_release_count_v1(sum(eligible)),
    finite_numeric_reports = editorial_release_count_v1(sum(finite)),
    unquantified_x_reports = editorial_release_count_v1(sum(x)),
    finite_numeric_proportion = if (sum(eligible) >= 20L &&
      sum(finite) >= 20L && sum(x) >= 20L) sum(finite) / sum(eligible) else
        NA_real_,
    event_blocks = editorial_release_count_v1(
      length(unique(dat$event_block_token[eligible]))
    ),
    observer_clusters = editorial_release_count_v1(
      length(unique(dat$observer_cluster_token[eligible]))
    ),
    generalized_locations = editorial_release_count_v1(
      length(unique(dat$location_cluster_token[eligible]))
    ),
    stringsAsFactors = FALSE
  )
}

editorial_process_taxon_v1 <- function(
    taxon_id, events, states, masks, species_registry, checkpoint_dir,
    run_signature, base_design, frozen_effects, period_zone_support) {
  unit_label <- species_registry$common_name[
    match(taxon_id, species_registry$analysis_taxon_id)
  ]
  if (length(unit_label) != 1L || is.na(unit_label)) {
    stop("Unresolved species label for ", taxon_id, call. = FALSE)
  }
  dat <- stage4a_materialize_taxon(events, states, masks, taxon_id)
  observed <- editorial_observed_summaries_v1(
    dat, taxon_id, unit_label, period_zone_support
  )
  finite_summary <- editorial_finite_x_summary_v1(dat, taxon_id, unit_label)
  outcomes <- c(
    "checklist_reporting", "conditional_positive_numeric_count",
    "finite_numeric_vs_x"
  )
  models <- lapply(outcomes, function(outcome) {
    checkpoint <- file.path(
      checkpoint_dir, paste(taxon_id, outcome, "rds", sep = "_")
    )
    editorial_fit_model_v1(
      dat, outcome, taxon_id, unit_label, checkpoint,
      paste(run_signature, taxon_id, outcome, sep = "|"),
      base_design, frozen_effects
    )
  })
  names(models) <- outcomes
  list(models = models, observed = observed, finite_summary = finite_summary)
}

editorial_link_distribution_v1 <- function(events, classified_links) {
  modeled <- classified_links[, .(analysis_window_links = .N),
                              by = analysis_event_token]
  values <- modeled$analysis_window_links[
    match(events$analysis_event_token, modeled$analysis_event_token)
  ]
  values[is.na(values)] <- 0L
  exact_rows <- function(x, distribution) {
    counts <- table(x)
    data.frame(
      distribution = distribution,
      category = names(counts),
      checklists = editorial_release_count_v1(as.numeric(counts)),
      proportion = ifelse(as.numeric(counts) >= 20L,
                          as.numeric(counts) / length(x), NA_real_),
      stringsAsFactors = FALSE
    )
  }
  summary_counts <- c(
    zero = sum(values == 0L),
    one = sum(values == 1L),
    multiple = sum(values > 1L)
  )
  rbind(
    exact_rows(as.integer(events$concurrent_links), "all_concurrent_links_exact"),
    exact_rows(values, "analysis_window_links_exact"),
    data.frame(
      distribution = "analysis_window_links_summary",
      category = names(summary_counts),
      checklists = as.numeric(summary_counts),
      proportion = as.numeric(summary_counts) / length(values),
      stringsAsFactors = FALSE
    )
  )
}

editorial_inventory_v1 <- function(events, selected_links, classified_links,
                                   core_taxa, frozen_diagnostics) {
  totals <- data.frame(
    metric = c(
      "eligible_checklists", "source_herring_events", "event_blocks",
      "observer_clusters", "generalized_locations", "supported_species",
      "primary_checklist_reporting_estimable",
      "primary_conditional_count_estimable",
      "primary_failed_components", "primary_singular_components"
    ),
    value = c(
      nrow(events),
      length(unique(selected_links$herring_source_token)),
      length(unique(events$event_block_token)),
      length(unique(events$observer_cluster_token)),
      length(unique(events$location_cluster_token)),
      length(core_taxa),
      sum(frozen_diagnostics$analysis_role == "core_species" &
            frozen_diagnostics$outcome == "detection" &
            grepl("^completed", frozen_diagnostics$status)),
      sum(frozen_diagnostics$analysis_role == "core_species" &
            frozen_diagnostics$outcome ==
              "positive_numeric_count_given_detection" &
            grepl("^completed", frozen_diagnostics$status)),
      sum(frozen_diagnostics$analysis_role == "core_species" &
            grepl("^failed", frozen_diagnostics$status)),
      sum(frozen_diagnostics$analysis_role == "core_species" &
            frozen_diagnostics$singular_fit %in% TRUE)
    ),
    unit = c(
      "checklists", "source_events", "event_blocks", "clusters", "clusters",
      "species", "models", "models", "models", "models"
    ),
    scope = "SoG_2005_2025_frozen_event_study_population",
    qa_status = "verified",
    stringsAsFactors = FALSE
  )
  support <- classified_links[, .(
    checklists = uniqueN(analysis_event_token),
    event_links = .N,
    source_events = uniqueN(herring_source_token)
  ), by = .(period, zone, term)]
  support <- support[order(match(period, post_stage4a_period_spec_v1()$period),
                           match(zone, c("near", "reference"))), ]
  list(
    totals = totals,
    support = as.data.frame(support),
    link_distribution = editorial_link_distribution_v1(
      events, classified_links
    )
  )
}

editorial_event_block_support_v1 <- function(events) {
  size <- as.numeric(table(events$event_block_token))
  bin <- cut(
    size, breaks = c(-Inf, 19, 99, 499, 1999, 9999, Inf),
    labels = c("<20", "20-99", "100-499", "500-1999",
               "2000-9999", "10000+"),
    right = TRUE
  )
  levels <- levels(bin)
  data.frame(
    checklist_support_bin = levels,
    event_blocks = vapply(levels, function(x) sum(bin == x), integer(1L)),
    checklists = vapply(
      levels, function(x) sum(size[bin == x]), numeric(1L)
    ),
    influence_basis = "checklist_support_only_no_outcome_inspection",
    stringsAsFactors = FALSE
  )
}

editorial_adjust_bh_v1 <- function(contrasts) {
  contrasts$q_value <- NA_real_
  family <- paste(contrasts$outcome, contrasts$comparison, sep = "__")
  for (name in unique(family)) {
    index <- which(family == name & is.finite(contrasts$p_value))
    contrasts$q_value[index] <- stats::p.adjust(
      contrasts$p_value[index], method = "BH"
    )
  }
  contrasts$multiplicity_family <- paste0(
    "support_qualified_49_species__", family
  )
  contrasts
}

editorial_flatten_models_v1 <- function(results, field) {
  pieces <- unlist(lapply(results, function(x) {
    lapply(x$models, `[[`, field)
  }), recursive = FALSE)
  pieces <- pieces[vapply(pieces, function(x) is.data.frame(x) && nrow(x),
                          logical(1L))]
  if (!length(pieces)) return(data.frame())
  do.call(rbind, pieces)
}

editorial_privacy_column_gate_v1 <- function(paths) {
  prohibited <- c(
    "analysis_event_token", "analysis_checklist_id", "observer_cluster_token",
    "location_cluster_token", "event_block_token", "herring_source_token",
    "latitude", "longitude", "locality", "coordinates"
  )
  failures <- character()
  for (path in paths) {
    if (!file.exists(path) || !grepl("\\.csv$", path, ignore.case = TRUE)) next
    header <- names(utils::read.csv(path, nrows = 1L, check.names = FALSE))
    bad <- intersect(tolower(header), prohibited)
    if (length(bad)) failures <- c(failures, paste(path, bad, sep = ":"))
  }
  if (length(failures)) {
    stop("EDITORIAL_PRIVACY_COLUMN_GATE: ", paste(failures, collapse = "; "),
         call. = FALSE)
  }
  invisible(TRUE)
}

run_editorial_requested_analysis_v1 <- function(
    protected_root, output_dir = "outputs/editorial_requested_analysis_v1",
    checkpoint_dir = "data/derived/editorial_requested_analysis_v1/checkpoints",
    code_commit = NA_character_) {
  acknowledgement <- "through_2025_editorial_post_result_v1"
  if (!identical(
      Sys.getenv("EDITORIAL_REQUESTED_ANALYSIS_AUTHORIZED"), acknowledgement)) {
    stop("Exact editorial analysis acknowledgement is required", call. = FALSE)
  }
  packages <- c("data.table", "digest", "lme4", "yaml")
  missing <- packages[!vapply(
    packages, requireNamespace, logical(1L), quietly = TRUE
  )]
  if (length(missing)) {
    stop("Missing packages: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  protected_files <- c(
    event_metadata = file.path(
      protected_root, "stage4a_protected", "stage4a_event_metadata.tsv.gz"
    ),
    source_links = file.path(
      protected_root, "stage3_phase2_protected",
      "metadata_source_point_links.tsv.gz"
    ),
    reported_states = file.path(
      protected_root, "stage4a_protected", "stage4a_reported_states.tsv.gz"
    ),
    ambiguity_masks = file.path(
      protected_root, "stage4a_protected", "stage4a_ambiguity_masks.tsv.gz"
    )
  )
  if (!all(file.exists(protected_files))) {
    stop("Frozen through-2025 protected inputs are unavailable", call. = FALSE)
  }
  expected_hashes <- c(
    event_metadata =
      "03eaccdd46b5cba779f596e7ce96dacd5a509f51f6eae4c5c79daf706879a9b2",
    source_links =
      "f26197d0a71fd177e77774ec9e5596563c127ec8eb0f948042aff51ad805567b",
    reported_states =
      "0f02ac6bdbb561a8e4df58cc8d53340ec29f9519b85a99f4748cb8367fc33cb5",
    ambiguity_masks =
      "c0e063f8a8c6ccfb97535183d8e669a9f4bb1eaea31bae144dffa3d81d57d3ff"
  )
  observed_hashes <- vapply(
    protected_files, editorial_sha256_v1, character(1L)
  )
  if (!identical(observed_hashes, expected_hashes)) {
    stop("EDITORIAL_PROTECTED_INPUT_HASH_GATE: mismatch", call. = FALSE)
  }

  events_all <- .stage4a_read_gz(protected_files[["event_metadata"]])
  if (nrow(events_all) != 239934L ||
      any(as.integer(events_all$checklist_year) > 2025L)) {
    stop("EDITORIAL_THROUGH_2025_EVENT_GATE: failed", call. = FALSE)
  }
  events_all <- .stage4a_prepare_events(events_all)
  selected <- events_all$region == "SoG" &
    events_all$checklist_year >= 2005L &
    events_all$checklist_year <= 2025L
  if (anyNA(selected) || sum(selected) != 217200L) {
    stop("EDITORIAL_SOG_POPULATION_GATE: expected 217200", call. = FALSE)
  }
  events <- events_all[selected, , drop = FALSE]
  rm(events_all)
  if (!all(stage4a_effort_eligible(
      events$protocol, events$duration_minutes,
      events$effort_distance_km, events$observer_count))) {
    stop("EDITORIAL_EFFORT_GATE: failed", call. = FALSE)
  }
  stage4a_validate_folds(events)

  links <- .stage4a_read_gz(protected_files[["source_links"]])
  link_keep <- links$analysis_event_token %in% events$analysis_event_token
  selected_links <- links[link_keep, , drop = FALSE]
  classified <- post_stage4a_classify_links_v1(selected_links)
  classified$herring_source_token <- selected_links$herring_source_token
  classified <- classified[!is.na(classified$term), , drop = FALSE]
  joint <- post_stage4a_add_joint_exposure_v1(events, links)
  events <- joint$events
  rm(links, joint)

  states_all <- .stage4a_read_gz(protected_files[["reported_states"]])
  masks_all <- .stage4a_read_gz(protected_files[["ambiguity_masks"]])
  if (nrow(states_all) != 1169612L || nrow(masks_all) != 5834L) {
    stop("EDITORIAL_SPARSE_STATE_CARDINALITY_GATE: failed", call. = FALSE)
  }
  states <- states_all[
    states_all$analysis_event_token %in% events$analysis_event_token,
    , drop = FALSE
  ]
  masks <- masks_all[
    masks_all$analysis_event_token %in% events$analysis_event_token,
    , drop = FALSE
  ]
  rm(states_all, masks_all)

  support_registry <- utils::read.csv(
    "outputs/stage2_design_lock/species_support_summary.csv",
    stringsAsFactors = FALSE
  )
  species_registry <- utils::read.csv(
    "metadata/canonical_species_registry.csv", stringsAsFactors = FALSE
  )
  core_taxa <- support_registry$analysis_taxon_id[
    support_registry$named_species_recommendation == "named_species_core"
  ]
  if (length(core_taxa) != 49L || anyDuplicated(core_taxa)) {
    stop("EDITORIAL_SPECIES_FAMILY_GATE: expected 49 species", call. = FALSE)
  }
  frozen_effects <- utils::read.csv(
    "outputs/post_stage4a_sog_event_study_v1/effect_estimates_v1.csv",
    stringsAsFactors = FALSE
  )
  frozen_diagnostics <- utils::read.csv(
    "outputs/post_stage4a_sog_event_study_v1/model_diagnostics_v1.csv",
    stringsAsFactors = FALSE
  )
  inventory <- editorial_inventory_v1(
    events, selected_links, data.table::as.data.table(classified),
    core_taxa, frozen_diagnostics
  )
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)
  editorial_write_csv_v1(
    inventory$totals, file.path(output_dir, "verified_dataset_totals.csv")
  )
  editorial_write_csv_v1(
    inventory$support, file.path(output_dir, "period_zone_support.csv")
  )
  editorial_write_csv_v1(
    inventory$link_distribution,
    file.path(output_dir, "event_link_distribution.csv")
  )
  editorial_write_csv_v1(
    editorial_event_block_support_v1(events),
    file.path(output_dir, "event_block_influence_support.csv")
  )

  base_design <- editorial_base_design_v1(events)
  spec_hash <- editorial_sha256_v1(
    "docs/editorial_requested_analysis_spec.md"
  )
  code_hash <- editorial_sha256_v1("R/editorial_requested_analysis_v1.R")
  run_signature <- paste(
    spec_hash, code_hash, observed_hashes, sep = "|", collapse = "|"
  )
  workers <- suppressWarnings(as.integer(Sys.getenv(
    "EDITORIAL_REQUESTED_ANALYSIS_WORKERS", "4"
  )))
  if (is.na(workers) || workers < 1L) workers <- 1L
  workers <- min(workers, length(core_taxa))
  if (workers == 1L) {
    results <- lapply(core_taxa, function(taxon_id) {
      editorial_process_taxon_v1(
        taxon_id, events, states, masks, species_registry, checkpoint_dir,
        run_signature, base_design, frozen_effects, inventory$support
      )
    })
  } else {
    cluster <- parallel::makePSOCKcluster(workers)
    results <- tryCatch({
      library_path <- Sys.getenv("EDITORIAL_R_LIBRARY", "")
      parallel::clusterExport(cluster, "library_path", envir = environment())
      parallel::clusterEvalQ(cluster, {
        if (nzchar(library_path)) .libPaths(c(library_path, .libPaths()))
        Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
        source(file.path("R", "stage4a_core.R"), local = FALSE)
        source(file.path("R", "stage4a_production.R"), local = FALSE)
        source(file.path("R", "post_stage4a_sog_event_study_v1.R"),
               local = FALSE)
        source(file.path("R", "editorial_requested_analysis_v1.R"),
               local = FALSE)
        NULL
      })
      parallel::clusterExport(
        cluster,
        c(
          "events", "states", "masks", "species_registry", "checkpoint_dir",
          "run_signature", "base_design", "frozen_effects", "inventory"
        ),
        envir = environment()
      )
      parallel::parLapply(cluster, core_taxa, function(taxon_id) {
        editorial_process_taxon_v1(
          taxon_id, events, states, masks, species_registry, checkpoint_dir,
          run_signature, base_design, frozen_effects, inventory$support
        )
      })
    }, finally = {
      parallel::stopCluster(cluster)
    })
  }
  names(results) <- core_taxa

  contrasts <- editorial_adjust_bh_v1(
    editorial_flatten_models_v1(results, "contrasts")
  )
  diagnostics <- editorial_flatten_models_v1(results, "diagnostics")
  term_support <- editorial_flatten_models_v1(results, "term_support")
  predictions <- editorial_flatten_models_v1(results, "predictions")
  observed <- do.call(rbind, lapply(results, `[[`, "observed"))
  finite_summary <- do.call(rbind, lapply(results, `[[`, "finite_summary"))
  finite_contrasts <- contrasts[
    contrasts$outcome == "finite_numeric_vs_x", , drop = FALSE
  ]
  primary_contrasts <- contrasts[
    contrasts$outcome != "finite_numeric_vs_x", , drop = FALSE
  ]
  editorial_write_csv_v1(
    primary_contrasts,
    file.path(output_dir, "active_minus_pre_contrasts.csv")
  )
  editorial_write_csv_v1(
    observed, file.path(output_dir, "observed_summaries.csv")
  )
  editorial_write_csv_v1(
    finite_summary, file.path(output_dir, "finite_vs_x_observed_summary.csv")
  )
  editorial_write_csv_v1(
    finite_contrasts, file.path(output_dir, "finite_vs_x_results.csv")
  )
  editorial_write_csv_v1(
    diagnostics, file.path(output_dir, "model_diagnostics.csv")
  )
  editorial_write_csv_v1(
    term_support, file.path(output_dir, "model_term_support.csv")
  )
  editorial_write_csv_v1(
    predictions, file.path(output_dir, "absolute_predictions.csv")
  )

  output_files <- list.files(output_dir, full.names = TRUE)
  editorial_privacy_column_gate_v1(output_files)
  execution <- list(
    analysis_version = "editorial_requested_analysis_v1",
    analysis_status =
      "frozen_post_result_exploratory_refinement_not_preregistered",
    branch = "analysis/editorial-required-analyses",
    base_commit = "c1f1970045274df353c7874b351a58fd0df06fdb",
    frozen_specification_commit = "a0c4ef5",
    code_commit = code_commit,
    executed_at_utc = format(
      as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"
    ),
    eligible_checklists = nrow(events),
    source_herring_events = length(unique(selected_links$herring_source_token)),
    event_blocks = length(unique(events$event_block_token)),
    observer_clusters = length(unique(events$observer_cluster_token)),
    generalized_locations = length(unique(events$location_cluster_token)),
    support_qualified_species = length(core_taxa),
    workers = workers,
    protected_input_hashes = as.list(observed_hashes),
    records_2026_plus_read = 0L,
    protected_rows_released = 0L,
    historical_stage4a_outputs_modified = FALSE,
    frozen_event_study_outputs_modified = FALSE,
    privacy_column_gate = "PASS"
  )
  yaml::write_yaml(execution, file.path(output_dir, "execution_record.yml"))
  output_files <- list.files(output_dir, full.names = TRUE)
  manifest <- data.frame(
    file = gsub("\\\\", "/", output_files),
    sha256 = vapply(output_files, editorial_sha256_v1, character(1L)),
    stringsAsFactors = FALSE
  )
  editorial_write_csv_v1(
    manifest, file.path(output_dir, "output_hash_manifest.csv")
  )
  message("EDITORIAL_REQUESTED_ANALYSIS_GATE=PASS_PENDING_QA_AND_HANDOFF")
  invisible(list(
    contrasts = contrasts,
    diagnostics = diagnostics,
    predictions = predictions,
    observed = observed
  ))
}
