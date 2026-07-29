stage2_block_slope_version_v1 <- function() {
  "post_stage4a_stage2_block_slope_diagnostic_v1"
}

stage2_block_slope_gate_v1 <- function(
    path =
      "metadata/post_stage4a_stage2_block_slope_diagnostic_authorization_v1.yml") {
  if (!file.exists(path)) {
    stop("STAGE2_BLOCK_SLOPE_AUTHORIZATION_GATE: record unavailable",
         call. = FALSE)
  }
  record <- yaml::read_yaml(path)
  if (
    !identical(
      record$authorization_version,
      "post_stage4a_stage2_block_slope_diagnostic_authorization_v1"
    ) ||
      !identical(
        record$decision,
        "AUTHORIZE_STAGE2_TOP10_COUNT_BLOCK_SLOPE_DIAGNOSTIC_V1"
      ) ||
      !identical(
        record$authorized_scope$outcome,
        "conditional_positive_numeric_count"
      ) ||
      !identical(
        record$authorized_scope$species_selection,
        "top_10_descending_active_minus_pre14_estimate"
      ) ||
      !identical(
        record$authorized_scope$variance_interval,
        "profile_likelihood"
      )
  ) {
    stop("STAGE2_BLOCK_SLOPE_AUTHORIZATION_GATE: scope mismatch",
         call. = FALSE)
  }
  invisible(record)
}

stage2_block_slope_direction_v1 <- function() {
  terms <- post_stage4a_exposure_terms_v1()
  weights <- staged_refit_s1_contrast_weights_v1()[[
    "active_minus_pre14"
  ]]
  contrast <- stats::setNames(rep(0, length(terms)), terms)
  contrast[names(weights)] <- as.numeric(weights)
  squared_norm <- sum(contrast^2)
  direction <- contrast / squared_norm
  if (
    !is.finite(squared_norm) ||
      squared_norm <= 0 ||
      abs(sum(contrast * direction) - 1) > 1e-12
  ) {
    stop("STAGE2_BLOCK_SLOPE_DIRECTION_GATE: invalid normalization",
         call. = FALSE)
  }
  list(
    contrast = contrast,
    direction = direction,
    squared_norm = squared_norm
  )
}

stage2_block_slope_add_predictor_v1 <- function(dat) {
  direction <- stage2_block_slope_direction_v1()
  terms <- names(direction$direction)
  if (!all(terms %in% names(dat))) {
    stop("STAGE2_BLOCK_SLOPE_PREDICTOR_GATE: exposure columns unavailable",
         call. = FALSE)
  }
  matrix <- as.matrix(dat[, terms, drop = FALSE])
  storage.mode(matrix) <- "double"
  dat$block_active_minus_pre14 <- drop(
    matrix %*% direction$direction
  )
  if (any(!is.finite(dat$block_active_minus_pre14))) {
    stop("STAGE2_BLOCK_SLOPE_PREDICTOR_GATE: nonfinite predictor",
         call. = FALSE)
  }
  dat
}

stage2_block_slope_formula_v1 <- function(response = "model_response") {
  fixed <- c(
    post_stage4a_exposure_terms_v1(),
    "factor(checklist_year)", "protocol", "log_duration",
    "log_effort_distance", "observer_count",
    staged_refit_s2_detectability_terms_v1()
  )
  stats::as.formula(paste(
    response, "~", paste(fixed, collapse = " + "),
    "+ (1 + block_active_minus_pre14 | event_block_token) +",
    "(1 | observer_cluster_token) + (1 | location_cluster_token)"
  ))
}

stage2_block_slope_select_top_ten_v1 <- function(
    path = file.path(
      "outputs", "post_stage4a_staged_refit_stage2_v1",
      "s2_detectability", "estimates_49x2.csv"
    )) {
  estimates <- utils::read.csv(path, stringsAsFactors = FALSE)
  required <- c(
    "analysis_taxon_id", "species", "outcome", "comparison", "estimate",
    "standard_error", "ratio", "ratio_conf_low", "ratio_conf_high",
    "p_value", "q_value", "n", "status"
  )
  if (
    !all(required %in% names(estimates)) ||
      nrow(estimates) != 98L ||
      anyDuplicated(paste(
        estimates$analysis_taxon_id, estimates$outcome, sep = "\r"
      ))
  ) {
    stop("STAGE2_BLOCK_SLOPE_SELECTION_GATE: Stage 2 family changed",
         call. = FALSE)
  }
  eligible <- estimates[
    estimates$outcome == "conditional_positive_numeric_count" &
      estimates$comparison == "active_minus_pre14" &
      is.finite(estimates$estimate) &
      !grepl("^failed", estimates$status),
    required,
    drop = FALSE
  ]
  eligible <- eligible[
    order(-eligible$estimate, eligible$species),
    ,
    drop = FALSE
  ]
  if (nrow(eligible) < 10L) {
    stop("STAGE2_BLOCK_SLOPE_SELECTION_GATE: fewer than ten estimable",
         call. = FALSE)
  }
  selected <- eligible[seq_len(10L), , drop = FALSE]
  selected$effect_rank <- seq_len(nrow(selected))
  selected$selection_rule <-
    "top_10_descending_link_scale_active_minus_pre14_count_estimate"
  selected[, c(
    "effect_rank", required, "selection_rule"
  ), drop = FALSE]
}

stage2_block_slope_extract_variance_v1 <- function(
    fit, group, variable = NULL) {
  variance <- as.data.frame(lme4::VarCorr(fit))
  use <- variance$grp == group & is.na(variance$var2)
  if (identical(group, "Residual")) {
    use <- use & is.na(variance$var1)
  } else if (is.null(variable)) {
    use <- use & variance$var1 == "(Intercept)"
  } else {
    use <- use & variance$var1 == variable
  }
  value <- variance$vcov[use]
  if (length(value) != 1L) NA_real_ else value[[1L]]
}

stage2_block_slope_profile_interval_v1 <- function(fit) {
  parameter <- "sd_block_active_minus_pre14|event_block_token"
  warnings <- character()
  interval <- tryCatch(
    withCallingHandlers(
      stats::confint(
        fit,
        parm = parameter,
        level = 0.95,
        method = "profile",
        signames = FALSE,
        quiet = TRUE
      ),
      warning = function(warning) {
        warnings <<- c(warnings, conditionMessage(warning))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(error) error
  )
  if (inherits(interval, "error")) {
    return(list(
      sd_low = NA_real_,
      sd_high = NA_real_,
      variance_low = NA_real_,
      variance_high = NA_real_,
      status = "profile_failed",
      message = substr(conditionMessage(interval), 1L, 500L)
    ))
  }
  values <- as.numeric(interval[1L, ])
  status <- if (length(warnings)) {
    "profile_completed_with_warning"
  } else {
    "profile_completed"
  }
  list(
    sd_low = values[[1L]],
    sd_high = values[[2L]],
    variance_low = values[[1L]]^2,
    variance_high = values[[2L]]^2,
    status = status,
    message = if (length(warnings)) {
      substr(paste(unique(warnings), collapse = "; "), 1L, 500L)
    } else {
      ""
    }
  )
}

stage2_block_slope_exposure_distribution_v1 <- function(events) {
  terms <- post_stage4a_exposure_terms_v1()
  required <- c("event_block_token", terms)
  if (!all(required %in% names(events))) {
    stop("STAGE2_BLOCK_SLOPE_DISTRIBUTION_GATE: columns unavailable",
         call. = FALSE)
  }
  exposed <- rowSums(events[, terms, drop = FALSE]) > 0
  all_blocks <- unique(as.character(events$event_block_token))
  counts <- as.numeric(table(factor(
    as.character(events$event_block_token[exposed]),
    levels = all_blocks
  )))
  if (
    !length(counts) ||
      sum(counts) != sum(exposed) ||
      any(counts < 0)
  ) {
    stop("STAGE2_BLOCK_SLOPE_DISTRIBUTION_GATE: invalid block counts",
         call. = FALSE)
  }
  shares <- counts / sum(counts)
  quantiles <- stats::quantile(
    counts,
    probs = c(0, 0.10, 0.25, 0.50, 0.75, 0.90, 1),
    names = FALSE,
    type = 7
  )
  release_count <- function(value) {
    if (is.finite(value) && value < 20) NA_real_ else value
  }
  data.frame(
    exposed_checklists = sum(counts),
    event_blocks_total = length(counts),
    event_blocks_with_exposed_checklists = sum(counts > 0),
    event_blocks_without_exposed_checklists = sum(counts == 0),
    mean_per_block = mean(counts),
    sd_per_block = stats::sd(counts),
    minimum_per_block = release_count(quantiles[[1L]]),
    p10_per_block = release_count(quantiles[[2L]]),
    p25_per_block = release_count(quantiles[[3L]]),
    median_per_block = release_count(quantiles[[4L]]),
    p75_per_block = release_count(quantiles[[5L]]),
    p90_per_block = release_count(quantiles[[6L]]),
    maximum_per_block = release_count(quantiles[[7L]]),
    suppressed_minimum_under_20 = quantiles[[1L]] < 20,
    largest_block_share = max(shares),
    five_largest_blocks_share =
      sum(sort(shares, decreasing = TRUE)[seq_len(min(5L, length(shares)))]),
    herfindahl_index = sum(shares^2),
    effective_clusters_inverse_herfindahl = 1 / sum(shares^2),
    exposed_definition = paste(
      "positive in at least one of twelve registered",
      "period-by-zone exposure-link columns"
    ),
    stringsAsFactors = FALSE
  )
}

stage2_block_slope_load_inputs_v1 <- function(
    herring_path = file.path(
      "data", "raw",
      "Pacific_herring_spawn_index_data_2025_EN_frozen_crlf.csv"
    )) {
  protected_files <- c(
    event_metadata =
      "data/derived/stage4a_protected/stage4a_event_metadata.tsv.gz",
    detectability = file.path(
      "data", "derived", "post_stage4a_staged_refit_stage2_v1",
      "stage2_detectability_covariates.tsv.gz"
    ),
    source_links_archived =
      "data/derived/stage3_phase2_protected/metadata_source_point_links.tsv.gz",
    reported_states =
      "data/derived/stage4a_protected/stage4a_reported_states.tsv.gz",
    ambiguity_masks =
      "data/derived/stage4a_protected/stage4a_ambiguity_masks.tsv.gz"
  )
  expected_hashes <- c(
    event_metadata =
      "03eaccdd46b5cba779f596e7ce96dacd5a509f51f6eae4c5c79daf706879a9b2",
    detectability =
      "8a43d3f84d1914ab2b1ce53978aa5b40092b5a777924b8d0c376f975da03a429",
    source_links_archived =
      "f26197d0a71fd177e77774ec9e5596563c127ec8eb0f948042aff51ad805567b",
    reported_states =
      "0f02ac6bdbb561a8e4df58cc8d53340ec29f9519b85a99f4748cb8367fc33cb5",
    ambiguity_masks =
      "c0e063f8a8c6ccfb97535183d8e669a9f4bb1eaea31bae144dffa3d81d57d3ff"
  )
  if (!all(file.exists(protected_files)) || !file.exists(herring_path)) {
    stop("STAGE2_BLOCK_SLOPE_INPUT_GATE: protected input unavailable",
         call. = FALSE)
  }
  observed_hashes <- vapply(
    protected_files, .post_stage4a_sha256_v1, character(1L)
  )
  if (!identical(observed_hashes[names(expected_hashes)], expected_hashes)) {
    stop("STAGE2_BLOCK_SLOPE_INPUT_HASH_GATE: frozen input mismatch",
         call. = FALSE)
  }

  events_all <- .stage4a_prepare_events(
    .stage4a_read_gz(protected_files[["event_metadata"]])
  )
  selected <- events_all$region == "SoG" &
    events_all$checklist_year >= 2005L &
    events_all$checklist_year <= 2025L
  events <- events_all[selected, , drop = FALSE]
  rm(events_all)
  if (
    nrow(events) != 217200L ||
      any(as.integer(events$checklist_year) > 2025L) ||
      anyDuplicated(events$analysis_event_token)
  ) {
    stop("STAGE2_BLOCK_SLOPE_POPULATION_GATE: changed",
         call. = FALSE)
  }
  stage4a_validate_folds(events)

  detectability <- staged_refit_s2_read_detectability_v1(
    protected_files[["detectability"]]
  )
  detectability_join <- staged_refit_s2_attach_detectability_v1(
    events, detectability
  )
  if (detectability_join$complete != 217200L) {
    stop("STAGE2_BLOCK_SLOPE_DETECTABILITY_GATE: population changed",
         call. = FALSE)
  }

  anchor_lookup <- staged_refit_build_anchor_lookup_v1(herring_path)
  links <- .stage4a_read_gz(protected_files[["source_links_archived"]])
  anchored_links <- staged_refit_reanchor_links_v1(links, anchor_lookup)
  joined <- post_stage4a_add_joint_exposure_v1(events, anchored_links)
  detectability_real <- staged_refit_s2_attach_detectability_v1(
    joined$events, detectability
  )
  events_real <- detectability_real$events
  if (
    nrow(events_real) != 217200L ||
      !identical(
        as.character(events_real$analysis_event_token),
        as.character(detectability_join$events$analysis_event_token)
      )
  ) {
    stop("STAGE2_BLOCK_SLOPE_REAL_JOIN_GATE: order or cardinality",
         call. = FALSE)
  }

  model_tokens <- as.character(events_real$analysis_event_token)
  states_all <- .stage4a_read_gz(protected_files[["reported_states"]])
  masks_all <- .stage4a_read_gz(protected_files[["ambiguity_masks"]])
  if (nrow(states_all) != 1169612L || nrow(masks_all) != 5834L) {
    stop("STAGE2_BLOCK_SLOPE_STATE_GATE: cardinality",
         call. = FALSE)
  }
  states <- states_all[
    states_all$analysis_event_token %in% model_tokens, , drop = FALSE
  ]
  masks <- masks_all[
    masks_all$analysis_event_token %in% model_tokens, , drop = FALSE
  ]
  rm(states_all, masks_all)
  list(
    events = events_real,
    states = states,
    masks = masks,
    protected_hashes = observed_hashes,
    herring_source_hash = attr(anchor_lookup, "source_hash"),
    joins = list(
      detectability_to_checklists = "one_to_one_217200_rows_PASS",
      links_to_anchor_lookup = "many_to_one_PASS",
      links_to_checklists =
        "many_to_one_then_aggregate_to_one_checklist_PASS"
    )
  )
}

stage2_block_slope_fit_species_v1 <- function(
    taxon_id, species, rank, events, states, masks, stage2_row,
    model_directory) {
  started <- Sys.time()
  dat <- stage4a_materialize_taxon(
    events, states, masks, taxon_id
  )
  use <- is.finite(dat$numeric_count) & dat$numeric_count > 0
  dat <- dat[use, , drop = FALSE]
  dat$model_response <- log(dat$numeric_count)
  dat <- stage2_block_slope_add_predictor_v1(dat)
  terms <- post_stage4a_exposure_terms_v1()
  exposed <- vapply(
    terms, function(term) sum(dat[[term]] > 0L), integer(1L)
  )
  grouping_levels <- c(
    event_block = length(unique(dat$event_block_token)),
    observer = length(unique(dat$observer_cluster_token)),
    location = length(unique(dat$location_cluster_token))
  )
  if (
    nrow(dat) < 20L ||
      any(exposed < 20L) ||
      any(grouping_levels < 2L)
  ) {
    stop(
      "STAGE2_BLOCK_SLOPE_SUPPORT_GATE: selected species unsupported: ",
      species,
      call. = FALSE
    )
  }

  formula <- stage2_block_slope_formula_v1("model_response")
  fit <- lme4::lmer(
    formula,
    data = dat,
    REML = TRUE,
    control = lme4::lmerControl(
      optimizer = "nloptwrap",
      calc.derivs = TRUE,
      optCtrl = list(maxeval = 10000L)
    )
  )
  dir.create(model_directory, recursive = TRUE, showWarnings = FALSE)
  model_path <- file.path(
    model_directory,
    paste0(sprintf("%02d", rank), "_", taxon_id, "_count_model.rds")
  )
  saveRDS(
    list(
      analysis_version = stage2_block_slope_version_v1(),
      species = species,
      analysis_taxon_id = taxon_id,
      fit = fit
    ),
    model_path
  )

  beta <- lme4::fixef(fit)
  covariance <- as.matrix(stats::vcov(fit))
  contrast <- staged_refit_wald_v1(
    beta, covariance,
    staged_refit_s1_contrast_weights_v1()[["active_minus_pre14"]]
  )
  singular <- lme4::isSingular(fit, tol = 1e-4)
  optimizer_code <- fit@optinfo$conv$opt
  classification <- .post_stage4a_model_messages_v1(
    optimizer_code, fit@optinfo$conv$lme4$messages, singular
  )
  slope_variance <- stage2_block_slope_extract_variance_v1(
    fit, "event_block_token", "block_active_minus_pre14"
  )
  variance_table <- as.data.frame(lme4::VarCorr(fit))
  correlation <- variance_table$sdcor[
    variance_table$grp == "event_block_token" &
      variance_table$var1 == "(Intercept)" &
      variance_table$var2 == "block_active_minus_pre14"
  ]
  if (length(correlation) != 1L) correlation <- NA_real_
  interval <- stage2_block_slope_profile_interval_v1(fit)
  residual_variance <- stage2_block_slope_extract_variance_v1(
    fit, "Residual"
  )
  gradients <- fit@optinfo$derivs$gradient
  data.frame(
    effect_rank = rank,
    analysis_taxon_id = taxon_id,
    species = species,
    outcome = "conditional_positive_numeric_count",
    comparison = "active_minus_pre14",
    stage2_estimate = stage2_row$estimate,
    stage2_standard_error = stage2_row$standard_error,
    random_slope_model_estimate = contrast[["estimate"]],
    random_slope_model_standard_error = contrast[["standard_error"]],
    random_slope_model_conf_low = contrast[["conf_low"]],
    random_slope_model_conf_high = contrast[["conf_high"]],
    n_positive_numeric_counts = nrow(dat),
    event_blocks_in_count_model = grouping_levels[["event_block"]],
    slope_variance = slope_variance,
    slope_variance_conf_low = interval$variance_low,
    slope_variance_conf_high = interval$variance_high,
    slope_sd = sqrt(slope_variance),
    slope_sd_conf_low = interval$sd_low,
    slope_sd_conf_high = interval$sd_high,
    event_block_intercept_slope_correlation = correlation,
    event_block_intercept_variance =
      stage2_block_slope_extract_variance_v1(
        fit, "event_block_token"
      ),
    observer_intercept_variance =
      stage2_block_slope_extract_variance_v1(
        fit, "observer_cluster_token"
      ),
    location_intercept_variance =
      stage2_block_slope_extract_variance_v1(
        fit, "location_cluster_token"
      ),
    residual_variance = residual_variance,
    slope_variance_over_residual_variance =
      slope_variance / residual_variance,
    converged = classification$converged,
    singular_fit = singular,
    convergence_message = classification$message,
    maximum_absolute_gradient = if (is.null(gradients)) {
      NA_real_
    } else {
      max(abs(gradients))
    },
    profile_status = interval$status,
    profile_message = interval$message,
    elapsed_seconds = as.numeric(
      difftime(Sys.time(), started, units = "secs")
    ),
    model_object_location = gsub("\\\\", "/", model_path),
    stringsAsFactors = FALSE
  )
}

stage2_block_slope_privacy_gate_v1 <- function(paths) {
  prohibited <- c(
    "analysis_event_token", "analysis_checklist_id",
    "observer_cluster_token", "location_cluster_token",
    "event_block_token", "herring_source_token",
    "latitude", "longitude", "locality", "coordinates", "source_id",
    "analysis_id"
  )
  failures <- character()
  for (path in paths) {
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
      "STAGE2_BLOCK_SLOPE_PRIVACY_GATE: ",
      paste(failures, collapse = "; "),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

run_post_stage4a_stage2_block_slope_diagnostic_v1 <- function(
    execution_code_commit,
    output_root =
      "outputs/post_stage4a_stage2_block_slope_diagnostic_v1",
    protected_root =
      "data/derived/post_stage4a_stage2_block_slope_diagnostic_v1") {
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
  stage2_block_slope_gate_v1()
  if (!identical(
      Sys.getenv("POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED"),
      authorization$environment_acknowledgement$value
  )) {
    stop("The exact author-set acknowledgement is required",
         call. = FALSE)
  }
  staged_refit_s2_verify_manifest_v1(
    "outputs/post_stage4a_staged_refit_stage2_v1"
  )
  historical_stage2_before <- staged_refit_amendment_snapshot_v1(
    "outputs/post_stage4a_staged_refit_stage2_v1"
  )
  historical_stage1_before <- staged_refit_amendment_snapshot_v1(
    "outputs/post_stage4a_staged_refit_v1"
  )
  historical_parent_before <- staged_refit_parent_hash_snapshot_v1()

  selected <- stage2_block_slope_select_top_ten_v1()
  inputs <- stage2_block_slope_load_inputs_v1()
  distribution <- stage2_block_slope_exposure_distribution_v1(
    inputs$events
  )
  model_directory <- file.path(protected_root, "models")
  results <- lapply(seq_len(nrow(selected)), function(index) {
    message(
      "STAGE2_BLOCK_SLOPE_FIT_START rank=", index,
      " species=", selected$species[[index]]
    )
    row <- stage2_block_slope_fit_species_v1(
      selected$analysis_taxon_id[[index]],
      selected$species[[index]],
      index,
      inputs$events,
      inputs$states,
      inputs$masks,
      selected[index, , drop = FALSE],
      model_directory
    )
    message(
      "STAGE2_BLOCK_SLOPE_FIT_DONE rank=", index,
      " variance=", signif(row$slope_variance, 6),
      " upper=", signif(row$slope_variance_conf_high, 6)
    )
    row
  })
  results <- do.call(rbind, results)

  point_pass <- is.finite(results$slope_variance) &
    results$slope_variance <= 0.0025
  interval_pass <- is.finite(results$slope_variance_conf_high) &
    results$slope_variance_conf_high <= 0.01
  results$near_zero_point_threshold_pass <- point_pass
  results$near_zero_interval_threshold_pass <- interval_pass
  near_zero_across_ten <- all(point_pass & interval_pass)

  dir.create(output_root, recursive = TRUE, showWarnings = FALSE)
  selected_path <- file.path(output_root, "selected_top10_stage2_counts.csv")
  result_path <- file.path(output_root, "block_slope_variance_top10.csv")
  distribution_path <- file.path(
    output_root, "exposed_checklists_block_distribution.csv"
  )
  .post_stage4a_write_csv_v1(selected, selected_path)
  .post_stage4a_write_csv_v1(results, result_path)
  .post_stage4a_write_csv_v1(distribution, distribution_path)
  stage2_block_slope_privacy_gate_v1(
    c(selected_path, result_path, distribution_path)
  )
  code_files <- c(
    "R/post_stage4a_stage2_block_slope_diagnostic_v1.R",
    "scripts/run_post_stage4a_stage2_block_slope_diagnostic_v1.R",
    "scripts/run_post_stage4a_stage2_block_slope_diagnostic_v1.ps1",
    "metadata/post_stage4a_stage2_block_slope_diagnostic_spec_v1.yml",
    paste0(
      "metadata/",
      "post_stage4a_stage2_block_slope_diagnostic_authorization_v1.yml"
    ),
    paste0(
      "tests/testthat/",
      "test-post-stage4a-stage2-block-slope-diagnostic-v1.R"
    )
  )
  code_hashes <- vapply(
    code_files, .post_stage4a_sha256_v1, character(1L)
  )

  if (!identical(
      historical_stage2_before,
      staged_refit_amendment_snapshot_v1(
        "outputs/post_stage4a_staged_refit_stage2_v1"
      )
  )) {
    stop("STAGE2_BLOCK_SLOPE_HISTORY_GATE: Stage 2 changed",
         call. = FALSE)
  }
  if (!identical(
      historical_stage1_before,
      staged_refit_amendment_snapshot_v1(
        "outputs/post_stage4a_staged_refit_v1"
      )
  )) {
    stop("STAGE2_BLOCK_SLOPE_HISTORY_GATE: Stage 1 changed",
         call. = FALSE)
  }
  if (!identical(
      historical_parent_before, staged_refit_parent_hash_snapshot_v1()
  )) {
    stop("STAGE2_BLOCK_SLOPE_HISTORY_GATE: parent changed",
         call. = FALSE)
  }

  execution <- list(
    execution_version = stage2_block_slope_version_v1(),
    analysis_status = "post_result_exploratory_uncertainty_diagnostic",
    execution_code_commit = execution_code_commit,
    execution_code_source_state =
      "additive_versioned_files_recorded_by_sha256",
    execution_code_hashes = as.list(code_hashes),
    executed_at_utc = format(
      as.POSIXct(Sys.time(), tz = "UTC"),
      "%Y-%m-%dT%H:%M:%SZ"
    ),
    elapsed_seconds = as.numeric(
      difftime(Sys.time(), started, units = "secs")
    ),
    population = list(
      region = "SoG",
      years = c(2005L, 2025L),
      stage2_checklists = nrow(inputs$events),
      selected_species = nrow(selected),
      outcome = "conditional_positive_numeric_count",
      records_2026_plus_read = 0L
    ),
    selection_rule =
      "top_10_descending_link_scale_active_minus_pre14_count_estimate",
    interval_method =
      "REML profile likelihood for slope SD; squared endpoints for variance",
    full_block_aware_interval_calculation_run = FALSE,
    near_zero_rule = list(
      maximum_point_variance_each_species = 0.0025,
      maximum_interval_upper_variance_each_species = 0.01,
      near_zero_across_ten = near_zero_across_ten
    ),
    cluster_distribution = as.list(distribution[1L, , drop = FALSE]),
    joins = inputs$joins,
    protected_input_hashes = as.list(inputs$protected_hashes),
    herring_source_hash = inputs$herring_source_hash,
    historical_stage2_outputs_modified = FALSE,
    historical_stage1_outputs_modified = FALSE,
    historical_parent_outputs_modified = FALSE,
    privacy_column_gate = "PASS",
    next_action = if (near_zero_across_ten) {
      paste(
        "STOP_NO_FULL_BOOTSTRAP;",
        "REWRITE_SECTION_4_4_RATHER_THAN_DEFEND"
      )
    } else {
      "DO_NOT_INFER_FULL_BOOTSTRAP_DECISION_FROM_NEAR_ZERO_RULE"
    }
  )
  staged_refit_write_yaml_lf_v1(
    execution, file.path(output_root, "execution_record_v1.yml")
  )
  manifest <- staged_refit_output_manifest_v1(output_root)
  .post_stage4a_write_csv_v1(
    manifest, file.path(output_root, "output_hash_manifest_v1.csv")
  )
  message(
    "STAGE2_BLOCK_SLOPE_DIAGNOSTIC=PASS near_zero_across_ten=",
    near_zero_across_ten
  )
  invisible(list(
    selected = selected,
    results = results,
    distribution = distribution,
    near_zero_across_ten = near_zero_across_ten
  ))
}
