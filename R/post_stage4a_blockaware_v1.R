blockaware_version_v1 <- function() {
  "post_stage4a_blockaware_v1"
}

blockaware_outcomes_v1 <- function() {
  c("checklist_reporting", "conditional_positive_numeric_count")
}

blockaware_analysis_library_v1 <- function() {
  file.path(
    ".analysis-library", "blockaware_v1", "R-4.5", "x86_64-w64-mingw32"
  )
}

blockaware_frozen_library_v1 <- function() {
  file.path("renv", "library", "windows", "R-4.5", "x86_64-w64-mingw32")
}

blockaware_spec_gate_v1 <- function(
    path = "metadata/post_stage4a_blockaware_spec_v1.yml") {
  if (!file.exists(path)) {
    stop("BLOCKAWARE_SPEC_GATE: record unavailable", call. = FALSE)
  }
  spec <- yaml::read_yaml(path)
  approval <- spec$authorization$method_approval_source
  if (
    !identical(spec$specification_version, "post_stage4a_blockaware_spec_v1") ||
      !identical(
        spec$model$replaced_random_effect$to,
        "correlated_intercept_and_one_random_slope"
      ) ||
      !identical(spec$model$replaced_random_effect$slope, "active_minus_pre14") ||
      !identical(
        spec$model$replaced_random_effect$separate_slopes_per_exposure_term,
        "prohibited"
      ) ||
      !identical(spec$model$profile_likelihood_intervals,
                 "prohibited_this_run") ||
      !identical(
        spec$intervals$conditional_positive_numeric_count$primary,
        "kenward_roger"
      ) ||
      !identical(
        spec$intervals$checklist_reporting$cluster_robust_cr0_cr1,
        "prohibited"
      ) ||
      !identical(spec$multiplicity$family_size, 49L) ||
      !identical(
        spec$multiplicity$non_estimable_or_interval_unavailable_p_value, 1L
      ) ||
      !identical(spec$bootstrap$decision, "not_run") ||
      !identical(spec$species_family$number, 49L) ||
      !identical(spec$species_family$subsetting, "prohibited") ||
      !identical(spec$reporting_requirements$convergence_failures,
                 "reported_not_dropped")
  ) {
    stop("BLOCKAWARE_SPEC_GATE: scope mismatch", call. = FALSE)
  }
  if (
    !is.character(approval) ||
      !file.exists(approval) ||
      !identical(
        .post_stage4a_sha256_v1(approval),
        spec$authorization$method_approval_source_sha256
      )
  ) {
    stop("BLOCKAWARE_SPEC_GATE: approved method source hash mismatch",
         call. = FALSE)
  }
  baseline <- spec$reporting_requirements$baseline_tallies
  if (
    !identical(baseline$conditional_positive_numeric_count_fixed49, 19L) ||
      !identical(baseline$checklist_reporting_fixed49_positive_direction, 13L) ||
      !identical(baseline$checklist_reporting_fixed49_negative_direction, 2L)
  ) {
    stop("BLOCKAWARE_SPEC_GATE: baseline tallies mismatch", call. = FALSE)
  }
  invisible(spec)
}

blockaware_library_gate_v1 <- function() {
  analysis_library <- blockaware_analysis_library_v1()
  if (!dir.exists(analysis_library)) {
    stop(
      "BLOCKAWARE_LIBRARY_GATE: versioned analysis library unavailable at ",
      analysis_library,
      call. = FALSE
    )
  }
  normalized <- normalizePath(analysis_library, winslash = "/")
  on_path <- any(normalizePath(.libPaths(), winslash = "/") == normalized)
  if (!on_path) {
    stop("BLOCKAWARE_LIBRARY_GATE: analysis library is not on the search path",
         call. = FALSE)
  }
  required <- c("lme4", "pbkrtest", "lmerTest", "data.table", "digest", "yaml")
  missing <- required[!vapply(
    required, requireNamespace, logical(1L), quietly = TRUE
  )]
  if (length(missing)) {
    stop("BLOCKAWARE_LIBRARY_GATE: missing packages: ",
         paste(missing, collapse = ", "),
         call. = FALSE)
  }
  installed <- utils::installed.packages(lib.loc = normalized)
  manifest <- data.frame(
    package = rownames(installed),
    version = unname(installed[, "Version"]),
    library = "versioned_analysis_library",
    stringsAsFactors = FALSE
  )
  frozen <- utils::installed.packages(
    lib.loc = normalizePath(blockaware_frozen_library_v1(), winslash = "/")
  )
  manifest <- rbind(
    manifest,
    data.frame(
      package = rownames(frozen),
      version = unname(frozen[, "Version"]),
      library = "frozen_renv_project_library",
      stringsAsFactors = FALSE
    )
  )
  manifest <- manifest[order(manifest$package, manifest$library), ]
  rownames(manifest) <- NULL
  manifest
}

blockaware_frozen_library_snapshot_v1 <- function() {
  frozen <- blockaware_frozen_library_v1()
  if (!dir.exists(frozen) || !file.exists("renv.lock")) {
    stop("BLOCKAWARE_FROZEN_LIBRARY_GATE: frozen library unavailable",
         call. = FALSE)
  }
  descriptions <- sort(list.files(
    frozen, pattern = "^DESCRIPTION$", recursive = TRUE, full.names = TRUE
  ))
  c(
    renv_lock = .post_stage4a_sha256_v1("renv.lock"),
    package_descriptions = digest::digest(
      vapply(descriptions, .post_stage4a_sha256_v1, character(1L)),
      algo = "sha256"
    )
  )
}

blockaware_contrast_weights_v1 <- function() {
  staged_refit_s1_contrast_weights_v1()[["active_minus_pre14"]]
}

blockaware_contrast_vector_v1 <- function(fit) {
  .post_stage4a_contrast_vector_v1(
    names(lme4::fixef(fit)), blockaware_contrast_weights_v1()
  )
}

blockaware_empty_interval_v1 <- function(status) {
  list(
    estimate = NA_real_, standard_error = NA_real_, denominator_df = NA_real_,
    conf_low = NA_real_, conf_high = NA_real_, p_value = NA_real_,
    status = status, message = "", seconds = NA_real_
  )
}

blockaware_wald_interval_v1 <- function(fit) {
  started <- Sys.time()
  x <- staged_refit_wald_v1(
    lme4::fixef(fit),
    as.matrix(stats::vcov(fit)),
    blockaware_contrast_weights_v1()
  )
  finite <- is.finite(x[["estimate"]]) &&
    is.finite(x[["standard_error"]]) &&
    x[["standard_error"]] > 0
  list(
    estimate = x[["estimate"]],
    standard_error = x[["standard_error"]],
    denominator_df = Inf,
    conf_low = x[["conf_low"]],
    conf_high = x[["conf_high"]],
    p_value = x[["p_value"]],
    status = if (finite) "completed" else "failed_contrast_geometry",
    message = "",
    seconds = as.numeric(difftime(Sys.time(), started, units = "secs"))
  )
}

blockaware_satterthwaite_interval_v1 <- function(fit) {
  if (!inherits(fit, "lmerMod")) {
    return(blockaware_empty_interval_v1("not_applicable_non_gaussian"))
  }
  if (!inherits(fit, "lmerModLmerTest")) {
    # Deliberately not falling back to as_lmerModLmerTest(): that path needs
    # update(devFunOnly = TRUE), which re-evaluates the recorded data argument
    # in whatever frame happens to be current and fails silently outside the
    # fitting scope. Count models are fitted by lmerTest::lmer so the deviance
    # function and Hessian travel with the object.
    return(blockaware_empty_interval_v1(
      "failed_deviance_function_unavailable"
    ))
  }
  started <- Sys.time()
  L <- blockaware_contrast_vector_v1(fit)
  if (is.null(L)) {
    return(blockaware_empty_interval_v1("failed_contrast_geometry"))
  }
  warnings <- character()
  result <- tryCatch(
    withCallingHandlers(
      lmerTest::contest1D(
        fit, L,
        ddf = "Satterthwaite", confint = TRUE, level = 0.95
      ),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )
  seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  if (inherits(result, "error")) {
    out <- blockaware_empty_interval_v1("failed")
    out$message <- substr(
      gsub("[\r\n]+", " ", conditionMessage(result)), 1L, 240L
    )
    out$seconds <- seconds
    return(out)
  }
  list(
    estimate = result[["Estimate"]],
    standard_error = result[["Std. Error"]],
    denominator_df = result[["df"]],
    conf_low = result[["lower"]],
    conf_high = result[["upper"]],
    p_value = result[["Pr(>|t|)"]],
    status = if (length(warnings)) {
      "completed_with_warning"
    } else {
      "completed"
    },
    message = if (length(warnings)) {
      substr(paste(unique(warnings), collapse = "; "), 1L, 240L)
    } else {
      ""
    },
    seconds = seconds
  )
}

blockaware_kenward_roger_projected_gb_v1 <- function(n) {
  # pbkrtest::vcovAdj forms chol2inv(chol(Sigma)) on the n by n marginal
  # covariance and then holds SigmaInv plus one dense n by n product per
  # variance component. Calibrated against a measured run: n = 8,109 peaked at
  # about 13.1 GB, which is 27 dense double matrices of that order.
  27 * 8 * as.numeric(n)^2 / 1024^3
}

blockaware_kenward_roger_projected_seconds_v1 <- function(n) {
  # Calibrated on two measured Kenward-Roger runs with this random-effect
  # structure: 21.7 s at n = 2,023 and 807.6 s at n = 8,109, an exponent of
  # about 2.6 in n.
  21.7 * (as.numeric(n) / 2023)^2.6
}

blockaware_kenward_roger_interval_v1 <- function(
    fit, maximum_projected_gb = 12) {
  if (!inherits(fit, "lmerMod")) {
    return(blockaware_empty_interval_v1("not_applicable_binomial_glmm"))
  }
  L <- blockaware_contrast_vector_v1(fit)
  if (is.null(L)) {
    return(blockaware_empty_interval_v1("failed_contrast_geometry"))
  }
  n <- lme4::getME(fit, "n")
  projected <- blockaware_kenward_roger_projected_gb_v1(n)
  if (projected > maximum_projected_gb) {
    out <- blockaware_empty_interval_v1(
      "skipped_dense_inverse_memory_infeasible"
    )
    out$message <- sprintf(
      paste(
        "pbkrtest forms a dense %d x %d inverse of the marginal covariance;",
        "projected working set %.1f GB exceeds the %.1f GB budget"
      ),
      n, n, projected, maximum_projected_gb
    )
    return(out)
  }
  started <- Sys.time()
  warnings <- character()
  result <- tryCatch(
    withCallingHandlers(
      {
        # Keep the object pbkrtest returns. vcovAdj carries the P, W and condi
        # attributes that Lb_ddf reads; as.matrix() drops them and Lb_ddf then
        # recurses until the evaluation depth limit, which reads as a generic
        # failure rather than as a stripped argument. Densify only inside the
        # quadratic form.
        adjusted <- pbkrtest::vcovAdj(fit)
        variance <- drop(t(L) %*% as.matrix(adjusted) %*% L)
        denominator_df <- getFromNamespace("Lb_ddf", "pbkrtest")(
          L, stats::vcov(fit), adjusted
        )
        c(variance = variance, denominator_df = denominator_df)
      },
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )
  seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  if (inherits(result, "error")) {
    out <- blockaware_empty_interval_v1("failed")
    out$message <- substr(
      gsub("[\r\n]+", " ", conditionMessage(result)), 1L, 240L
    )
    out$seconds <- seconds
    return(out)
  }
  variance <- result[["variance"]]
  denominator_df <- result[["denominator_df"]]
  if (
    !is.finite(variance) || variance <= 0 ||
      !is.finite(denominator_df) || denominator_df <= 0
  ) {
    out <- blockaware_empty_interval_v1("failed_nonfinite_adjustment")
    out$seconds <- seconds
    return(out)
  }
  estimate <- sum(L * lme4::fixef(fit))
  standard_error <- sqrt(variance)
  quantile <- stats::qt(0.975, df = denominator_df)
  list(
    estimate = estimate,
    standard_error = standard_error,
    denominator_df = denominator_df,
    conf_low = estimate - quantile * standard_error,
    conf_high = estimate + quantile * standard_error,
    p_value = 2 * stats::pt(
      -abs(estimate / standard_error), df = denominator_df
    ),
    status = if (length(warnings)) {
      "completed_with_warning"
    } else {
      "completed"
    },
    message = if (length(warnings)) {
      substr(paste(unique(warnings), collapse = "; "), 1L, 240L)
    } else {
      ""
    },
    seconds = seconds
  )
}

blockaware_variance_components_v1 <- function(fit) {
  variance <- as.data.frame(lme4::VarCorr(fit))
  pick <- function(group, variable) {
    value <- variance$vcov[
      variance$grp == group &
        !is.na(variance$var1) &
        variance$var1 == variable &
        is.na(variance$var2)
    ]
    if (length(value) == 1L) value[[1L]] else NA_real_
  }
  residual <- variance$vcov[
    variance$grp == "Residual" & is.na(variance$var1)
  ]
  correlation <- variance$sdcor[
    variance$grp == "event_block_token" &
      !is.na(variance$var2) &
      variance$var1 == "(Intercept)" &
      variance$var2 == "block_active_minus_pre14"
  ]
  list(
    event_block_intercept_variance =
      pick("event_block_token", "(Intercept)"),
    event_block_slope_variance =
      pick("event_block_token", "block_active_minus_pre14"),
    event_block_intercept_slope_correlation =
      if (length(correlation) == 1L) correlation[[1L]] else NA_real_,
    observer_variance = pick("observer_cluster_token", "(Intercept)"),
    location_variance = pick("location_cluster_token", "(Intercept)"),
    residual_variance = if (length(residual) == 1L) residual[[1L]] else NA_real_
  )
}

blockaware_model_frame_v1 <- function(dat, outcome) {
  if (outcome == "checklist_reporting") {
    use <- !is.na(dat$detection)
    dat$model_response <- dat$detection
  } else if (outcome == "conditional_positive_numeric_count") {
    use <- is.finite(dat$numeric_count) & dat$numeric_count > 0
    dat$model_response <- log(dat$numeric_count)
  } else {
    stop("BLOCKAWARE_OUTCOME_GATE: unsupported outcome", call. = FALSE)
  }
  d <- dat[use, , drop = FALSE]
  stage2_block_slope_add_predictor_v1(d)
}

blockaware_support_v1 <- function(d) {
  terms <- post_stage4a_exposure_terms_v1()
  exposed <- vapply(terms, function(term) sum(d[[term]] > 0L), integer(1L))
  grouping_levels <- c(
    event_block = length(unique(d$event_block_token)),
    observer = length(unique(d$observer_cluster_token)),
    location = length(unique(d$location_cluster_token))
  )
  list(
    sufficient = nrow(d) >= 20L &&
      length(unique(d$model_response)) >= 2L &&
      all(exposed >= 20L) &&
      all(grouping_levels >= 2L),
    event_blocks = grouping_levels[["event_block"]]
  )
}

blockaware_fit_v1 <- function(d, outcome) {
  formula <- stage2_block_slope_formula_v1("model_response")
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
    # lmerTest::lmer is lme4::lmer plus the stored deviance function and
    # Hessian that the Satterthwaite denominator correction needs. Verified on
    # three species that the fixed effects and every variance component are
    # identical to lme4::lmer under the same control settings.
    lmerTest::lmer(
      formula,
      data = d,
      REML = TRUE,
      control = lme4::lmerControl(
        optimizer = "nloptwrap",
        calc.derivs = TRUE,
        optCtrl = list(maxeval = 10000L)
      )
    )
  }
}

blockaware_empty_row_v1 <- function(taxon_id, species, outcome, n, status) {
  interval <- blockaware_empty_interval_v1("not_attempted")
  data.frame(
    analysis_version = blockaware_version_v1(),
    analysis_taxon_id = taxon_id,
    species = species,
    outcome = outcome,
    comparison = "active_minus_pre14",
    engine = if (outcome == "conditional_positive_numeric_count") {
      "lmerTest_lmer_REML_random_slope"
    } else {
      "lme4_glmer_nAGQ0_random_slope"
    },
    n = .post_stage4a_release_count_v1(n),
    event_blocks_in_model = NA_integer_,
    estimate = NA_real_,
    wald_standard_error = NA_real_,
    wald_conf_low = NA_real_,
    wald_conf_high = NA_real_,
    wald_p_value = NA_real_,
    wald_status = interval$status,
    satterthwaite_standard_error = NA_real_,
    satterthwaite_df = NA_real_,
    satterthwaite_conf_low = NA_real_,
    satterthwaite_conf_high = NA_real_,
    satterthwaite_p_value = NA_real_,
    satterthwaite_status = interval$status,
    satterthwaite_message = "",
    kenward_roger_standard_error = NA_real_,
    kenward_roger_df = NA_real_,
    kenward_roger_conf_low = NA_real_,
    kenward_roger_conf_high = NA_real_,
    kenward_roger_p_value = NA_real_,
    kenward_roger_status = interval$status,
    kenward_roger_message = "",
    kenward_roger_projected_dense_gb = NA_real_,
    converged = FALSE,
    singular_fit = NA,
    rank_deficient = NA,
    convergence_message = status,
    maximum_absolute_gradient = NA_real_,
    status = status,
    fit_seconds = NA_real_,
    interval_seconds = NA_real_,
    stringsAsFactors = FALSE
  )
}

blockaware_empty_variance_row_v1 <- function(
    taxon_id, species, outcome, n, status) {
  data.frame(
    analysis_version = blockaware_version_v1(),
    analysis_taxon_id = taxon_id,
    species = species,
    outcome = outcome,
    n = .post_stage4a_release_count_v1(n),
    event_blocks_in_model = NA_integer_,
    event_block_intercept_variance = NA_real_,
    event_block_slope_variance = NA_real_,
    event_block_slope_sd = NA_real_,
    event_block_intercept_slope_correlation = NA_real_,
    observer_variance = NA_real_,
    location_variance = NA_real_,
    residual_variance = NA_real_,
    slope_variance_over_residual_variance = NA_real_,
    slope_sd_multiplicative_spread_low = NA_real_,
    slope_sd_multiplicative_spread_high = NA_real_,
    converged = FALSE,
    singular_fit = NA,
    status = status,
    stringsAsFactors = FALSE
  )
}

blockaware_kenward_roger_row_cap_v1 <- function(budget_gb) {
  floor(sqrt(budget_gb * 1024^3 / (27 * 8)))
}

blockaware_fit_component_v1 <- function(
    dat, taxon_id, species, outcome, checkpoint_path, cache_signature,
    kenward_roger_budget_gb = 0, compute_kenward_roger = FALSE) {
  if (file.exists(checkpoint_path)) {
    cached <- readRDS(checkpoint_path)
    if (identical(cached$cache_signature, cache_signature)) {
      return(cached$result)
    }
  }
  d <- blockaware_model_frame_v1(dat, outcome)
  support <- blockaware_support_v1(d)
  if (!support$sufficient) {
    result <- list(
      estimates = blockaware_empty_row_v1(
        taxon_id, species, outcome, nrow(d), "failed_insufficient_support"
      ),
      variances = blockaware_empty_variance_row_v1(
        taxon_id, species, outcome, nrow(d), "failed_insufficient_support"
      )
    )
    saveRDS(
      list(cache_signature = cache_signature, result = result),
      checkpoint_path
    )
    return(result)
  }

  fit_started <- Sys.time()
  fit <- try(blockaware_fit_v1(d, outcome), silent = TRUE)
  fit_seconds <- as.numeric(difftime(Sys.time(), fit_started, units = "secs"))
  if (inherits(fit, "try-error")) {
    result <- list(
      estimates = blockaware_empty_row_v1(
        taxon_id, species, outcome, nrow(d),
        "failed_numerical_fit_no_fallback"
      ),
      variances = blockaware_empty_variance_row_v1(
        taxon_id, species, outcome, nrow(d),
        "failed_numerical_fit_no_fallback"
      )
    )
    result$estimates$convergence_message <- substr(
      gsub("[\r\n]+", " ", as.character(fit)), 1L, 240L
    )
    result$estimates$fit_seconds <- fit_seconds
    saveRDS(
      list(cache_signature = cache_signature, result = result),
      checkpoint_path
    )
    return(result)
  }

  singular <- lme4::isSingular(fit, tol = 1e-4)
  optimizer_code <- fit@optinfo$conv$opt
  classification <- .post_stage4a_model_messages_v1(
    optimizer_code, fit@optinfo$conv$lme4$messages, singular
  )
  rank_deficient <- length(lme4::fixef(fit)) < ncol(stats::model.matrix(
    lme4::nobars(stage2_block_slope_formula_v1("model_response")), d
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

  interval_started <- Sys.time()
  wald <- blockaware_wald_interval_v1(fit)
  satterthwaite <- blockaware_satterthwaite_interval_v1(fit)
  kenward_roger <- if (compute_kenward_roger) {
    blockaware_kenward_roger_interval_v1(
      fit, maximum_projected_gb = kenward_roger_budget_gb
    )
  } else if (inherits(fit, "lmerMod")) {
    blockaware_empty_interval_v1("deferred_to_serial_kenward_roger_pass")
  } else {
    blockaware_empty_interval_v1("not_applicable_binomial_glmm")
  }
  interval_seconds <- as.numeric(
    difftime(Sys.time(), interval_started, units = "secs")
  )
  components <- blockaware_variance_components_v1(fit)
  gradients <- fit@optinfo$derivs$gradient
  slope_sd <- sqrt(components$event_block_slope_variance)

  estimates <- data.frame(
    analysis_version = blockaware_version_v1(),
    analysis_taxon_id = taxon_id,
    species = species,
    outcome = outcome,
    comparison = "active_minus_pre14",
    engine = if (outcome == "conditional_positive_numeric_count") {
      "lmerTest_lmer_REML_random_slope"
    } else {
      "lme4_glmer_nAGQ0_random_slope"
    },
    n = .post_stage4a_release_count_v1(nrow(d)),
    event_blocks_in_model = support$event_blocks,
    estimate = wald$estimate,
    wald_standard_error = wald$standard_error,
    wald_conf_low = wald$conf_low,
    wald_conf_high = wald$conf_high,
    wald_p_value = wald$p_value,
    wald_status = wald$status,
    satterthwaite_standard_error = satterthwaite$standard_error,
    satterthwaite_df = satterthwaite$denominator_df,
    satterthwaite_conf_low = satterthwaite$conf_low,
    satterthwaite_conf_high = satterthwaite$conf_high,
    satterthwaite_p_value = satterthwaite$p_value,
    satterthwaite_status = satterthwaite$status,
    satterthwaite_message = satterthwaite$message,
    kenward_roger_standard_error = kenward_roger$standard_error,
    kenward_roger_df = kenward_roger$denominator_df,
    kenward_roger_conf_low = kenward_roger$conf_low,
    kenward_roger_conf_high = kenward_roger$conf_high,
    kenward_roger_p_value = kenward_roger$p_value,
    kenward_roger_status = kenward_roger$status,
    kenward_roger_message = kenward_roger$message,
    kenward_roger_projected_dense_gb =
      blockaware_kenward_roger_projected_gb_v1(nrow(d)),
    converged = classification$converged,
    singular_fit = singular,
    rank_deficient = rank_deficient,
    convergence_message = classification$message,
    maximum_absolute_gradient = if (is.null(gradients)) {
      NA_real_
    } else {
      max(abs(gradients))
    },
    status = status,
    fit_seconds = fit_seconds,
    interval_seconds = interval_seconds,
    stringsAsFactors = FALSE
  )
  variances <- data.frame(
    analysis_version = blockaware_version_v1(),
    analysis_taxon_id = taxon_id,
    species = species,
    outcome = outcome,
    n = .post_stage4a_release_count_v1(nrow(d)),
    event_blocks_in_model = support$event_blocks,
    event_block_intercept_variance = components$event_block_intercept_variance,
    event_block_slope_variance = components$event_block_slope_variance,
    event_block_slope_sd = slope_sd,
    event_block_intercept_slope_correlation =
      components$event_block_intercept_slope_correlation,
    observer_variance = components$observer_variance,
    location_variance = components$location_variance,
    residual_variance = components$residual_variance,
    slope_variance_over_residual_variance =
      components$event_block_slope_variance / components$residual_variance,
    slope_sd_multiplicative_spread_low = exp(wald$estimate - slope_sd),
    slope_sd_multiplicative_spread_high = exp(wald$estimate + slope_sd),
    converged = classification$converged,
    singular_fit = singular,
    status = status,
    stringsAsFactors = FALSE
  )
  result <- list(estimates = estimates, variances = variances)
  saveRDS(
    list(cache_signature = cache_signature, result = result),
    checkpoint_path
  )
  result
}

blockaware_species_label_v1 <- function(taxon_id, species_registry) {
  species <- species_registry$common_name[
    match(taxon_id, species_registry$analysis_taxon_id)
  ]
  if (length(species) != 1L || is.na(species) || !nzchar(species)) {
    stop("BLOCKAWARE_TAXON_GATE: unresolved core taxon", call. = FALSE)
  }
  species
}

blockaware_process_taxon_v1 <- function(
    taxon_id, events, states, masks, species_registry, checkpoint_dir,
    run_signature) {
  species <- blockaware_species_label_v1(taxon_id, species_registry)
  dat <- stage4a_materialize_taxon(events, states, masks, taxon_id)
  results <- lapply(blockaware_outcomes_v1(), function(outcome) {
    blockaware_fit_component_v1(
      dat, taxon_id, species, outcome,
      file.path(checkpoint_dir, paste(taxon_id, outcome, "rds", sep = "_")),
      paste(run_signature, taxon_id, outcome, sep = "|"),
      kenward_roger_budget_gb = 0,
      compute_kenward_roger = FALSE
    )
  })
  names(results) <- blockaware_outcomes_v1()
  results
}

blockaware_parallel_v1 <- function(
    taxa, events, states, masks, species_registry, checkpoint_dir,
    run_signature, workers) {
  if (!length(taxa)) return(list())
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(checkpoint_dir)) {
    stop("BLOCKAWARE_CHECKPOINT_GATE: directory unavailable", call. = FALSE)
  }
  workers <- min(as.integer(workers), length(taxa))
  fit_one <- function(taxon_id) {
    blockaware_process_taxon_v1(
      taxon_id, events, states, masks, species_registry, checkpoint_dir,
      run_signature
    )
  }
  if (workers <= 1L) {
    out <- lapply(taxa, fit_one)
    names(out) <- taxa
    return(out)
  }
  library_paths <- .libPaths()
  cluster <- parallel::makePSOCKcluster(workers)
  out <- tryCatch({
    parallel::clusterExport(cluster, "library_paths", envir = environment())
    parallel::clusterEvalQ(cluster, {
      Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
      .libPaths(library_paths)
      source(file.path("R", "stage4a_core.R"), local = FALSE)
      source(file.path("R", "stage4a_production.R"), local = FALSE)
      source(file.path("R", "post_stage4a_sog_event_study_v1.R"), local = FALSE)
      source(
        file.path("R", "post_stage4a_distance_band_sensitivity_v2.R"),
        local = FALSE
      )
      source(file.path("R", "post_stage4a_staged_refit_v1.R"), local = FALSE)
      source(
        file.path("R", "post_stage4a_staged_refit_amendment_v1.R"),
        local = FALSE
      )
      source(
        file.path("R", "post_stage4a_staged_refit_stage2_v1.R"),
        local = FALSE
      )
      source(
        file.path("R", "post_stage4a_stage2_block_slope_diagnostic_v1.R"),
        local = FALSE
      )
      source(file.path("R", "post_stage4a_blockaware_v1.R"), local = FALSE)
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
      blockaware_process_taxon_v1(
        taxon_id, events, states, masks, species_registry, checkpoint_dir,
        run_signature
      )
    })
  }, finally = {
    parallel::stopCluster(cluster)
  })
  names(out) <- taxa
  out
}

blockaware_kenward_roger_pass_v1 <- function(
    estimates, events, states, masks, species_registry, checkpoint_dir,
    run_signature, kenward_roger_budget_gb) {
  # Kenward-Roger runs serially and after the parallel fitting pass.
  # pbkrtest inverts the n by n marginal covariance densely, so two workers
  # doing this at once would multiply an already multi-gigabyte working set.
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)
  row_cap <- blockaware_kenward_roger_row_cap_v1(kenward_roger_budget_gb)
  candidates <- estimates[
    estimates$outcome == "conditional_positive_numeric_count" &
      is.finite(estimates$n) &
      estimates$status != "failed_insufficient_support" &
      estimates$status != "failed_numerical_fit_no_fallback",
    ,
    drop = FALSE
  ]
  message(
    "BLOCKAWARE_KR_PASS_START candidates=", nrow(candidates),
    " row_cap=", row_cap, " budget_gb=", kenward_roger_budget_gb
  )
  rows <- lapply(seq_len(nrow(candidates)), function(index) {
    taxon_id <- candidates$analysis_taxon_id[[index]]
    species <- candidates$species[[index]]
    n <- candidates$n[[index]]
    projected <- blockaware_kenward_roger_projected_gb_v1(n)
    template <- data.frame(
      analysis_taxon_id = taxon_id,
      outcome = "conditional_positive_numeric_count",
      kenward_roger_standard_error = NA_real_,
      kenward_roger_df = NA_real_,
      kenward_roger_conf_low = NA_real_,
      kenward_roger_conf_high = NA_real_,
      kenward_roger_p_value = NA_real_,
      kenward_roger_status = "skipped_dense_inverse_memory_infeasible",
      kenward_roger_message = sprintf(
        paste(
          "pbkrtest forms a dense %d by %d inverse of the marginal",
          "covariance; projected working set %.1f GB exceeds the %.1f GB",
          "budget (row cap %d)"
        ),
        n, n, projected, kenward_roger_budget_gb, row_cap
      ),
      kenward_roger_seconds = NA_real_,
      stringsAsFactors = FALSE
    )
    if (n > row_cap) {
      message(sprintf(
        "BLOCKAWARE_KR_SKIP %s n=%d projected=%.1f GB", species, n, projected
      ))
      return(template)
    }
    checkpoint_path <- file.path(
      checkpoint_dir, paste0(taxon_id, "_kenward_roger.rds")
    )
    cache_signature <- paste(
      run_signature, taxon_id, sprintf("cap=%d", row_cap), sep = "|"
    )
    if (file.exists(checkpoint_path)) {
      cached <- readRDS(checkpoint_path)
      if (identical(cached$cache_signature, cache_signature)) {
        return(cached$result)
      }
    }
    message(sprintf(
      "BLOCKAWARE_KR_START %s n=%d projected=%.1f GB", species, n, projected
    ))
    started <- Sys.time()
    result <- try(
      {
        dat <- blockaware_model_frame_v1(
          stage4a_materialize_taxon(events, states, masks, taxon_id),
          "conditional_positive_numeric_count"
        )
        fit <- blockaware_fit_v1(dat, "conditional_positive_numeric_count")
        blockaware_kenward_roger_interval_v1(
          fit, maximum_projected_gb = kenward_roger_budget_gb
        )
      },
      silent = TRUE
    )
    seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))
    if (inherits(result, "try-error")) {
      template$kenward_roger_status <- "failed"
      template$kenward_roger_message <- substr(
        gsub("[\r\n]+", " ", as.character(result)), 1L, 240L
      )
      template$kenward_roger_seconds <- seconds
      message(sprintf("BLOCKAWARE_KR_FAIL %s %.1f s", species, seconds))
    } else {
      template$kenward_roger_standard_error <- result$standard_error
      template$kenward_roger_df <- result$denominator_df
      template$kenward_roger_conf_low <- result$conf_low
      template$kenward_roger_conf_high <- result$conf_high
      template$kenward_roger_p_value <- result$p_value
      template$kenward_roger_status <- result$status
      template$kenward_roger_message <- result$message
      template$kenward_roger_seconds <- seconds
      message(sprintf(
        "BLOCKAWARE_KR_DONE %s status=%s df=%s %.1f s",
        species, result$status, signif(result$denominator_df, 5), seconds
      ))
    }
    saveRDS(
      list(cache_signature = cache_signature, result = template),
      checkpoint_path
    )
    gc()
    template
  })
  if (!length(rows)) return(NULL)
  do.call(rbind, rows)
}

blockaware_merge_kenward_roger_v1 <- function(estimates, kenward_roger) {
  estimates$kenward_roger_seconds <- NA_real_
  if (is.null(kenward_roger) || !nrow(kenward_roger)) return(estimates)
  index <- match(
    paste(kenward_roger$analysis_taxon_id, kenward_roger$outcome, sep = "\r"),
    paste(estimates$analysis_taxon_id, estimates$outcome, sep = "\r")
  )
  if (anyNA(index) || anyDuplicated(index)) {
    stop("BLOCKAWARE_KR_MERGE_GATE: unmatched Kenward-Roger rows",
         call. = FALSE)
  }
  for (column in c(
    "kenward_roger_standard_error", "kenward_roger_df",
    "kenward_roger_conf_low", "kenward_roger_conf_high",
    "kenward_roger_p_value", "kenward_roger_status",
    "kenward_roger_message", "kenward_roger_seconds"
  )) {
    estimates[[column]][index] <- kenward_roger[[column]]
  }
  deferred <- estimates$kenward_roger_status ==
    "deferred_to_serial_kenward_roger_pass"
  if (any(deferred)) {
    estimates$kenward_roger_status[deferred] <-
      "not_attempted_model_not_estimable"
  }
  estimates
}

blockaware_primary_interval_v1 <- function(estimates) {
  method <- rep("none", nrow(estimates))
  standard_error <- rep(NA_real_, nrow(estimates))
  denominator_df <- rep(NA_real_, nrow(estimates))
  conf_low <- rep(NA_real_, nrow(estimates))
  conf_high <- rep(NA_real_, nrow(estimates))
  p_value <- rep(NA_real_, nrow(estimates))
  usable <- function(status, p) {
    !is.na(status) &&
      status %in% c("completed", "completed_with_warning") &&
      is.finite(p)
  }
  for (i in seq_len(nrow(estimates))) {
    row <- estimates[i, , drop = FALSE]
    if (
      row$outcome == "conditional_positive_numeric_count" &&
        usable(row$kenward_roger_status, row$kenward_roger_p_value)
    ) {
      method[[i]] <- "kenward_roger"
      standard_error[[i]] <- row$kenward_roger_standard_error
      denominator_df[[i]] <- row$kenward_roger_df
      conf_low[[i]] <- row$kenward_roger_conf_low
      conf_high[[i]] <- row$kenward_roger_conf_high
      p_value[[i]] <- row$kenward_roger_p_value
    } else if (
      row$outcome == "conditional_positive_numeric_count" &&
        usable(row$satterthwaite_status, row$satterthwaite_p_value)
    ) {
      method[[i]] <- "satterthwaite_denominator_df"
      standard_error[[i]] <- row$satterthwaite_standard_error
      denominator_df[[i]] <- row$satterthwaite_df
      conf_low[[i]] <- row$satterthwaite_conf_low
      conf_high[[i]] <- row$satterthwaite_conf_high
      p_value[[i]] <- row$satterthwaite_p_value
    } else if (usable(row$wald_status, row$wald_p_value)) {
      method[[i]] <- "wald"
      standard_error[[i]] <- row$wald_standard_error
      denominator_df[[i]] <- Inf
      conf_low[[i]] <- row$wald_conf_low
      conf_high[[i]] <- row$wald_conf_high
      p_value[[i]] <- row$wald_p_value
    }
  }
  estimates$primary_interval_method <- method
  estimates$primary_standard_error <- standard_error
  estimates$primary_denominator_df <- denominator_df
  estimates$primary_conf_low <- conf_low
  estimates$primary_conf_high <- conf_high
  estimates$primary_p_value <- p_value
  estimates$inference_strength_label <- ifelse(
    estimates$outcome == "checklist_reporting",
    "weaker: prespecified Wald on the random-slope binomial fit",
    ifelse(
      method == "kenward_roger",
      "stronger: Kenward-Roger adjusted standard error and denominator df",
      ifelse(
        method == "satterthwaite_denominator_df",
        paste(
          "intermediate: Satterthwaite denominator df, standard error not",
          "Kenward-Roger adjusted"
        ),
        "weaker: Wald only"
      )
    )
  )
  estimates$ratio <- exp(estimates$estimate)
  estimates$ratio_conf_low <- exp(estimates$primary_conf_low)
  estimates$ratio_conf_high <- exp(estimates$primary_conf_high)
  estimates$direction <- ifelse(
    !is.finite(estimates$estimate), NA_character_,
    ifelse(estimates$estimate > 0, "positive", "negative")
  )
  estimates
}

blockaware_bh_fixed49_v1 <- function(p_values, family_size = 49L) {
  if (length(p_values) != family_size) {
    stop("BLOCKAWARE_BH_GATE: family size changed", call. = FALSE)
  }
  substituted <- ifelse(is.finite(p_values), p_values, 1)
  stats::p.adjust(substituted, method = "BH")
}

blockaware_add_multiplicity_v1 <- function(estimates) {
  estimates$multiplicity_family <- NA_character_
  estimates$q_value_bh_fixed49 <- NA_real_
  estimates$q_value_bh_fixed49_satterthwaite <- NA_real_
  estimates$q_value_bh_fixed49_wald <- NA_real_
  estimates$q_value_bh_estimable_only <- NA_real_
  for (outcome in unique(estimates$outcome)) {
    index <- which(estimates$outcome == outcome)
    if (length(index) != 49L) {
      stop("BLOCKAWARE_BH_GATE: expected 49 species per outcome",
           call. = FALSE)
    }
    estimates$q_value_bh_fixed49[index] <-
      blockaware_bh_fixed49_v1(estimates$primary_p_value[index])
    satterthwaite <- if (
      outcome == "conditional_positive_numeric_count"
    ) {
      estimates$satterthwaite_p_value[index]
    } else {
      estimates$wald_p_value[index]
    }
    estimates$q_value_bh_fixed49_satterthwaite[index] <-
      blockaware_bh_fixed49_v1(satterthwaite)
    estimates$q_value_bh_fixed49_wald[index] <-
      blockaware_bh_fixed49_v1(estimates$wald_p_value[index])
    estimable <- index[is.finite(estimates$primary_p_value[index])]
    estimates$q_value_bh_estimable_only[estimable] <- stats::p.adjust(
      estimates$primary_p_value[estimable], method = "BH"
    )
    estimates$multiplicity_family[index] <- paste0(
      "blockaware_random_slope__fixed_49_species__", outcome
    )
  }
  estimates$significant_bh_fixed49 <-
    is.finite(estimates$q_value_bh_fixed49) &
      estimates$q_value_bh_fixed49 < 0.05
  estimates
}

blockaware_stage2_baseline_v1 <- function(
    path = file.path(
      "outputs", "post_stage4a_staged_refit_stage2_v1", "s2_detectability",
      "estimates_49x2.csv"
    )) {
  stage2 <- utils::read.csv(path, stringsAsFactors = FALSE)
  stage2 <- stage2[stage2$comparison == "active_minus_pre14", , drop = FALSE]
  if (
    nrow(stage2) != 98L ||
      anyDuplicated(paste(stage2$analysis_taxon_id, stage2$outcome, sep = "\r"))
  ) {
    stop("BLOCKAWARE_STAGE2_GATE: Stage 2 family changed", call. = FALSE)
  }
  stage2$q_value_bh_fixed49 <- NA_real_
  for (outcome in unique(stage2$outcome)) {
    index <- which(stage2$outcome == outcome)
    stage2$q_value_bh_fixed49[index] <-
      blockaware_bh_fixed49_v1(stage2$p_value[index])
  }
  stage2$significant_bh_fixed49 <-
    is.finite(stage2$q_value_bh_fixed49) & stage2$q_value_bh_fixed49 < 0.05
  stage2
}

blockaware_counterfactual_p_v1 <- function(estimate, standard_error, df) {
  # df may be supplied as a scalar; recycle explicitly rather than relying on
  # ifelse, which takes its length from the condition and would otherwise
  # collapse the whole family to one species' p-value.
  length_out <- max(length(estimate), length(standard_error), length(df))
  estimate <- rep_len(estimate, length_out)
  standard_error <- rep_len(standard_error, length_out)
  df <- rep_len(df, length_out)
  out <- rep(NA_real_, length_out)
  usable <- is.finite(estimate) &
    is.finite(standard_error) &
    standard_error > 0
  if (!any(usable)) return(out)
  statistic <- abs(estimate[usable] / standard_error[usable])
  degrees <- df[usable]
  degrees[!(is.finite(degrees) & degrees > 0)] <- Inf
  out[usable] <- 2 * stats::pt(-statistic, df = degrees)
  out
}

blockaware_vs_stage2_v1 <- function(estimates, stage2) {
  key_new <- paste(estimates$analysis_taxon_id, estimates$outcome, sep = "\r")
  key_old <- paste(stage2$analysis_taxon_id, stage2$outcome, sep = "\r")
  index <- match(key_new, key_old)
  if (length(key_new) != 98L || anyNA(index) || anyDuplicated(key_new)) {
    stop("BLOCKAWARE_COMPARISON_GATE: one-to-one join to Stage 2 failed",
         call. = FALSE)
  }
  old <- stage2[index, , drop = FALSE]
  comparison <- data.frame(
    analysis_version = blockaware_version_v1(),
    analysis_taxon_id = estimates$analysis_taxon_id,
    species = estimates$species,
    outcome = estimates$outcome,
    comparison = "active_minus_pre14",
    stage2_estimate = old$estimate,
    blockaware_estimate = estimates$estimate,
    estimate_shift = estimates$estimate - old$estimate,
    percent_shift_in_log_effect = 100 *
      (estimates$estimate - old$estimate) / abs(old$estimate),
    stage2_ratio = old$ratio,
    blockaware_ratio = estimates$ratio,
    stage2_standard_error = old$standard_error,
    blockaware_primary_standard_error = estimates$primary_standard_error,
    standard_error_ratio =
      estimates$primary_standard_error / old$standard_error,
    stage2_interval_width = old$conf_high - old$conf_low,
    blockaware_interval_width =
      estimates$primary_conf_high - estimates$primary_conf_low,
    interval_width_ratio =
      (estimates$primary_conf_high - estimates$primary_conf_low) /
        (old$conf_high - old$conf_low),
    blockaware_primary_interval_method = estimates$primary_interval_method,
    blockaware_primary_denominator_df = estimates$primary_denominator_df,
    stage2_p_value = old$p_value,
    blockaware_p_value = estimates$primary_p_value,
    stage2_q_value_bh_fixed49 = old$q_value_bh_fixed49,
    blockaware_q_value_bh_fixed49 = estimates$q_value_bh_fixed49,
    stage2_significant_bh_fixed49 = old$significant_bh_fixed49,
    blockaware_significant_bh_fixed49 = estimates$significant_bh_fixed49,
    stage2_status = old$status,
    blockaware_status = estimates$status,
    stringsAsFactors = FALSE
  )
  comparison$bh_change <- ifelse(
    comparison$stage2_significant_bh_fixed49 &
      !comparison$blockaware_significant_bh_fixed49,
    "left_bh",
    ifelse(
      !comparison$stage2_significant_bh_fixed49 &
        comparison$blockaware_significant_bh_fixed49,
      "entered_bh",
      ifelse(
        comparison$stage2_significant_bh_fixed49,
        "retained_bh",
        "absent_from_bh_in_both"
      )
    )
  )

  widening_only <- rep(NA_real_, nrow(comparison))
  movement_only <- rep(NA_real_, nrow(comparison))
  for (outcome in unique(comparison$outcome)) {
    index <- which(comparison$outcome == outcome)
    widening_p <- blockaware_counterfactual_p_v1(
      comparison$stage2_estimate[index],
      comparison$blockaware_primary_standard_error[index],
      comparison$blockaware_primary_denominator_df[index]
    )
    movement_p <- blockaware_counterfactual_p_v1(
      comparison$blockaware_estimate[index],
      comparison$stage2_standard_error[index],
      Inf
    )
    widening_only[index] <- blockaware_bh_fixed49_v1(widening_p)
    movement_only[index] <- blockaware_bh_fixed49_v1(movement_p)
  }
  comparison$q_value_widening_only_counterfactual <- widening_only
  comparison$q_value_point_movement_only_counterfactual <- movement_only
  comparison$survives_bh_widening_only <- widening_only < 0.05
  comparison$survives_bh_point_movement_only <- movement_only < 0.05
  comparison$mechanism <- ifelse(
    comparison$bh_change != "left_bh",
    "not_applicable",
    ifelse(
      is.na(comparison$survives_bh_widening_only) |
        is.na(comparison$survives_bh_point_movement_only),
      "blockaware_model_not_estimable",
    ifelse(
      !comparison$survives_bh_widening_only &
        comparison$survives_bh_point_movement_only,
      "interval_widening",
      ifelse(
        comparison$survives_bh_widening_only &
          !comparison$survives_bh_point_movement_only,
        "point_estimate_movement",
        ifelse(
          !comparison$survives_bh_widening_only &
            !comparison$survives_bh_point_movement_only,
          "both_widening_and_point_movement",
          "neither_alone_sufficient_joint_effect_only"
        )
      )
    )
    )
  )
  comparison$mechanism_rule <- paste(
    "counterfactual Benjamini-Hochberg over the same fixed 49-species family:",
    "widening_only uses the Stage 2 point estimate with the block-aware",
    "standard error and denominator df; point_movement_only uses the",
    "block-aware point estimate with the Stage 2 standard error"
  )
  comparison
}

blockaware_bh_changes_v1 <- function(comparison) {
  changed <- comparison[
    comparison$bh_change %in% c("left_bh", "entered_bh"),
    c(
      "analysis_version", "species", "outcome", "bh_change",
      "stage2_estimate", "blockaware_estimate", "estimate_shift",
      "percent_shift_in_log_effect", "stage2_q_value_bh_fixed49",
      "blockaware_q_value_bh_fixed49", "interval_width_ratio",
      "blockaware_primary_interval_method",
      "survives_bh_widening_only", "survives_bh_point_movement_only",
      "mechanism", "mechanism_rule", "blockaware_status"
    ),
    drop = FALSE
  ]
  changed[order(changed$outcome, changed$bh_change, changed$species), ,
          drop = FALSE]
}

blockaware_tallies_v1 <- function(estimates, spec) {
  baseline <- spec$reporting_requirements$baseline_tallies
  rows <- lapply(unique(estimates$outcome), function(outcome) {
    d <- estimates[estimates$outcome == outcome, , drop = FALSE]
    hit <- d$significant_bh_fixed49
    positive <- sum(hit & d$direction == "positive", na.rm = TRUE)
    negative <- sum(hit & d$direction == "negative", na.rm = TRUE)
    stage2_positive <- if (outcome == "checklist_reporting") {
      baseline$checklist_reporting_fixed49_positive_direction
    } else {
      baseline$conditional_positive_numeric_count_fixed49
    }
    stage2_negative <- if (outcome == "checklist_reporting") {
      baseline$checklist_reporting_fixed49_negative_direction
    } else {
      0L
    }
    data.frame(
      analysis_version = blockaware_version_v1(),
      outcome = outcome,
      multiplicity_family_size = nrow(d),
      estimable_models = sum(is.finite(d$primary_p_value)),
      non_estimable_models_assigned_p1 = sum(!is.finite(d$primary_p_value)),
      stage2_fixed49_positive = stage2_positive,
      stage2_fixed49_negative = stage2_negative,
      blockaware_fixed49_positive = positive,
      blockaware_fixed49_negative = negative,
      blockaware_fixed49_total = sum(hit),
      change_in_positive_direction = positive - stage2_positive,
      uniform_satterthwaite_or_wald_positive = sum(
        is.finite(d$q_value_bh_fixed49_satterthwaite) &
          d$q_value_bh_fixed49_satterthwaite < 0.05 &
          d$direction == "positive",
        na.rm = TRUE
      ),
      uniform_wald_positive = sum(
        is.finite(d$q_value_bh_fixed49_wald) &
          d$q_value_bh_fixed49_wald < 0.05 &
          d$direction == "positive",
        na.rm = TRUE
      ),
      convergence_failures = sum(!d$converged %in% TRUE),
      singular_fits = sum(d$singular_fit %in% TRUE),
      kenward_roger_completed = sum(
        d$kenward_roger_status %in% c("completed", "completed_with_warning")
      ),
      kenward_roger_skipped_memory = sum(
        d$kenward_roger_status == "skipped_dense_inverse_memory_infeasible"
      ),
      inference_strength = if (outcome == "checklist_reporting") {
        "weaker_prespecified_wald"
      } else {
        "kenward_roger_where_computable_else_satterthwaite"
      },
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

blockaware_bootstrap_record_v1 <- function(
    audit_path = file.path(
      "outputs", "post_stage4a_blockaware_preflight_v1",
      "cluster_block_dependence_audit.csv"
    ),
    projection_path = file.path(
      "outputs", "post_stage4a_blockaware_preflight_v1",
      "bootstrap_runtime_projection.csv"
    )) {
  if (!file.exists(audit_path) || !file.exists(projection_path)) {
    stop("BLOCKAWARE_PREFLIGHT_GATE: dependence audit unavailable",
         call. = FALSE)
  }
  audit <- utils::read.csv(audit_path, stringsAsFactors = FALSE)
  projection <- utils::read.csv(projection_path, stringsAsFactors = FALSE)
  crossing <- stats::setNames(
    audit$n_crossing_more_than_one_block, audit$cluster_type
  )
  totals <- stats::setNames(audit$n_clusters, audit$cluster_type)
  list(
    requested_repetitions = projection$requested_repetitions[[1L]],
    decision = "not_run",
    reason = paste(
      "One-way resampling of event blocks cannot preserve the crossed",
      "observer and location dependence measured in the preflight audit."
    ),
    observer_clusters_crossing_more_than_one_block =
      crossing[["observer_cluster"]],
    observer_clusters_total = totals[["observer_cluster"]],
    location_clusters_crossing_more_than_one_block =
      crossing[["location_cluster"]],
    location_clusters_total = totals[["location_cluster"]],
    checklists_partition_cleanly_by_block =
      identical(audit$partitions_cleanly_by_block[
        audit$cluster_type == "checklist"
      ], TRUE),
    projected_core_hours = projection$projected_core_hours[[1L]],
    projected_wall_clock_days = projection$projected_wall_clock_days[[1L]],
    future_work = paste(
      "A resampling design that respects both crossed factors is a separate",
      "methodological extension, not a parameter change to this run."
    ),
    preflight_audit_sha256 = .post_stage4a_sha256_v1(audit_path),
    preflight_projection_sha256 = .post_stage4a_sha256_v1(projection_path)
  )
}

blockaware_privacy_gate_v1 <- function(paths) {
  staged_refit_privacy_column_gate_v1(paths)
}

run_post_stage4a_blockaware_v1 <- function(
    execution_code_commit,
    output_root = "outputs/post_stage4a_blockaware_v1",
    protected_root = "data/derived/post_stage4a_blockaware_v1",
    workers = NULL,
    kenward_roger_budget_gb = 12) {
  started <- Sys.time()
  spec <- blockaware_spec_gate_v1()
  library_manifest <- blockaware_library_gate_v1()
  frozen_before <- blockaware_frozen_library_snapshot_v1()

  authorization <- staged_refit_authorization_gate_v1()
  staged_refit_amendment_gate_v1()
  staged_refit_s2_gate_v1()
  if (!identical(
    Sys.getenv("POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED"),
    authorization$environment_acknowledgement$value
  )) {
    stop("The exact author-set acknowledgement is required", call. = FALSE)
  }

  stage2_root <- "outputs/post_stage4a_staged_refit_stage2_v1"
  stage1_root <- "outputs/post_stage4a_staged_refit_v1"
  staged_refit_s2_verify_manifest_v1(stage2_root)
  stage2_hashes_before <- staged_refit_amendment_snapshot_v1(stage2_root)
  stage1_hashes_before <- staged_refit_amendment_snapshot_v1(stage1_root)
  parent_hashes_before <- staged_refit_parent_hash_snapshot_v1()
  diagnostic_hashes_before <- staged_refit_amendment_snapshot_v1(
    "outputs/post_stage4a_stage2_block_slope_diagnostic_v1"
  )
  preflight_hashes_before <- staged_refit_amendment_snapshot_v1(
    "outputs/post_stage4a_blockaware_preflight_v1"
  )

  bootstrap <- blockaware_bootstrap_record_v1()
  inputs <- stage2_block_slope_load_inputs_v1()
  direction <- stage2_block_slope_direction_v1()

  support_registry <- utils::read.csv(
    "outputs/stage2_design_lock/species_support_summary.csv",
    stringsAsFactors = FALSE
  )
  species_registry <- utils::read.csv(
    "metadata/canonical_species_registry.csv",
    stringsAsFactors = FALSE
  )
  core_taxa <- support_registry$analysis_taxon_id[
    support_registry$named_species_recommendation == "named_species_core"
  ]
  if (length(core_taxa) != 49L || anyDuplicated(core_taxa)) {
    stop("BLOCKAWARE_FAMILY_GATE: fixed 49", call. = FALSE)
  }

  checkpoint_root <- file.path(protected_root, "checkpoints")
  dir.create(checkpoint_root, recursive = TRUE, showWarnings = FALSE)
  code_signature <- paste(
    execution_code_commit,
    .post_stage4a_sha256_v1("R/post_stage4a_blockaware_v1.R"),
    .post_stage4a_sha256_v1("metadata/post_stage4a_blockaware_spec_v1.yml"),
    .post_stage4a_sha256_v1(
      "R/post_stage4a_stage2_block_slope_diagnostic_v1.R"
    ),
    inputs$protected_hashes,
    inputs$herring_source_hash,
    sep = "|",
    collapse = "|"
  )

  if (is.null(workers)) {
    workers <- post_stage4a_worker_count_v1(length(core_taxa))
  }
  message(
    "BLOCKAWARE_FAMILY_START taxa=", length(core_taxa),
    " workers=", workers,
    " kr_budget_gb=", kenward_roger_budget_gb,
    " kr_row_cap=",
    blockaware_kenward_roger_row_cap_v1(kenward_roger_budget_gb)
  )
  fit_started <- Sys.time()
  fitted <- blockaware_parallel_v1(
    core_taxa, inputs$events, inputs$states, inputs$masks, species_registry,
    file.path(checkpoint_root, "random_slope_family"),
    paste(code_signature, "random_slope_family", sep = "|"),
    workers
  )
  fitted <- fitted[core_taxa]
  fit_elapsed <- as.numeric(difftime(Sys.time(), fit_started, units = "secs"))

  estimates <- do.call(rbind, unlist(
    lapply(fitted, function(x) lapply(x, `[[`, "estimates")),
    recursive = FALSE
  ))
  variances <- do.call(rbind, unlist(
    lapply(fitted, function(x) lapply(x, `[[`, "variances")),
    recursive = FALSE
  ))
  rownames(estimates) <- NULL
  rownames(variances) <- NULL
  if (
    nrow(estimates) != 98L ||
      nrow(variances) != 98L ||
      anyDuplicated(paste(
        estimates$analysis_taxon_id, estimates$outcome, sep = "\r"
      ))
  ) {
    stop("BLOCKAWARE_FAMILY_GATE: expected 49 x 2", call. = FALSE)
  }

  kenward_roger_started <- Sys.time()
  kenward_roger <- blockaware_kenward_roger_pass_v1(
    estimates, inputs$events, inputs$states, inputs$masks, species_registry,
    file.path(checkpoint_root, "kenward_roger"),
    paste(code_signature, "kenward_roger", sep = "|"),
    kenward_roger_budget_gb
  )
  estimates <- blockaware_merge_kenward_roger_v1(estimates, kenward_roger)
  kenward_roger_elapsed <- as.numeric(
    difftime(Sys.time(), kenward_roger_started, units = "secs")
  )

  estimates$multiplicity_family <- NA_character_
  estimates <- blockaware_primary_interval_v1(estimates)
  estimates <- blockaware_add_multiplicity_v1(estimates)
  stage2 <- blockaware_stage2_baseline_v1()
  comparison <- blockaware_vs_stage2_v1(estimates, stage2)
  changes <- blockaware_bh_changes_v1(comparison)
  tallies <- blockaware_tallies_v1(estimates, spec)

  dir.create(output_root, recursive = TRUE, showWarnings = FALSE)
  outputs <- list(
    blockaware_estimates_49x2 = estimates,
    blockaware_vs_stage2 = comparison,
    blockaware_slope_variance = variances,
    blockaware_bh_changes = changes,
    blockaware_tallies = tallies,
    blockaware_analysis_library_manifest = library_manifest
  )
  output_paths <- character()
  for (name in names(outputs)) {
    path <- file.path(output_root, paste0(name, ".csv"))
    .post_stage4a_write_csv_v1(outputs[[name]], path)
    output_paths <- c(output_paths, path)
  }
  blockaware_privacy_gate_v1(output_paths)

  if (!identical(
    stage2_hashes_before, staged_refit_amendment_snapshot_v1(stage2_root)
  )) {
    stop("BLOCKAWARE_HISTORY_GATE: Stage 2 changed", call. = FALSE)
  }
  if (!identical(
    stage1_hashes_before, staged_refit_amendment_snapshot_v1(stage1_root)
  )) {
    stop("BLOCKAWARE_HISTORY_GATE: Stage 1 changed", call. = FALSE)
  }
  if (!identical(
    parent_hashes_before, staged_refit_parent_hash_snapshot_v1()
  )) {
    stop("BLOCKAWARE_HISTORY_GATE: parent changed", call. = FALSE)
  }
  if (!identical(
    diagnostic_hashes_before,
    staged_refit_amendment_snapshot_v1(
      "outputs/post_stage4a_stage2_block_slope_diagnostic_v1"
    )
  )) {
    stop("BLOCKAWARE_HISTORY_GATE: block-slope diagnostic changed",
         call. = FALSE)
  }
  if (!identical(
    preflight_hashes_before,
    staged_refit_amendment_snapshot_v1(
      "outputs/post_stage4a_blockaware_preflight_v1"
    )
  )) {
    stop("BLOCKAWARE_HISTORY_GATE: preflight changed", call. = FALSE)
  }
  frozen_after <- blockaware_frozen_library_snapshot_v1()
  if (!identical(frozen_before, frozen_after)) {
    stop("BLOCKAWARE_FROZEN_LIBRARY_GATE: renv library or lockfile changed",
         call. = FALSE)
  }

  code_files <- c(
    "R/post_stage4a_blockaware_v1.R",
    "scripts/run_post_stage4a_blockaware_v1.R",
    "scripts/run_post_stage4a_blockaware_v1.ps1",
    "metadata/post_stage4a_blockaware_spec_v1.yml",
    "tests/testthat/test-post-stage4a-blockaware-v1.R"
  )
  code_hashes <- vapply(
    code_files[file.exists(code_files)], .post_stage4a_sha256_v1, character(1L)
  )

  count_kr <- estimates[
    estimates$outcome == "conditional_positive_numeric_count", , drop = FALSE
  ]
  agreement <- count_kr[
    count_kr$kenward_roger_status %in%
      c("completed", "completed_with_warning") &
      is.finite(count_kr$satterthwaite_df), , drop = FALSE
  ]
  execution <- list(
    execution_version = blockaware_version_v1(),
    analysis_status = "post_result_block_aware_interval_recomputation",
    specification_record = "metadata/post_stage4a_blockaware_spec_v1.yml",
    approved_method_source =
      spec$authorization$method_approval_source,
    approved_method_source_sha256 =
      spec$authorization$method_approval_source_sha256,
    execution_code_commit = execution_code_commit,
    execution_code_source_state =
      "additive_versioned_files_recorded_by_sha256",
    execution_code_hashes = as.list(code_hashes),
    executed_at_utc = format(
      as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"
    ),
    elapsed_seconds = as.numeric(
      difftime(Sys.time(), started, units = "secs")
    ),
    stage_timings_seconds = list(
      parallel_random_slope_family = fit_elapsed,
      serial_kenward_roger_pass = kenward_roger_elapsed
    ),
    authorization_env_var_verified_not_set_by_agent = TRUE,
    population = list(
      region = "SoG",
      years = c(2005L, 2025L),
      checklists = nrow(inputs$events),
      fixed_family_species = length(core_taxa),
      model_fits = nrow(estimates),
      records_2026_plus_read = 0L
    ),
    random_effect_structure = list(
      event_block = "correlated_intercept_and_one_random_slope",
      slope_predictor = "normalized_active_minus_pre14_contrast_direction",
      normalization_check_unit_contrast = abs(
        sum(direction$contrast * direction$direction) - 1
      ) < 1e-12,
      observer_cluster = "random_intercept",
      location_cluster = "random_intercept",
      separate_slopes_per_exposure_term = FALSE,
      profile_likelihood_intervals_computed = FALSE
    ),
    engines = list(
      checklist_reporting = "lme4::glmer binomial nAGQ=0 with random slope",
      conditional_positive_numeric_count = paste(
        "lmerTest::lmer REML with random slope; lme4::lmer plus the stored",
        "deviance function and Hessian, verified on three species to give",
        "identical fixed effects and variance components"
      )
    ),
    interval_methods = list(
      conditional_positive_numeric_count = list(
        prespecified_primary = "kenward_roger_via_pbkrtest",
        completed = sum(count_kr$kenward_roger_status %in%
                          c("completed", "completed_with_warning")),
        skipped_dense_inverse_memory_infeasible = sum(
          count_kr$kenward_roger_status ==
            "skipped_dense_inverse_memory_infeasible"
        ),
        failed = sum(count_kr$kenward_roger_status == "failed"),
        memory_budget_gb = kenward_roger_budget_gb,
        row_cap_implied_by_budget =
          blockaware_kenward_roger_row_cap_v1(kenward_roger_budget_gb),
        execution_order =
          "serial_pass_after_the_parallel_fitting_pass_to_bound_memory",
        infeasibility_cause = paste(
          "pbkrtest::vcovAdj forms chol2inv(chol(Sigma)) where Sigma is the",
          "n by n marginal covariance; the inverse is dense, so the working",
          "set grows as n squared and exceeds machine memory for the larger",
          "count models"
        ),
        fallback_where_infeasible = "satterthwaite_denominator_df_via_lmerTest",
        fallback_corrects = "denominator_degrees_of_freedom_only",
        kenward_roger_versus_satterthwaite_df_on_common_subset = list(
          species = nrow(agreement),
          median_absolute_df_difference = if (nrow(agreement)) {
            stats::median(abs(
              agreement$kenward_roger_df - agreement$satterthwaite_df
            ))
          } else {
            NA_real_
          },
          median_kenward_roger_se_over_wald_se = if (nrow(agreement)) {
            stats::median(
              agreement$kenward_roger_standard_error /
                agreement$wald_standard_error
            )
          } else {
            NA_real_
          }
        )
      ),
      checklist_reporting = list(
        prespecified_primary = "wald_on_random_slope_binomial_fit",
        kenward_roger = "not_applicable_to_binomial_glmm",
        satterthwaite = "not_available_for_glmerMod",
        cluster_robust_cr0_cr1 = "prohibited_and_not_computed",
        label = "weaker_of_the_two_outcomes"
      )
    ),
    multiplicity = list(
      method = "benjamini_hochberg",
      family = "fixed_49_species_per_outcome",
      family_size = 49L,
      non_estimable_p_value = 1L,
      families_unchanged_from_stage2 = TRUE
    ),
    tallies = lapply(
      seq_len(nrow(tallies)), function(i) as.list(tallies[i, , drop = FALSE])
    ),
    bootstrap = bootstrap,
    software = list(
      r_version = R.version.string,
      pbkrtest_version = as.character(utils::packageVersion("pbkrtest")),
      lmerTest_version = as.character(utils::packageVersion("lmerTest")),
      lme4_version = as.character(utils::packageVersion("lme4")),
      versioned_analysis_library = blockaware_analysis_library_v1(),
      frozen_renv_library = blockaware_frozen_library_v1(),
      frozen_renv_library_modified = FALSE,
      renv_lock_modified = FALSE,
      renv_lock_sha256 = frozen_after[["renv_lock"]]
    ),
    workers = workers,
    joins = inputs$joins,
    protected_input_hashes = as.list(inputs$protected_hashes),
    herring_source_hash = inputs$herring_source_hash,
    historical_stage1_outputs_modified = FALSE,
    historical_stage2_outputs_modified = FALSE,
    historical_parent_outputs_modified = FALSE,
    historical_diagnostic_outputs_modified = FALSE,
    preflight_outputs_modified = FALSE,
    privacy_column_gate = "PASS",
    manuscript_edited_in_this_run = FALSE,
    next_action = "HUMAN_REVIEW_THEN_FIGURE_AND_MANUSCRIPT_UPDATE"
  )
  staged_refit_write_yaml_lf_v1(
    execution, file.path(output_root, "execution_record_v1.yml")
  )
  manifest <- staged_refit_output_manifest_v1(output_root)
  .post_stage4a_write_csv_v1(
    manifest, file.path(output_root, "output_hash_manifest_v1.csv")
  )
  for (i in seq_len(nrow(tallies))) {
    message(sprintf(
      "BLOCKAWARE_TALLY outcome=%s stage2_positive=%d blockaware_positive=%d negative=%d",
      tallies$outcome[[i]], tallies$stage2_fixed49_positive[[i]],
      tallies$blockaware_fixed49_positive[[i]],
      tallies$blockaware_fixed49_negative[[i]]
    ))
  }
  message("BLOCKAWARE_GATE=PASS_PENDING_HUMAN_REVIEW")
  invisible(list(
    estimates = estimates,
    variances = variances,
    comparison = comparison,
    changes = changes,
    tallies = tallies,
    library_manifest = library_manifest
  ))
}
