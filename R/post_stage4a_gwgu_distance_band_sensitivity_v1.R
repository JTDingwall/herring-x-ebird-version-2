post_stage4a_gwgu_distance_band_spec_v1 <- function() {
  minimum <- seq(0, 24, by = 2)
  maximum <- seq(2, 26, by = 2)
  data.frame(
    band = paste0("band_", minimum, "_", maximum),
    label = paste0(
      minimum, "–", ifelse(maximum == 26, "", "<"), maximum, " km"
    ),
    minimum_km = minimum,
    maximum_km = maximum,
    lower_inclusive = rep(TRUE, length(minimum)),
    upper_inclusive = maximum == 26,
    plotted = rep(TRUE, length(minimum)),
    stringsAsFactors = FALSE
  )
}

post_stage4a_gwgu_distance_band_terms_v1 <- function() {
  periods <- post_stage4a_period_spec_v1()$period
  bands <- post_stage4a_gwgu_distance_band_spec_v1()$band
  as.vector(outer(
    bands, periods,
    function(band, period) paste("db", band, period, sep = "_")
  ))
}

post_stage4a_gwgu_classify_distance_band_links_v1 <- function(links) {
  .post_stage4a_require_fields_v1(
    links,
    c("analysis_event_token", "event_day", "distance_km"),
    "distance-band link table"
  )
  event_day <- suppressWarnings(as.integer(links$event_day))
  distance_km <- suppressWarnings(as.numeric(links$distance_km))
  if (anyNA(event_day) || anyNA(distance_km) ||
      any(distance_km < 0 | distance_km > 26.0001)) {
    stop(
      "POST_STAGE4A_DISTANCE_BAND_LINK_RANGE_GATE: invalid day or distance",
      call. = FALSE
    )
  }

  period <- rep(NA_character_, length(event_day))
  periods <- post_stage4a_period_spec_v1()
  for (i in seq_len(nrow(periods))) {
    use <- event_day >= periods$minimum_day[[i]] &
      event_day <= periods$maximum_day[[i]]
    period[use] <- periods$period[[i]]
  }

  band <- rep(NA_character_, length(distance_km))
  bands <- post_stage4a_gwgu_distance_band_spec_v1()
  for (i in seq_len(nrow(bands))) {
    lower <- if (bands$lower_inclusive[[i]]) {
      distance_km >= bands$minimum_km[[i]]
    } else {
      distance_km > bands$minimum_km[[i]]
    }
    upper <- if (bands$upper_inclusive[[i]]) {
      distance_km <= bands$maximum_km[[i]]
    } else {
      distance_km < bands$maximum_km[[i]]
    }
    band[lower & upper] <- bands$band[[i]]
  }
  if ("link_provenance__" %in% names(links)) {
    archived_upper_boundary <-
      links$link_provenance__ == "archived_0_20" &
      distance_km == 20
    band[archived_upper_boundary] <- "band_18_20"
  }
  if (anyNA(band)) {
    stop(
      "POST_STAGE4A_DISTANCE_BAND_CLASSIFICATION_GATE: unclassified distance",
      call. = FALSE
    )
  }

  term <- ifelse(
    is.na(period), NA_character_,
    paste("db", band, period, sep = "_")
  )
  data.frame(
    analysis_event_token = as.character(links$analysis_event_token),
    period = period,
    band = band,
    term = term,
    stringsAsFactors = FALSE
  )
}

post_stage4a_gwgu_add_distance_band_exposure_v1 <- function(events, links) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("data.table is required for distance-band exposure construction",
         call. = FALSE)
  }
  event_required <- c(
    "analysis_event_token", "event_block_token", "region", "checklist_year",
    "concurrent_links"
  )
  link_required <- c(
    "analysis_event_token", "region", "checklist_year", "event_day",
    "distance_km", "link_provenance__"
  )
  .post_stage4a_require_fields_v1(
    events, event_required, "distance-band event metadata"
  )
  .post_stage4a_require_fields_v1(
    links, link_required, "distance-band source links"
  )
  if (anyDuplicated(events$analysis_event_token)) {
    stop(
      "POST_STAGE4A_DISTANCE_BAND_EVENT_CARDINALITY_GATE: duplicate event token",
      call. = FALSE
    )
  }

  event_tokens <- as.character(events$analysis_event_token)
  selected_links <- links[
    as.character(links$analysis_event_token) %in% event_tokens,
    link_required,
    drop = FALSE
  ]
  link_match <- match(selected_links$analysis_event_token, event_tokens)
  if (anyNA(link_match)) {
    stop(
      "POST_STAGE4A_DISTANCE_BAND_LINK_JOIN_GATE: unmatched selected link",
      call. = FALSE
    )
  }
  if (!all(
      as.integer(selected_links$checklist_year) ==
        as.integer(events$checklist_year[link_match])
  )) {
    stop(
      "POST_STAGE4A_DISTANCE_BAND_LINK_JOIN_GATE: checklist year disagreement",
      call. = FALSE
    )
  }

  link_counts <- table(selected_links$analysis_event_token)
  observed <- as.integer(link_counts[event_tokens])
  observed[is.na(observed)] <- 0L
  archived_counts <- table(
    selected_links$analysis_event_token[
      selected_links$link_provenance__ == "archived_0_20"
    ]
  )
  observed_archived <- as.integer(archived_counts[event_tokens])
  observed_archived[is.na(observed_archived)] <- 0L
  expected <- as.integer(events$concurrent_links)
  if (!identical(observed_archived, expected) ||
      any(observed < observed_archived)) {
    stop(
      paste0(
        "POST_STAGE4A_DISTANCE_BAND_LINK_CARDINALITY_GATE: ",
        "archived concurrent-link totals changed"
      ),
      call. = FALSE
    )
  }

  classified <- post_stage4a_gwgu_classify_distance_band_links_v1(selected_links)
  classified <- classified[!is.na(classified$term), , drop = FALSE]
  terms <- post_stage4a_gwgu_distance_band_terms_v1()
  if (!all(classified$term %in% terms)) {
    stop(
      "POST_STAGE4A_DISTANCE_BAND_TERM_GATE: unregistered joint term",
      call. = FALSE
    )
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
  event_dt[, concurrent_links_0_26 := observed]
  event_dt[, distance_band_row_order__ := .I]
  joined <- merge(
    event_dt, wide,
    by = "analysis_event_token",
    all.x = TRUE,
    sort = FALSE
  )
  data.table::setorder(joined, distance_band_row_order__)
  joined[, distance_band_row_order__ := NULL]
  if (nrow(joined) != nrow(events) ||
      anyDuplicated(joined$analysis_event_token)) {
    stop(
      "POST_STAGE4A_DISTANCE_BAND_AGGREGATION_GATE: model-row cardinality changed",
      call. = FALSE
    )
  }
  for (term in terms) {
    if (!term %in% names(joined)) joined[, (term) := 0L]
    data.table::set(
      joined, which(is.na(joined[[term]])), term, 0L
    )
    joined[, (term) := as.integer(get(term))]
  }
  retained_links <- rowSums(as.data.frame(joined[, ..terms]))
  if (any(retained_links > joined$concurrent_links_0_26)) {
    stop(
      "POST_STAGE4A_DISTANCE_BAND_JOINT_EXPOSURE_GATE: joint totals exceed links",
      call. = FALSE
    )
  }

  period_lookup <- post_stage4a_period_spec_v1()
  band_lookup <- post_stage4a_gwgu_distance_band_spec_v1()
  support <- do.call(rbind, lapply(terms, function(term) {
    match_row <- classified[classified$term == term, , drop = FALSE]
    bits <- strsplit(sub("^db_band_", "", term), "_", fixed = TRUE)[[1L]]
    band_id <- paste0("band_", bits[[1L]], "_", bits[[2L]])
    period <- paste(bits[-c(1L, 2L)], collapse = "_")
    use <- joined[[term]] > 0L
    data.frame(
      term = term,
      band = band_id,
      band_label = band_lookup$label[match(band_id, band_lookup$band)],
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
  if (anyNA(match(support$period, period_lookup$period)) ||
      anyNA(match(support$band, band_lookup$band))) {
    stop(
      "POST_STAGE4A_DISTANCE_BAND_SUPPORT_LABEL_GATE: term parse failed",
      call. = FALSE
    )
  }
  list(events = as.data.frame(joined), support = support)
}

post_stage4a_gwgu_distance_band_formula_v1 <- function(response) {
  fixed <- c(
    post_stage4a_gwgu_distance_band_terms_v1(),
    "factor(checklist_year)", "protocol", "log_duration",
    "log_effort_distance", "observer_count"
  )
  stats::as.formula(paste(
    response, "~", paste(fixed, collapse = " + "),
    "+ (1 | event_block_token) + (1 | observer_cluster_token) +",
    "(1 | location_cluster_token)"
  ))
}

post_stage4a_gwgu_distance_band_contrasts_v1 <- function(coefficient_names) {
  bands <- post_stage4a_gwgu_distance_band_spec_v1()
  bands <- bands[bands$plotted, , drop = FALSE]
  periods <- post_stage4a_period_spec_v1()
  periods <- periods[periods$period != "baseline", , drop = FALSE]
  make_vector <- function(weights) {
    vector <- stats::setNames(
      rep(0, length(coefficient_names)), coefficient_names
    )
    if (!all(names(weights) %in% coefficient_names)) return(NULL)
    vector[names(weights)] <- weights
    vector
  }
  rows <- list()
  index <- 1L
  for (i in seq_len(nrow(bands))) {
    baseline_term <- paste(
      "db", bands$band[[i]], "baseline", sep = "_"
    )
    for (j in seq_len(nrow(periods))) {
      period_term <- paste(
        "db", bands$band[[i]], periods$period[[j]], sep = "_"
      )
      vector <- make_vector(stats::setNames(
        c(1, -1), c(period_term, baseline_term)
      ))
      rows[[index]] <- list(
        band = bands$band[[i]],
        band_label = bands$label[[i]],
        contrast = paste0("within_", bands$band[[i]], "_",
                          periods$period[[j]], "_minus_baseline"),
        period = periods$period[[j]],
        minimum_day = periods$minimum_day[[j]],
        maximum_day = periods$maximum_day[[j]],
        contrast_type = "within_band_period_minus_baseline",
        vector = vector
      )
      index <- index + 1L
    }
    active_weights <- c(4 / 15, 11 / 15, -1)
    active_names <- c(
      paste("db", bands$band[[i]], "spawn_start", sep = "_"),
      paste("db", bands$band[[i]], "early_egg", sep = "_"),
      baseline_term
    )
    rows[[index]] <- list(
      band = bands$band[[i]],
      band_label = bands$label[[i]],
      contrast = paste0("within_", bands$band[[i]],
                        "_active_0_14_minus_baseline"),
      period = "active_0_14",
      minimum_day = 0L,
      maximum_day = 14L,
      contrast_type = "within_band_duration_weighted_active_minus_baseline",
      vector = make_vector(stats::setNames(active_weights, active_names))
    )
    index <- index + 1L
  }
  rows
}

post_stage4a_fit_gwgu_distance_band_component_v1 <- function(
    dat, outcome, checkpoint_path, cache_signature) {
  if (file.exists(checkpoint_path)) {
    cached <- readRDS(checkpoint_path)
    if (identical(cached$cache_signature, cache_signature)) {
      return(cached$result)
    }
  }
  if (outcome == "detection") {
    use <- !is.na(dat$detection)
    response <- "detection"
  } else if (outcome == "positive_numeric_count_given_detection") {
    use <- is.finite(dat$numeric_count) & dat$numeric_count > 0
    response <- "log_count"
  } else {
    stop("POST_STAGE4A_DISTANCE_BAND_OUTCOME_GATE: unsupported outcome",
         call. = FALSE)
  }
  d <- dat[use, , drop = FALSE]
  if (outcome == "positive_numeric_count_given_detection") {
    d$log_count <- log(d$numeric_count)
  }
  terms <- post_stage4a_gwgu_distance_band_terms_v1()
  term_support <- data.frame(
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
  if (nrow(d) < 20L || length(unique(d[[response]])) < 2L ||
      anyNA(term_support$exposed_model_rows) ||
      any(term_support$exposed_model_rows < 20L)) {
    stop(
      "POST_STAGE4A_DISTANCE_BAND_SUPPORT_GATE: insufficient model support",
      call. = FALSE
    )
  }

  formula <- post_stage4a_gwgu_distance_band_formula_v1(response)
  fit <- try(
    if (outcome == "detection") {
      lme4::glmer(
        formula, data = d, family = stats::binomial(), nAGQ = 0L,
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
    stop(
      "POST_STAGE4A_DISTANCE_BAND_FIT_GATE: failed numerical fit; no fallback",
      call. = FALSE
    )
  }
  beta <- lme4::fixef(fit)
  covariance <- as.matrix(stats::vcov(fit))
  missing_terms <- setdiff(terms, names(beta))
  if (length(missing_terms)) {
    stop(
      "POST_STAGE4A_DISTANCE_BAND_GEOMETRY_GATE: exposure coefficient dropped",
      call. = FALSE
    )
  }
  singular_fit <- lme4::isSingular(fit, tol = 1e-4)
  classification <- .post_stage4a_model_messages_v1(
    fit@optinfo$conv$opt,
    fit@optinfo$conv$lme4$messages,
    singular_fit
  )
  fixed_x <- lme4::getME(fit, "X")
  rank_deficient <- !is.null(attr(fixed_x, "col.dropped"))
  status <- if (!classification$converged) {
    "failed_convergence"
  } else if (rank_deficient) {
    "completed_with_rank_deficiency_warning"
  } else if (singular_fit) {
    "completed_with_singular_warning"
  } else {
    "completed"
  }
  if (!classification$converged) {
    stop(
      "POST_STAGE4A_DISTANCE_BAND_CONVERGENCE_GATE: model did not converge",
      call. = FALSE
    )
  }

  definitions <- post_stage4a_gwgu_distance_band_contrasts_v1(names(beta))
  z_value <- 1.959963984540054
  effects <- do.call(rbind, lapply(definitions, function(definition) {
    vector <- definition$vector
    if (is.null(vector)) {
      stop(
        "POST_STAGE4A_DISTANCE_BAND_CONTRAST_GATE: contrast geometry failed",
        call. = FALSE
      )
    }
    estimate <- sum(vector * beta)
    variance <- drop(t(vector) %*% covariance %*% vector)
    standard_error <- if (is.finite(variance) && variance >= 0) {
      sqrt(variance)
    } else {
      NA_real_
    }
    if (!is.finite(standard_error) || standard_error <= 0) {
      stop(
        "POST_STAGE4A_DISTANCE_BAND_CONTRAST_GATE: invalid standard error",
        call. = FALSE
      )
    }
    p_value <- 2 * stats::pnorm(-abs(estimate / standard_error))
    conf_low <- estimate - z_value * standard_error
    conf_high <- estimate + z_value * standard_error
    data.frame(
      model_version_id = "SOG_GLAUCOUS_WINGED_GULL_DISTANCE_BAND_v1",
      analysis_taxon_id = "atx_725074cbfcb6",
      unit_label = "Glaucous-winged Gull",
      region = "SoG",
      outcome = outcome,
      band = definition$band,
      band_label = definition$band_label,
      contrast = definition$contrast,
      contrast_type = definition$contrast_type,
      period = definition$period,
      minimum_day = definition$minimum_day,
      maximum_day = definition$maximum_day,
      estimate = estimate,
      standard_error = standard_error,
      conf_low = conf_low,
      conf_high = conf_high,
      ratio = exp(estimate),
      ratio_conf_low = exp(conf_low),
      ratio_conf_high = exp(conf_high),
      p_value = p_value,
      n = .post_stage4a_release_count_v1(nrow(d)),
      status = status,
      stringsAsFactors = FALSE
    )
  }))
  diagnostic <- data.frame(
    model_version_id = "SOG_GLAUCOUS_WINGED_GULL_DISTANCE_BAND_v1",
    analysis_taxon_id = "atx_725074cbfcb6",
    unit_label = "Glaucous-winged Gull",
    region = "SoG",
    outcome = outcome,
    converged = classification$converged,
    singular_fit = singular_fit,
    rank_deficient = rank_deficient,
    convergence_message = classification$message,
    n = .post_stage4a_release_count_v1(nrow(d)),
    status = status,
    stringsAsFactors = FALSE
  )
  fixed_effects <- data.frame(
    outcome = outcome,
    coefficient = names(beta),
    estimate = unname(beta),
    stringsAsFactors = FALSE
  )
  exposure_covariance <- as.data.frame(as.table(covariance[terms, terms]))
  names(exposure_covariance) <- c(
    "row_coefficient", "column_coefficient", "covariance"
  )
  exposure_covariance$outcome <- outcome
  exposure_covariance <- exposure_covariance[
    , c("outcome", "row_coefficient", "column_coefficient", "covariance")
  ]
  result <- list(
    effects = effects,
    diagnostic = diagnostic,
    term_support = term_support,
    fixed_effects = fixed_effects,
    exposure_covariance = exposure_covariance
  )
  saveRDS(
    list(cache_signature = cache_signature, result = result),
    checkpoint_path
  )
  result
}

post_stage4a_plot_gwgu_distance_bands_v1 <- function(
    effects, output_path) {
  plotted <- effects[
    effects$contrast_type == "within_band_period_minus_baseline",
    ,
    drop = FALSE
  ]
  period_order <- c(
    "baseline", "early_pre", "immediate_pre",
    "spawn_start", "early_egg", "late_egg"
  )
  period_labels <- c(
    "Baseline\n−28 to −15", "Early pre\n−14 to −8",
    "Immediate pre\n−7 to −1", "Spawn start\n0 to 3",
    "Early egg\n4 to 14", "Late egg\n15 to 28"
  )
  bands <- post_stage4a_gwgu_distance_band_spec_v1()
  bands <- bands[bands$plotted, , drop = FALSE]
  baseline <- do.call(rbind, lapply(unique(plotted$outcome), function(outcome) {
    data.frame(
      outcome = outcome,
      band = bands$band,
      band_label = bands$label,
      period = "baseline",
      ratio = 1,
      ratio_conf_low = 1,
      ratio_conf_high = 1,
      stringsAsFactors = FALSE
    )
  }))
  plot_data <- rbind(
    baseline,
    plotted[, c(
      "outcome", "band", "band_label", "period",
      "ratio", "ratio_conf_low", "ratio_conf_high"
    )]
  )
  palette <- stats::setNames(
    grDevices::hcl.colors(nrow(bands), palette = "Viridis", rev = TRUE),
    bands$band
  )
  symbols <- stats::setNames(
    rep(c(21, 22, 23, 24, 25, 1, 2), length.out = nrow(bands)),
    bands$band
  )
  line_types <- stats::setNames(
    rep(1:6, length.out = nrow(bands)),
    bands$band
  )
  distance_groups <- list(
    `0–<12 km` = bands$band[bands$minimum_km < 12],
    `12–26 km` = bands$band[bands$minimum_km >= 12]
  )
  panel_titles <- c(
    detection = "Checklist reporting",
    positive_numeric_count_given_detection =
      "Reported number, conditional on numeric detection"
  )
  y_labels <- c(
    detection = "Odds ratio versus same-band baseline",
    positive_numeric_count_given_detection =
      "Reported-number ratio versus same-band baseline"
  )

  y_limits_by_outcome <- lapply(names(panel_titles), function(outcome) {
    d <- plot_data[plot_data$outcome == outcome, , drop = FALSE]
    finite_limits <- c(d$ratio_conf_low, d$ratio_conf_high)
    finite_limits <- finite_limits[
      is.finite(finite_limits) & finite_limits > 0
    ]
    limits <- range(finite_limits)
    padding <- exp(0.1 * diff(log(limits)))
    c(limits[[1L]] / padding, limits[[2L]] * padding)
  })
  names(y_limits_by_outcome) <- names(panel_titles)

  grDevices::png(output_path, width = 3600, height = 2600, res = 240)
  par(oma = c(3.5, 0, 6.2, 0), family = "sans")
  layout(
    matrix(1:6, nrow = 3, byrow = TRUE),
    heights = c(0.28, 1, 1)
  )

  for (group_name in names(distance_groups)) {
    group_bands <- distance_groups[[group_name]]
    group_rows <- match(group_bands, bands$band)
    par(family = "sans", mar = c(0, 0, 0, 0))
    plot.new()
    legend(
      "center",
      legend = bands$label[group_rows],
      col = unname(palette[group_bands]),
      pch = unname(symbols[group_bands]),
      pt.bg = "white",
      lty = unname(line_types[group_bands]),
      lwd = 1.7,
      pt.cex = 1.0,
      ncol = if (length(group_bands) == 6L) 3L else 4L,
      bty = "n",
      title = paste0(
        group_name, " from recorded herring source point"
      )
    )
  }

  for (outcome in names(panel_titles)) {
    d <- plot_data[plot_data$outcome == outcome, , drop = FALSE]
    for (group_name in names(distance_groups)) {
      group_bands <- distance_groups[[group_name]]
      offsets <- stats::setNames(
        seq(-0.18, 0.18, length.out = length(group_bands)),
        group_bands
      )
      group_number <- match(group_name, names(distance_groups))
      par(mar = c(
        8.0,
        if (group_number == 1L) 7.2 else 4.0,
        4.0,
        1.5
      ))
      plot(
        NA,
        xlim = c(0.55, 6.45),
        ylim = y_limits_by_outcome[[outcome]],
        log = "y",
        xaxt = "n",
        xlab = "",
        ylab = if (group_number == 1L) y_labels[[outcome]] else "",
        main = paste(panel_titles[[outcome]], "—", group_name),
        bty = "l"
      )
      axis(
        1, at = seq_along(period_order), labels = period_labels,
        las = 2, tick = FALSE, cex.axis = 0.72
      )
      abline(h = 1, col = "#4A4A4A", lty = 3, lwd = 1.1)
      abline(
        v = seq(1.5, 5.5, by = 1),
        col = "#E2E2E2", lwd = 0.7
      )
      for (band in group_bands) {
        z <- d[d$band == band, , drop = FALSE]
        z <- z[match(period_order, z$period), , drop = FALSE]
        x <- seq_along(period_order) + offsets[[band]]
        ok <- is.finite(z$ratio) & is.finite(z$ratio_conf_low) &
          is.finite(z$ratio_conf_high) & z$ratio > 0 &
          z$ratio_conf_low > 0 & z$ratio_conf_high > 0
        lines(
          x[ok], z$ratio[ok],
          col = palette[[band]], lty = line_types[[band]], lwd = 1.7
        )
        nonbaseline <- ok & z$period != "baseline"
        segments(
          x[nonbaseline], z$ratio_conf_low[nonbaseline],
          x[nonbaseline], z$ratio_conf_high[nonbaseline],
          col = palette[[band]], lwd = 1.0
        )
        segments(
          x[nonbaseline] - 0.03, z$ratio_conf_low[nonbaseline],
          x[nonbaseline] + 0.03, z$ratio_conf_low[nonbaseline],
          col = palette[[band]], lwd = 1.0
        )
        segments(
          x[nonbaseline] - 0.03, z$ratio_conf_high[nonbaseline],
          x[nonbaseline] + 0.03, z$ratio_conf_high[nonbaseline],
          col = palette[[band]], lwd = 1.0
        )
        points(
          x[ok], z$ratio[ok],
          col = palette[[band]], bg = "white",
          pch = symbols[[band]], cex = 0.86, lwd = 1.0
        )
      }
    }
  }
  mtext(
    "Glaucous-winged Gull response timing by source-point distance, 0–26 km",
    outer = TRUE, side = 3, line = 1.1, cex = 1.25, font = 2
  )
  mtext(
    paste0(
      "Thirteen 2 km bands; within-band contrasts versus days −28 to −15; ",
      "SoG, 2005–2025; adjusted mixed models with 95% intervals"
    ),
    outer = TRUE, side = 3, line = -0.25, cex = 0.78
  )
  mtext(
    "Lines connect discrete periods and are not continuous trajectories. Baseline is fixed at 1 by definition.",
    outer = TRUE, side = 1, line = 1.2, cex = 0.68
  )
  grDevices::dev.off()
}

run_post_stage4a_gwgu_distance_band_sensitivity_v1 <- function(
    execution_code_commit,
    output_dir = "outputs/post_stage4a_gwgu_distance_band_sensitivity_v1") {
  acknowledgement <- "through_2025_glaucous_winged_gull_distance_bands_26km_v1"
  if (!identical(
      Sys.getenv("POST_STAGE4A_GWGU_DISTANCE_BAND_SENSITIVITY_V1_AUTHORIZED"),
      acknowledgement
  )) {
    stop(
      "Production requires the exact Glaucous-winged Gull distance-band acknowledgement",
      call. = FALSE
    )
  }
  packages <- c("data.table", "digest", "lme4", "yaml")
  missing <- packages[!vapply(
    packages, requireNamespace, logical(1L), quietly = TRUE
  )]
  if (length(missing)) {
    stop("Missing packages: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }
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
      "data/derived/stage4a_protected/stage4a_ambiguity_masks.tsv.gz"
  )
  if (!all(file.exists(protected_files))) {
    stop("Protected through-2025 distance-band inputs are unavailable",
         call. = FALSE)
  }
  source_link_hashes <- vapply(
    protected_files[c("source_links_archived", "source_links_extended")],
    .post_stage4a_sha256_v1,
    character(1L)
  )
  expected_source_link_hashes <- c(
    source_links_archived =
      "f26197d0a71fd177e77774ec9e5596563c127ec8eb0f948042aff51ad805567b",
    source_links_extended =
      "06a34a4d3880f2dd3a969d9976b901eff855ff7362e86ae40d75a38edd697dc2"
  )
  if (!identical(source_link_hashes, expected_source_link_hashes)) {
    stop("POST_STAGE4A_DISTANCE_BAND_SOURCE_LINK_HASH_GATE: mismatch",
         call. = FALSE)
  }
  protected_hashes <- vapply(
    protected_files, .post_stage4a_sha256_v1, character(1L)
  )

  events_all <- .stage4a_read_gz(protected_files[["event_metadata"]])
  if (nrow(events_all) != 239934L) {
    stop("POST_STAGE4A_DISTANCE_BAND_EVENT_CARDINALITY_GATE: expected 239934 rows",
         call. = FALSE)
  }
  if (any(as.integer(events_all$checklist_year) > 2025L)) {
    stop("POST_STAGE4A_DISTANCE_BAND_YEAR_GATE: 2026+ data encountered",
         call. = FALSE)
  }
  events_all <- .stage4a_prepare_events(events_all)
  selected <- events_all$region == "SoG" &
    events_all$checklist_year >= 2005L &
    events_all$checklist_year <= 2025L
  if (anyNA(selected) || sum(selected) != 217200L) {
    stop("POST_STAGE4A_DISTANCE_BAND_SOG_SCOPE_GATE: expected 217200 events",
         call. = FALSE)
  }
  events <- events_all[selected, , drop = FALSE]
  rm(events_all)
  if (!all(stage4a_effort_eligible(
      events$protocol, events$duration_minutes,
      events$effort_distance_km, events$observer_count
  ))) {
    stop("POST_STAGE4A_DISTANCE_BAND_EFFORT_GATE: ineligible checklist",
         call. = FALSE)
  }
  stage4a_validate_folds(events)

  archived_links <- .stage4a_read_gz(
    protected_files[["source_links_archived"]]
  )
  extended_links <- .stage4a_read_gz(
    protected_files[["source_links_extended"]]
  )
  link_key <- function(x) paste(
    x$analysis_event_token, x$herring_source_token, sep = "\r"
  )
  archived_key <- link_key(archived_links)
  extended_key <- link_key(extended_links)
  if (anyDuplicated(archived_key) || anyDuplicated(extended_key) ||
      !all(archived_key %in% extended_key)) {
    stop(
      "POST_STAGE4A_DISTANCE_BAND_ARCHIVED_LINK_RECONCILIATION_GATE: failed",
      call. = FALSE
    )
  }
  archived_index <- match(archived_key, extended_key)
  if (anyNA(archived_index) ||
      max(abs(
        as.numeric(archived_links$distance_km) -
          as.numeric(extended_links$distance_km[archived_index])
      )) > 0.0011 ||
      any(
        as.integer(archived_links$event_day) !=
          as.integer(extended_links$event_day[archived_index])
      )) {
    stop(
      "POST_STAGE4A_DISTANCE_BAND_ARCHIVED_LINK_VALUE_GATE: failed",
      call. = FALSE
    )
  }
  extra_links <- extended_links[
    !extended_key %in% archived_key, , drop = FALSE
  ]
  if (!nrow(extra_links) ||
      any(as.numeric(extra_links$distance_km) < 20 |
          as.numeric(extra_links$distance_km) > 26.0001)) {
    stop(
      "POST_STAGE4A_DISTANCE_BAND_EXTENSION_GATE: expected 20-26 km only",
      call. = FALSE
    )
  }
  archived_links$link_provenance__ <- "archived_0_20"
  extra_links$link_provenance__ <- "new_20_26"
  links <- rbind(archived_links, extra_links)
  rm(archived_links, extended_links, extra_links)
  joint <- post_stage4a_gwgu_add_distance_band_exposure_v1(events, links)
  events <- joint$events
  exposure_support <- joint$support
  rm(links, joint)

  states_all <- .stage4a_read_gz(protected_files[["reported_states"]])
  masks_all <- .stage4a_read_gz(protected_files[["ambiguity_masks"]])
  if (nrow(states_all) != 1169612L || nrow(masks_all) != 5834L) {
    stop("POST_STAGE4A_DISTANCE_BAND_STATE_CARDINALITY_GATE: changed",
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

  registry <- utils::read.csv(
    "metadata/canonical_species_registry.csv",
    stringsAsFactors = FALSE
  )
  if (anyDuplicated(registry$analysis_taxon_id)) {
    stop("POST_STAGE4A_DISTANCE_BAND_REGISTRY_KEY_GATE: duplicate taxon",
         call. = FALSE)
  }
  target_id <- registry$analysis_taxon_id[
    registry$common_name == "Glaucous-winged Gull"
  ]
  if (!identical(target_id, "atx_725074cbfcb6")) {
    stop("POST_STAGE4A_DISTANCE_BAND_TAXON_GATE: Glaucous-winged Gull mismatch",
         call. = FALSE)
  }
  denominator <- stage4a_materialize_taxon(
    events, states, masks, target_id
  )

  protected_dir <-
    "data/derived/post_stage4a_gwgu_distance_band_sensitivity_v1_protected"
  checkpoint_dir <- file.path(protected_dir, "checkpoints")
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  code_signature <- paste(
    execution_code_commit,
    protected_hashes,
    .post_stage4a_sha256_v1(
      "metadata/post_stage4a_gwgu_distance_band_sensitivity_spec_v1.yml"
    ),
    sep = "|",
    collapse = "|"
  )
  outcomes <- c(
    "detection", "positive_numeric_count_given_detection"
  )
  results <- lapply(outcomes, function(outcome) {
    checkpoint <- file.path(
      checkpoint_dir, paste0(target_id, "_", outcome, ".rds")
    )
    post_stage4a_fit_gwgu_distance_band_component_v1(
      denominator, outcome, checkpoint, code_signature
    )
  })

  effects <- do.call(rbind, lapply(results, `[[`, "effects"))
  diagnostics <- do.call(rbind, lapply(results, `[[`, "diagnostic"))
  term_support <- do.call(rbind, lapply(results, `[[`, "term_support"))
  fixed_effects <- do.call(rbind, lapply(results, `[[`, "fixed_effects"))
  exposure_covariance <- do.call(
    rbind, lapply(results, `[[`, "exposure_covariance")
  )
  support_lookup <- unique(exposure_support[, c("term", "band", "period")])
  if (anyDuplicated(support_lookup$term)) {
    stop("POST_STAGE4A_DISTANCE_BAND_SUPPORT_KEY_GATE: duplicate term",
         call. = FALSE)
  }
  support_idx <- match(term_support$term, support_lookup$term)
  if (anyNA(support_idx)) {
    stop("POST_STAGE4A_DISTANCE_BAND_SUPPORT_JOIN_GATE: unmatched term",
         call. = FALSE)
  }
  term_support$band <- support_lookup$band[support_idx]
  term_support$period <- support_lookup$period[support_idx]

  .post_stage4a_write_csv_v1(
    effects, file.path(output_dir, "glaucous_winged_gull_distance_band_effects_v1.csv")
  )
  .post_stage4a_write_csv_v1(
    diagnostics, file.path(output_dir, "model_diagnostics_v1.csv")
  )
  .post_stage4a_write_csv_v1(
    term_support, file.path(output_dir, "model_term_support_v1.csv")
  )
  .post_stage4a_write_csv_v1(
    exposure_support, file.path(output_dir, "joint_exposure_support_v1.csv")
  )
  .post_stage4a_write_csv_v1(
    fixed_effects, file.path(output_dir, "fixed_effects_v1.csv")
  )
  .post_stage4a_write_csv_v1(
    exposure_covariance,
    file.path(output_dir, "exposure_covariance_v1.csv")
  )
  figure_path <- file.path(
    output_dir, "glaucous_winged_gull_distance_band_panel_v1.png"
  )
  post_stage4a_plot_gwgu_distance_bands_v1(effects, figure_path)

  execution_record <- list(
    execution_version = "post_stage4a_gwgu_distance_band_sensitivity_v1",
    executed_at_utc = format(
      as.POSIXct(Sys.time(), tz = "UTC"),
      "%Y-%m-%dT%H:%M:%SZ"
    ),
    execution_code_commit = execution_code_commit,
    authorization_record =
      "metadata/post_stage4a_gwgu_distance_band_sensitivity_authorization_v1.yml",
    authorization_record_sha256 = .post_stage4a_sha256_v1(
      "metadata/post_stage4a_gwgu_distance_band_sensitivity_authorization_v1.yml"
    ),
    specification_sha256 = .post_stage4a_sha256_v1(
      "metadata/post_stage4a_gwgu_distance_band_sensitivity_spec_v1.yml"
    ),
    analysis_status = "post_result_exploratory_estimand_refinement",
    historical_stage4a_outputs_modified = FALSE,
    region = "SoG",
    years = c(2005L, 2025L),
    taxon = "Glaucous-winged Gull",
    maximum_source_point_distance_km = 26L,
    plotted_distance_bands = 13L,
    eligible_checklists = nrow(events),
    model_components = nrow(diagnostics),
    released_contrasts = nrow(effects),
    model_status_counts = as.list(table(diagnostics$status)),
    protected_input_hashes = as.list(protected_hashes),
    source_link_hash_gate = "PASS",
    archived_0_20km_link_reconciliation_gate = "PASS",
    new_20_26km_links_only_gate = "PASS",
    concurrent_link_joint_pairing_gate = "PASS",
    records_2026_plus_read = 0L,
    comments_read = 0L,
    shoreline_fields_read = 0L,
    full_event_taxon_grid_expanded = FALSE,
    glaucous_winged_gull_fit = TRUE,
    bald_eagle_fit = FALSE,
    manuscript_edited = FALSE,
    final_gate =
      "PASS_PENDING_HUMAN_GLAUCOUS_WINGED_GULL_26KM_DISTANCE_BAND_REVIEW"
  )
  yaml::write_yaml(
    execution_record,
    file.path(output_dir, "execution_record_v1.yml")
  )
  output_files <- file.path(
    output_dir,
    c(
      "glaucous_winged_gull_distance_band_effects_v1.csv",
      "model_diagnostics_v1.csv",
      "model_term_support_v1.csv",
      "joint_exposure_support_v1.csv",
      "fixed_effects_v1.csv",
      "exposure_covariance_v1.csv",
      "glaucous_winged_gull_distance_band_panel_v1.png",
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
    "POST_STAGE4A_DISTANCE_BAND_SENSITIVITY_GATE=",
    "PASS_PENDING_HUMAN_GLAUCOUS_WINGED_GULL_26KM_DISTANCE_BAND_REVIEW"
  )
  invisible(list(
    effects = effects,
    diagnostics = diagnostics,
    exposure_support = exposure_support
  ))
}
