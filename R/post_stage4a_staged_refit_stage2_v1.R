staged_refit_s2_version_v1 <- function() {
  "post_stage4a_staged_refit_v1_s2_detectability"
}

staged_refit_s2_gate_v1 <- function(
    path =
      "metadata/post_stage4a_staged_refit_stage2_authorization_v1.yml") {
  if (!file.exists(path)) {
    stop("STAGED_REFIT_S2_AUTHORIZATION_GATE: record unavailable",
         call. = FALSE)
  }
  record <- yaml::read_yaml(path)
  expected_terms <- c(
    "minutes_from_sunrise",
    "sin_2pi_doy_365", "cos_2pi_doy_365",
    "sin_4pi_doy_365", "cos_4pi_doy_365"
  )
  if (
    !identical(
      record$authorization_version,
      "post_stage4a_staged_refit_stage2_authorization_v1"
    ) ||
      !identical(
        record$decision,
        "ADOPT_START_DATE_STAGE1_AND_AUTHORIZE_STAGE2_DETECTABILITY_V1"
      ) ||
      !identical(record$authorized_stage$stage, "s2_detectability") ||
      !identical(
        unlist(record$authorized_stage$only_added_fixed_effects),
        expected_terms
      ) ||
      !identical(
        record$adopted_stage1_result$anchor,
        "first_recorded_spawn_date_at_location"
      ) ||
      !identical(record$stage_gate$stage3_authorized_by_this_record, FALSE) ||
      !identical(record$stage_gate$required_stop,
                 "report_stage2_before_stage3")
  ) {
    stop("STAGED_REFIT_S2_AUTHORIZATION_GATE: scope mismatch",
         call. = FALSE)
  }
  invisible(record)
}

staged_refit_s2_detectability_terms_v1 <- function() {
  c(
    "minutes_from_sunrise",
    "sin_2pi_doy_365", "cos_2pi_doy_365",
    "sin_4pi_doy_365", "cos_4pi_doy_365"
  )
}

staged_refit_s2_formula_v1 <- function(response) {
  fixed <- c(
    post_stage4a_exposure_terms_v1(),
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

staged_refit_s2_effort_formula_v1 <- function(response_column) {
  effort_terms <- c(
    "log_duration", "log_effort_distance", "observer_count"
  )
  if (!response_column %in% effort_terms) {
    stop("STAGED_REFIT_S2_EFFORT_FORMULA_GATE: response",
         call. = FALSE)
  }
  fixed <- c(
    post_stage4a_exposure_terms_v1(),
    "factor(checklist_year)", "protocol",
    setdiff(effort_terms, response_column),
    staged_refit_s2_detectability_terms_v1()
  )
  stats::as.formula(paste(
    response_column, "~", paste(fixed, collapse = " + "),
    "+ (1 | event_block_token) + (1 | observer_cluster_token) +",
    "(1 | location_cluster_token)"
  ))
}

staged_refit_s2_distance_formula_v1 <- function(response) {
  fixed <- c(
    post_stage4a_distance_band_terms_v2(),
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

staged_refit_s2_read_detectability_v1 <- function(
    path = file.path(
      "data", "derived", "post_stage4a_staged_refit_stage2_v1",
      "stage2_detectability_covariates.tsv.gz"
    )) {
  if (!file.exists(path)) {
    stop("STAGED_REFIT_S2_DETECTABILITY_GATE: protected cache unavailable",
         call. = FALSE)
  }
  dat <- .stage4a_read_gz(path)
  required <- c(
    "analysis_event_token", "checklist_year",
    "start_time_present", "start_time_syntax_valid", "coordinate_valid",
    "stage2_covariates_complete", "missingness_status",
    staged_refit_s2_detectability_terms_v1()
  )
  if (
    !all(required %in% names(dat)) ||
      nrow(dat) != 217200L ||
      anyDuplicated(dat$analysis_event_token) ||
      any(as.integer(dat$checklist_year) > 2025L) ||
      any(grepl(
        "latitude|longitude|observer|locality|source_id|analysis_id",
        names(dat), ignore.case = TRUE
      ))
  ) {
    stop("STAGED_REFIT_S2_DETECTABILITY_GATE: schema or cardinality",
         call. = FALSE)
  }
  logical_columns <- c(
    "start_time_present", "start_time_syntax_valid", "coordinate_valid",
    "stage2_covariates_complete"
  )
  for (name in logical_columns) {
    dat[[name]] <- toupper(trimws(as.character(dat[[name]]))) %in%
      c("TRUE", "T", "1", "YES")
  }
  numeric_columns <- c(
    "checklist_year", "day_of_year",
    staged_refit_s2_detectability_terms_v1()
  )
  for (name in numeric_columns) {
    dat[[name]] <- suppressWarnings(as.numeric(dat[[name]]))
  }
  complete <- dat$stage2_covariates_complete
  if (
    anyNA(complete) ||
      any(!is.finite(as.matrix(
        dat[complete, staged_refit_s2_detectability_terms_v1(),
            drop = FALSE]
      ))) ||
      any(dat$day_of_year[complete] < 1 |
          dat$day_of_year[complete] > 366)
  ) {
    stop("STAGED_REFIT_S2_DETECTABILITY_GATE: invalid complete row",
         call. = FALSE)
  }
  dat
}

staged_refit_s2_attach_detectability_v1 <- function(events, detectability) {
  if (
    nrow(events) != 217200L ||
      anyDuplicated(events$analysis_event_token) ||
      anyDuplicated(detectability$analysis_event_token)
  ) {
    stop("STAGED_REFIT_S2_JOIN_GATE: source keys", call. = FALSE)
  }
  index <- match(
    as.character(events$analysis_event_token),
    as.character(detectability$analysis_event_token)
  )
  if (
    anyNA(index) ||
      any(as.integer(events$checklist_year) !=
          as.integer(detectability$checklist_year[index]))
  ) {
    stop("STAGED_REFIT_S2_JOIN_GATE: one-to-one match failed",
         call. = FALSE)
  }
  joined <- events
  add <- c(
    "start_time_present", "start_time_syntax_valid", "coordinate_valid",
    "stage2_covariates_complete", "missingness_status",
    staged_refit_s2_detectability_terms_v1()
  )
  joined[add] <- detectability[index, add, drop = FALSE]
  if (nrow(joined) != nrow(events)) {
    stop("STAGED_REFIT_S2_JOIN_GATE: row multiplication",
         call. = FALSE)
  }

  total <- nrow(joined)
  metrics <- data.frame(
    metric = c(
      "eligible_checklists", "start_time_present",
      "start_time_syntax_valid", "coordinate_valid",
      "stage2_covariates_complete"
    ),
    category = "overall",
    n = c(
      total,
      sum(joined$start_time_present),
      sum(joined$start_time_syntax_valid),
      sum(joined$coordinate_valid),
      sum(joined$stage2_covariates_complete)
    ),
    stringsAsFactors = FALSE
  )
  status <- as.data.frame(table(
    factor(joined$missingness_status),
    useNA = "ifany"
  ), stringsAsFactors = FALSE)
  names(status) <- c("category", "n")
  status$metric <- "missingness_status"
  status <- status[, c("metric", "category", "n")]
  coverage <- rbind(metrics, status)
  coverage$denominator <- total
  coverage$percent <- 100 * coverage$n / total
  coverage$missingness_rule <- paste(
    "complete-case: valid local start time, observation date, WGS84",
    "coordinate and computable sunrise; no imputation; Stage 1 remains primary"
  )
  coverage$timezone <- "America/Vancouver"
  coverage$sunrise_algorithm <- "NOAA_90.833_degree_zenith_v1"
  coverage$day_of_year_rule <- "local date; denominator 365; harmonics 1 and 2"

  complete_events <- joined[
    joined$stage2_covariates_complete, , drop = FALSE
  ]
  if (
    !nrow(complete_events) ||
      anyDuplicated(complete_events$analysis_event_token)
  ) {
    stop("STAGED_REFIT_S2_COVERAGE_GATE: no valid model population",
         call. = FALSE)
  }
  list(
    events = complete_events,
    coverage = coverage,
    total = total,
    complete = nrow(complete_events)
  )
}

staged_refit_s2_fit_component_v1 <- function(
    dat, taxon_id, unit_label, analysis_role, outcome,
    checkpoint_path, cache_signature) {
  old_formula <- get("post_stage4a_formula_v1", envir = .GlobalEnv)
  assign(
    "post_stage4a_formula_v1",
    staged_refit_s2_formula_v1,
    envir = .GlobalEnv
  )
  on.exit(assign(
    "post_stage4a_formula_v1", old_formula, envir = .GlobalEnv
  ), add = TRUE)
  result <- staged_refit_s1_fit_component_v1(
    dat, taxon_id, unit_label, analysis_role, outcome,
    checkpoint_path, cache_signature
  )
  result$contrasts$analysis_version <- staged_refit_s2_version_v1()
  result$contrasts$stage <- "s2_detectability"
  result$diagnostic$analysis_version <- staged_refit_s2_version_v1()
  result$diagnostic$stage <- "s2_detectability"
  result
}

staged_refit_s2_process_core_taxon_v1 <- function(
    taxon_id, events, states, masks, species_registry,
    checkpoint_dir, run_signature) {
  unit_label <- species_registry$common_name[
    match(taxon_id, species_registry$analysis_taxon_id)
  ]
  if (length(unit_label) != 1L || is.na(unit_label) || !nzchar(unit_label)) {
    stop("STAGED_REFIT_S2_TAXON_GATE: unresolved core taxon",
         call. = FALSE)
  }
  dat <- stage4a_materialize_taxon(events, states, masks, taxon_id)
  models <- lapply(
    c("checklist_reporting", "conditional_positive_numeric_count"),
    function(outcome) {
      checkpoint <- file.path(
        checkpoint_dir, paste(taxon_id, outcome, "rds", sep = "_")
      )
      staged_refit_s2_fit_component_v1(
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

staged_refit_s2_parallel_core_v1 <- function(
    taxa, events, states, masks, species_registry,
    checkpoint_dir, run_signature, workers) {
  if (!length(taxa)) return(list())
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(checkpoint_dir)) {
    stop("STAGED_REFIT_S2_CHECKPOINT_GATE: directory unavailable",
         call. = FALSE)
  }
  workers <- min(as.integer(workers), length(taxa))
  fit_one <- function(taxon_id) {
    staged_refit_s2_process_core_taxon_v1(
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
      source(
        file.path("R", "post_stage4a_sog_event_study_v1.R"),
        local = FALSE
      )
      source(
        file.path("R", "post_stage4a_distance_band_sensitivity_v2.R"),
        local = FALSE
      )
      source(
        file.path("R", "post_stage4a_staged_refit_v1.R"),
        local = FALSE
      )
      source(
        file.path("R", "post_stage4a_staged_refit_amendment_v1.R"),
        local = FALSE
      )
      source(
        file.path("R", "post_stage4a_staged_refit_stage2_v1.R"),
        local = FALSE
      )
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
      staged_refit_s2_process_core_taxon_v1(
        taxon_id, events, states, masks, species_registry,
        checkpoint_dir, run_signature
      )
    })
  }, finally = {
    parallel::stopCluster(cluster)
  })
}

staged_refit_s2_finalize_family_v1 <- function(
    results, core_taxa, family_prefix, analysis_variant) {
  results <- results[core_taxa]
  contrasts <- staged_refit_adjust_bh_v1(
    staged_refit_flatten_models_v1(results, "contrasts"),
    family_prefix
  )
  primary <- contrasts[
    contrasts$comparison == "active_minus_pre14",
    ,
    drop = FALSE
  ]
  diagnostics <- staged_refit_flatten_models_v1(
    results, "diagnostic"
  )
  if (
    nrow(primary) != 98L ||
      nrow(diagnostics) != 98L ||
      anyDuplicated(paste(
        primary$analysis_taxon_id, primary$outcome, sep = "\r"
      ))
  ) {
    stop("STAGED_REFIT_S2_FAMILY_GATE: expected 49 x 2",
         call. = FALSE)
  }
  primary$analysis_variant <- analysis_variant
  diagnostics$analysis_variant <- analysis_variant
  list(
    primary = primary,
    contrasts = contrasts,
    diagnostics = diagnostics
  )
}

staged_refit_s2_fit_controls_v1 <- function(
    denominators, checkpoint_dir, run_signature) {
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)
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
        staged_refit_s2_fit_component_v1(
          info$data, info$taxon_id, species,
          "terrestrial_attention_displacement", outcome,
          checkpoint,
          paste(run_signature, species, outcome, sep = "|")
        )
      }
    )
    names(results[[species]]) <- c(
      "checklist_reporting", "conditional_positive_numeric_count"
    )
  }
  effects <- staged_refit_adjust_bh_v1(
    staged_refit_flatten_models_v1(results, "contrasts"),
    "terrestrial_displacement_2_species_s2"
  )
  effects$reporting_role <-
    "terrestrial_attention_displacement_not_negative_control"
  diagnostics <- staged_refit_flatten_models_v1(
    results, "diagnostic"
  )
  diagnostics$reporting_role <-
    "terrestrial_attention_displacement_not_negative_control"
  list(effects = effects, diagnostics = diagnostics)
}

staged_refit_s2_fit_pool_v1 <- function(
    pooled, checkpoint_path, cache_signature) {
  result <- staged_refit_s2_fit_component_v1(
    pooled$data,
    pooled$taxon_id,
    pooled$species,
    "terrestrial_attention_displacement_pool",
    "checklist_reporting",
    checkpoint_path,
    cache_signature
  )
  effect <- result$contrasts[
    result$contrasts$comparison == "active_minus_pre14",
    ,
    drop = FALSE
  ]
  effect$reporting_role <-
    "terrestrial_attention_displacement_not_negative_control"
  list(effect = effect, diagnostic = result$diagnostic)
}

staged_refit_s2_fit_effort_set_v1 <- function(
    events, checkpoint_dir, cache_signature) {
  old_formula <- get(
    "staged_refit_amendment_effort_formula_v1",
    envir = .GlobalEnv
  )
  assign(
    "staged_refit_amendment_effort_formula_v1",
    staged_refit_s2_effort_formula_v1,
    envir = .GlobalEnv
  )
  on.exit(assign(
    "staged_refit_amendment_effort_formula_v1",
    old_formula,
    envir = .GlobalEnv
  ), add = TRUE)
  result <- staged_refit_amendment_fit_effort_set_v1(
    events,
    checkpoint_dir,
    cache_signature,
    "real_start_anchor_s2_detectability"
  )
  result$effects$stage <- "s2_detectability"
  result$effects$amendment_version <-
    "post_stage4a_staged_refit_stage2_v1"
  result$diagnostics$stage <- "s2_detectability"
  result$diagnostics$amendment_version <-
    "post_stage4a_staged_refit_stage2_v1"
  result
}

staged_refit_s2_distance_analysis_v1 <- function(
    distance_events, states, masks, species_registry,
    terrestrial_denominators, checkpoint_dir, run_signature) {
  old_formula <- get(
    "post_stage4a_distance_band_formula_v2",
    envir = .GlobalEnv
  )
  assign(
    "post_stage4a_distance_band_formula_v2",
    staged_refit_s2_distance_formula_v1,
    envir = .GlobalEnv
  )
  on.exit(assign(
    "post_stage4a_distance_band_formula_v2",
    old_formula,
    envir = .GlobalEnv
  ), add = TRUE)
  result <- staged_refit_distance_analysis_v1(
    distance_events, states, masks, species_registry,
    terrestrial_denominators, checkpoint_dir, run_signature
  )
  result$effects$stage <- "s2_detectability"
  result$effects$model_version_id <- gsub(
    "SOG_STAGED_REFIT_S1_DISTANCE",
    "SOG_STAGED_REFIT_S2_DISTANCE",
    result$effects$model_version_id,
    fixed = TRUE
  )
  result$diagnostics$model_version_id <- gsub(
    "SOG_STAGED_REFIT_S1_DISTANCE",
    "SOG_STAGED_REFIT_S2_DISTANCE",
    result$diagnostics$model_version_id,
    fixed = TRUE
  )
  result
}

staged_refit_s2_delta_v1 <- function(stage2, stage1, label) {
  stage2_key <- paste(
    stage2$analysis_taxon_id, stage2$outcome, sep = "\r"
  )
  stage1_key <- paste(
    stage1$analysis_taxon_id, stage1$outcome, sep = "\r"
  )
  if (
    length(stage2_key) != 98L ||
      length(stage1_key) != 98L ||
      anyDuplicated(stage2_key) ||
      anyDuplicated(stage1_key)
  ) {
    stop("STAGED_REFIT_S2_DELTA_GATE: key cardinality",
         call. = FALSE)
  }
  index <- match(stage2_key, stage1_key)
  if (anyNA(index)) {
    stop("STAGED_REFIT_S2_DELTA_GATE: unmatched", call. = FALSE)
  }
  data.frame(
    analysis_variant = label,
    analysis_taxon_id = stage2$analysis_taxon_id,
    species = stage2$species,
    outcome = stage2$outcome,
    s1_estimate = stage1$estimate[index],
    s2_estimate = stage2$estimate,
    estimate_delta = stage2$estimate - stage1$estimate[index],
    s1_ratio = stage1$ratio[index],
    s2_ratio = stage2$ratio,
    s1_q_value = stage1$q_value[index],
    s2_q_value = stage2$q_value,
    changed_direction =
      sign(stage2$estimate) != sign(stage1$estimate[index]),
    changed_bh_significance =
      (stage2$q_value < 0.05) != (stage1$q_value[index] < 0.05),
    s1_status = stage1$status[index],
    s2_status = stage2$status,
    stringsAsFactors = FALSE
  )
}

staged_refit_s2_guild_delta_v1 <- function(
    guild_stage2,
    stage1_path = file.path(
      "outputs", "post_stage4a_staged_refit_v1",
      "s1_anchor", "guild_timing.csv"
    )) {
  stage1 <- utils::read.csv(stage1_path, stringsAsFactors = FALSE)
  key2 <- paste(guild_stage2$outcome, guild_stage2$guild, sep = "\r")
  key1 <- paste(stage1$outcome, stage1$guild, sep = "\r")
  index <- match(key2, key1)
  if (
    nrow(guild_stage2) != 14L ||
      nrow(stage1) != 14L ||
      anyDuplicated(key2) ||
      anyDuplicated(key1) ||
      anyNA(index)
  ) {
    stop("STAGED_REFIT_S2_GUILD_DELTA_GATE: one-to-one join",
         call. = FALSE)
  }
  guild_stage2$stage <- "s2_detectability"
  guild_stage2$s1_estimate <- stage1$estimate[index]
  guild_stage2$s1_standard_error <- stage1$standard_error[index]
  guild_stage2$s1_p_guild_differences <-
    stage1$p_guild_differences[index]
  guild_stage2$s1_q_between <- stage1$q_between[index]
  guild_stage2$changed_direction <-
    sign(guild_stage2$estimate) != sign(stage1$estimate[index])
  guild_stage2$changed_omnibus_significance <-
    (guild_stage2$p_guild_differences < 0.05) !=
    (stage1$p_guild_differences[index] < 0.05)
  guild_stage2
}

staged_refit_s2_classify_magnitude_v1 <- function(
    stage1_value, stage2_value, hold_band = 0.10) {
  if (
    !is.finite(stage1_value) ||
      !is.finite(stage2_value) ||
      abs(stage1_value) < .Machine$double.eps
  ) {
    return("not_classifiable")
  }
  ratio <- abs(stage2_value) / abs(stage1_value)
  if (ratio < 1 - hold_band) {
    "weakens"
  } else if (ratio > 1 + hold_band) {
    "strengthens"
  } else {
    "holds"
  }
}

staged_refit_s2_bind_rows_v1 <- function(...) {
  pieces <- list(...)
  pieces <- pieces[vapply(pieces, is.data.frame, logical(1L))]
  names_all <- Reduce(union, lapply(pieces, names))
  aligned <- lapply(pieces, function(x) {
    for (name in setdiff(names_all, names(x))) x[[name]] <- NA
    x[, names_all, drop = FALSE]
  })
  do.call(rbind, aligned)
}

staged_refit_s2_comparison_summary_v1 <- function(
    terrestrial_s2, pool_s2, guild_s2, effort_s2,
    placebo_s2, terrestrial_s1_path = file.path(
      "outputs", "post_stage4a_staged_refit_v1",
      "negative_controls_all_stages.csv"
    ),
    pool_s1_path = file.path(
      "outputs", "post_stage4a_staged_refit_amendment_v1",
      "s1_anchor_amendment", "pooled_terrestrial_displacement.csv"
    ),
    effort_s1_path = file.path(
      "outputs", "post_stage4a_staged_refit_amendment_v1",
      "s1_anchor_amendment", "effort_negative_control_outcomes.csv"
    ),
    placebo_s1_path = file.path(
      "outputs", "post_stage4a_staged_refit_amendment_v1",
      "s1_anchor_amendment", "placebo_estimates_49x2.csv"
    )) {
  terrestrial_s1 <- utils::read.csv(
    terrestrial_s1_path, stringsAsFactors = FALSE
  )
  terrestrial_s1 <- terrestrial_s1[
    terrestrial_s1$comparison == "active_minus_pre14" &
      terrestrial_s1$outcome == "checklist_reporting",
    ,
    drop = FALSE
  ]
  terrestrial_s2 <- terrestrial_s2[
    terrestrial_s2$comparison == "active_minus_pre14" &
      terrestrial_s2$outcome == "checklist_reporting",
    ,
    drop = FALSE
  ]
  pool_s1 <- utils::read.csv(pool_s1_path, stringsAsFactors = FALSE)
  pool_s1 <- pool_s1[
    pool_s1$analysis_variant == "real_start_anchor", , drop = FALSE
  ]
  effort_s1 <- utils::read.csv(effort_s1_path, stringsAsFactors = FALSE)
  duration_s1 <- effort_s1[
    effort_s1$outcome == "log_duration_minutes", , drop = FALSE
  ]
  duration_s2 <- effort_s2[
    effort_s2$outcome == "log_duration_minutes", , drop = FALSE
  ]
  placebo_s1 <- utils::read.csv(
    placebo_s1_path, stringsAsFactors = FALSE
  )
  placebo_s1 <- placebo_s1[
    placebo_s1$offset_days == 90 &
      placebo_s1$species == "Dunlin" &
      placebo_s1$outcome == "checklist_reporting",
    ,
    drop = FALSE
  ]
  placebo_s2 <- placebo_s2[
    placebo_s2$species == "Dunlin" &
      placebo_s2$outcome == "checklist_reporting",
    ,
    drop = FALSE
  ]
  guild_reporting <- guild_s2[
    guild_s2$outcome == "checklist_reporting", , drop = FALSE
  ]
  if (
    nrow(terrestrial_s1) != 2L ||
      nrow(terrestrial_s2) != 2L ||
      nrow(pool_s1) != 1L ||
      nrow(pool_s2) != 1L ||
      nrow(duration_s1) != 1L ||
      nrow(duration_s2) != 1L ||
      nrow(placebo_s1) != 1L ||
      nrow(placebo_s2) != 1L ||
      nrow(guild_reporting) != 7L
  ) {
    stop("STAGED_REFIT_S2_REQUIRED_COMPARISON_GATE: cardinality",
         call. = FALSE)
  }

  rows <- list()
  for (species in c("American Robin", "Chestnut-backed Chickadee")) {
    x1 <- terrestrial_s1[terrestrial_s1$species == species, ]
    x2 <- terrestrial_s2[terrestrial_s2$species == species, ]
    rows[[length(rows) + 1L]] <- data.frame(
      requested_result = paste0(
        "terrestrial_displacement_", gsub(" ", "_", tolower(species))
      ),
      unit = species,
      comparison = "active_minus_pre14_reporting",
      s1_estimate = x1$estimate,
      s2_estimate = x2$estimate,
      s1_ratio = x1$ratio,
      s2_ratio = x2$ratio,
      s1_p_value = x1$p_value,
      s2_p_value = x2$p_value,
      s1_q_value = x1$q_value,
      s2_q_value = x2$q_value,
      change_classification = staged_refit_s2_classify_magnitude_v1(
        x1$estimate, x2$estimate
      ),
      sign_preserved = sign(x1$estimate) == sign(x2$estimate),
      survives_nominal_0_05 = x2$p_value < 0.05,
      survives_bh_0_05 = x2$q_value < 0.05,
      stringsAsFactors = FALSE
    )
  }
  rows[[length(rows) + 1L]] <- data.frame(
    requested_result = "terrestrial_displacement_pooled",
    unit = "American Robin + Chestnut-backed Chickadee",
    comparison = "active_minus_pre14_reporting",
    s1_estimate = pool_s1$estimate,
    s2_estimate = pool_s2$estimate,
    s1_ratio = pool_s1$ratio,
    s2_ratio = pool_s2$ratio,
    s1_p_value = pool_s1$p_value,
    s2_p_value = pool_s2$p_value,
    s1_q_value = NA_real_,
    s2_q_value = NA_real_,
    change_classification = staged_refit_s2_classify_magnitude_v1(
      pool_s1$estimate, pool_s2$estimate
    ),
    sign_preserved = sign(pool_s1$estimate) == sign(pool_s2$estimate),
    survives_nominal_0_05 = pool_s2$p_value < 0.05,
    survives_bh_0_05 = NA,
    stringsAsFactors = FALSE
  )
  rows[[length(rows) + 1L]] <- data.frame(
    requested_result = "reporting_guild_timing_omnibus",
    unit = "seven reporting guilds",
    comparison = "spawn_start_minus_early_egg_omnibus",
    s1_estimate = guild_reporting$s1_q_between[[1L]],
    s2_estimate = guild_reporting$q_between[[1L]],
    s1_ratio = NA_real_,
    s2_ratio = NA_real_,
    s1_p_value = guild_reporting$s1_p_guild_differences[[1L]],
    s2_p_value = guild_reporting$p_guild_differences[[1L]],
    s1_q_value = NA_real_,
    s2_q_value = NA_real_,
    change_classification = staged_refit_s2_classify_magnitude_v1(
      guild_reporting$s1_q_between[[1L]],
      guild_reporting$q_between[[1L]]
    ),
    sign_preserved = NA,
    survives_nominal_0_05 =
      guild_reporting$p_guild_differences[[1L]] < 0.05,
    survives_bh_0_05 = NA,
    stringsAsFactors = FALSE
  )
  rows[[length(rows) + 1L]] <- data.frame(
    requested_result = "duration_negative_control",
    unit = "log duration minutes",
    comparison = "active_minus_pre14",
    s1_estimate = duration_s1$estimate,
    s2_estimate = duration_s2$estimate,
    s1_ratio = duration_s1$multiplicative_effect,
    s2_ratio = duration_s2$multiplicative_effect,
    s1_p_value = duration_s1$p_value,
    s2_p_value = duration_s2$p_value,
    s1_q_value = duration_s1$q_value_bh_3_outcomes,
    s2_q_value = duration_s2$q_value_bh_3_outcomes,
    change_classification = staged_refit_s2_classify_magnitude_v1(
      duration_s1$estimate, duration_s2$estimate
    ),
    sign_preserved =
      sign(duration_s1$estimate) == sign(duration_s2$estimate),
    survives_nominal_0_05 = duration_s2$p_value < 0.05,
    survives_bh_0_05 =
      duration_s2$q_value_bh_3_outcomes < 0.05,
    stringsAsFactors = FALSE
  )
  rows[[length(rows) + 1L]] <- data.frame(
    requested_result = "placebo_p90_positive_reporting_hit",
    unit = "Dunlin",
    comparison = "active_minus_pre14_reporting",
    s1_estimate = placebo_s1$estimate,
    s2_estimate = placebo_s2$estimate,
    s1_ratio = placebo_s1$ratio,
    s2_ratio = placebo_s2$ratio,
    s1_p_value = placebo_s1$p_value,
    s2_p_value = placebo_s2$p_value,
    s1_q_value = placebo_s1$q_value,
    s2_q_value = placebo_s2$q_value,
    change_classification = staged_refit_s2_classify_magnitude_v1(
      placebo_s1$estimate, placebo_s2$estimate
    ),
    sign_preserved =
      sign(placebo_s1$estimate) == sign(placebo_s2$estimate),
    survives_nominal_0_05 = placebo_s2$p_value < 0.05,
    survives_bh_0_05 = placebo_s2$q_value < 0.05,
    stringsAsFactors = FALSE
  )
  result <- do.call(rbind, rows)
  result$classification_rule <- paste(
    "absolute log-effect (or omnibus Q) ratio: weakens <0.90,",
    "holds 0.90-1.10, strengthens >1.10"
  )
  result$leading_alternative_explanation <-
    "unmodelled_seasonal_reporting_trend"
  result
}

staged_refit_s2_verify_manifest_v1 <- function(root) {
  path <- file.path(root, "output_hash_manifest_v1.csv")
  if (!file.exists(path)) {
    stop("STAGED_REFIT_S2_HISTORY_GATE: manifest unavailable",
         call. = FALSE)
  }
  manifest <- utils::read.csv(path, stringsAsFactors = FALSE)
  if (
    anyDuplicated(manifest$file) ||
      !all(file.exists(manifest$file)) ||
      any(vapply(
        manifest$file, .post_stage4a_sha256_v1, character(1L)
      ) != manifest$sha256)
  ) {
    stop("STAGED_REFIT_S2_HISTORY_GATE: manifest failed",
         call. = FALSE)
  }
  invisible(manifest)
}

run_post_stage4a_staged_refit_s2_v1 <- function(
    execution_code_commit,
    output_root =
      "outputs/post_stage4a_staged_refit_stage2_v1") {
  started <- Sys.time()
  packages <- c("data.table", "digest", "lme4", "yaml")
  missing_packages <- packages[!vapply(
    packages, requireNamespace, logical(1L), quietly = TRUE
  )]
  if (length(missing_packages)) {
    stop("Missing packages: ", paste(missing_packages, collapse = ", "),
         call. = FALSE)
  }
  authorization <- staged_refit_authorization_gate_v1()
  staged_refit_amendment_gate_v1()
  staged_refit_s2_gate_v1()
  if (!identical(
      Sys.getenv("POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED"),
      authorization$environment_acknowledgement$value
  )) {
    stop("The exact author-set acknowledgement is required",
         call. = FALSE)
  }

  stage1_root <- "outputs/post_stage4a_staged_refit_v1"
  amendment_root <- "outputs/post_stage4a_staged_refit_amendment_v1"
  staged_refit_s2_verify_manifest_v1(stage1_root)
  staged_refit_s2_verify_manifest_v1(amendment_root)
  stage1_hashes_before <- staged_refit_amendment_snapshot_v1(stage1_root)
  amendment_hashes_before <-
    staged_refit_amendment_snapshot_v1(amendment_root)
  parent_hashes_before <- staged_refit_parent_hash_snapshot_v1()

  protected_files <- c(
    event_metadata =
      "data/derived/stage4a_protected/stage4a_event_metadata.tsv.gz",
    detectability = file.path(
      "data", "derived", "post_stage4a_staged_refit_stage2_v1",
      "stage2_detectability_covariates.tsv.gz"
    ),
    source_links_archived =
      "data/derived/stage3_phase2_protected/metadata_source_point_links.tsv.gz",
    source_links_extended = paste0(
      "data/derived/",
      "post_stage4a_distance_band_sensitivity_v2_protected/",
      "link_builder/metadata_source_point_links.tsv.gz"
    ),
    source_links_placebo = paste0(
      "data/derived/post_stage4a_staged_refit_amendment_v1/",
      "placebo_link_builder/metadata_source_point_links.tsv.gz"
    ),
    reported_states =
      "data/derived/stage4a_protected/stage4a_reported_states.tsv.gz",
    ambiguity_masks =
      "data/derived/stage4a_protected/stage4a_ambiguity_masks.tsv.gz",
    terrestrial_extract = paste0(
      "data/derived/",
      "post_stage4a_distance_band_followup_v1_protected/",
      "control_candidate_rows_pre2026.tsv"
    )
  )
  if (!all(file.exists(protected_files))) {
    stop("STAGED_REFIT_S2_INPUT_GATE: protected input unavailable",
         call. = FALSE)
  }
  protected_hashes <- vapply(
    protected_files, .post_stage4a_sha256_v1, character(1L)
  )
  expected_hashes <- c(
    event_metadata =
      "03eaccdd46b5cba779f596e7ce96dacd5a509f51f6eae4c5c79daf706879a9b2",
    source_links_archived =
      "f26197d0a71fd177e77774ec9e5596563c127ec8eb0f948042aff51ad805567b",
    source_links_extended =
      "06a34a4d3880f2dd3a969d9976b901eff855ff7362e86ae40d75a38edd697dc2",
    source_links_placebo =
      "2605fed6fd3e511dc634ce7ac684a54ec652730b261816bf903c2a8ff31b749c",
    reported_states =
      "0f02ac6bdbb561a8e4df58cc8d53340ec29f9519b85a99f4748cb8367fc33cb5",
    ambiguity_masks =
      "c0e063f8a8c6ccfb97535183d8e669a9f4bb1eaea31bae144dffa3d81d57d3ff",
    terrestrial_extract =
      "70ecae25e7cb8888c6ee6ffbfb307a8a44bd22402190f7cfb07ad286755f4195"
  )
  if (!identical(
      protected_hashes[names(expected_hashes)], expected_hashes
  )) {
    stop("STAGED_REFIT_S2_INPUT_HASH_GATE: frozen input mismatch",
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
    stop("STAGED_REFIT_S2_POPULATION_GATE: changed",
         call. = FALSE)
  }
  stage4a_validate_folds(events)

  detectability <- staged_refit_s2_read_detectability_v1(
    protected_files[["detectability"]]
  )
  detectability_join <- staged_refit_s2_attach_detectability_v1(
    events, detectability
  )
  model_tokens <- as.character(
    detectability_join$events$analysis_event_token
  )
  coverage <- detectability_join$coverage

  herring_path <- Sys.getenv("HERRING_EBIRD_V2_HERRING", unset = "")
  anchor_lookup <- staged_refit_build_anchor_lookup_v1(herring_path)
  archived_links <- .stage4a_read_gz(
    protected_files[["source_links_archived"]]
  )
  extended_links <- .stage4a_read_gz(
    protected_files[["source_links_extended"]]
  )
  widened_links <- .stage4a_read_gz(
    protected_files[["source_links_placebo"]]
  )
  anchored_links <- staged_refit_reanchor_links_v1(
    archived_links, anchor_lookup
  )
  real_joint <- post_stage4a_add_joint_exposure_v1(
    events, anchored_links
  )
  events_real_full <- real_joint$events
  rm(real_joint)
  real_detectability <- staged_refit_s2_attach_detectability_v1(
    events_real_full, detectability
  )
  events_real <- real_detectability$events
  if (!identical(
      as.character(events_real$analysis_event_token), model_tokens
  )) {
    stop("STAGED_REFIT_S2_REAL_JOIN_GATE: subset order changed",
         call. = FALSE)
  }

  placebo_joint <- staged_refit_amendment_placebo_events_v1(
    events, widened_links, anchor_lookup, 90L
  )
  placebo_detectability <- staged_refit_s2_attach_detectability_v1(
    placebo_joint$events, detectability
  )
  events_placebo <- placebo_detectability$events
  if (!identical(
      as.character(events_placebo$analysis_event_token), model_tokens
  )) {
    stop("STAGED_REFIT_S2_PLACEBO_JOIN_GATE: subset order changed",
         call. = FALSE)
  }

  distance_links <- staged_refit_distance_links_v1(
    archived_links, extended_links, anchor_lookup
  )
  distance_joint <- post_stage4a_add_distance_band_exposure_v2(
    events, distance_links
  )
  distance_detectability <- staged_refit_s2_attach_detectability_v1(
    distance_joint$events, detectability
  )
  events_distance <- distance_detectability$events
  if (!identical(
      as.character(events_distance$analysis_event_token), model_tokens
  )) {
    stop("STAGED_REFIT_S2_DISTANCE_JOIN_GATE: subset order changed",
         call. = FALSE)
  }

  states_all <- .stage4a_read_gz(protected_files[["reported_states"]])
  masks_all <- .stage4a_read_gz(protected_files[["ambiguity_masks"]])
  if (nrow(states_all) != 1169612L || nrow(masks_all) != 5834L) {
    stop("STAGED_REFIT_S2_STATE_GATE: cardinality",
         call. = FALSE)
  }
  states <- states_all[
    states_all$analysis_event_token %in% model_tokens, , drop = FALSE
  ]
  masks <- masks_all[
    masks_all$analysis_event_token %in% model_tokens, , drop = FALSE
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
  core_taxa <- support_registry$analysis_taxon_id[
    support_registry$named_species_recommendation == "named_species_core"
  ]
  if (
    length(core_taxa) != 49L ||
      anyDuplicated(core_taxa) ||
      anyDuplicated(species_registry$analysis_taxon_id)
  ) {
    stop("STAGED_REFIT_S2_FAMILY_GATE: fixed 49",
         call. = FALSE)
  }
  priority_names <- c(
    "Bald Eagle", "Glaucous-winged Gull", "Dunlin"
  )
  priority_taxa <- species_registry$analysis_taxon_id[
    match(priority_names, species_registry$common_name)
  ]
  if (anyNA(priority_taxa) || !all(priority_taxa %in% core_taxa)) {
    stop("STAGED_REFIT_S2_PRIORITY_GATE: unresolved",
         call. = FALSE)
  }
  remaining_taxa <- setdiff(core_taxa, priority_taxa)
  workers <- post_stage4a_worker_count_v1(length(core_taxa))

  protected_root <- file.path(
    "data", "derived", "post_stage4a_staged_refit_stage2_v1"
  )
  checkpoint_root <- file.path(protected_root, "checkpoints")
  dir.create(checkpoint_root, recursive = TRUE, showWarnings = FALSE)
  code_signature <- paste(
    execution_code_commit,
    .post_stage4a_sha256_v1(
      "R/post_stage4a_staged_refit_stage2_v1.R"
    ),
    .post_stage4a_sha256_v1(
      "metadata/post_stage4a_staged_refit_stage2_authorization_v1.yml"
    ),
    protected_hashes,
    attr(anchor_lookup, "source_hash"),
    sep = "|",
    collapse = "|"
  )

  priority_started <- Sys.time()
  terrestrial_denominators <- staged_refit_load_control_denominators_v1(
    events_real, protected_files[["terrestrial_extract"]]
  )
  terrestrial <- staged_refit_s2_fit_controls_v1(
    terrestrial_denominators,
    file.path(checkpoint_root, "terrestrial_displacement"),
    code_signature
  )
  pooled <- staged_refit_amendment_pool_control_v1(
    terrestrial_denominators
  )
  pooled_fit <- staged_refit_s2_fit_pool_v1(
    pooled,
    file.path(checkpoint_root, "terrestrial_pool.rds"),
    paste(code_signature, "terrestrial_pool", sep = "|")
  )
  effort <- staged_refit_s2_fit_effort_set_v1(
    events_real,
    file.path(checkpoint_root, "effort_outcomes"),
    code_signature
  )
  real_priority <- staged_refit_s2_parallel_core_v1(
    priority_taxa, events_real, states, masks, species_registry,
    file.path(checkpoint_root, "real_family"),
    paste(code_signature, "real_family", sep = "|"),
    workers
  )
  names(real_priority) <- priority_taxa
  placebo_priority <- staged_refit_s2_parallel_core_v1(
    priority_taxa, events_placebo, states, masks, species_registry,
    file.path(checkpoint_root, "placebo_p90_family"),
    paste(code_signature, "placebo_p90_family", sep = "|"),
    workers
  )
  names(placebo_priority) <- priority_taxa
  priority_elapsed <- as.numeric(
    difftime(Sys.time(), priority_started, units = "secs")
  )

  full_started <- Sys.time()
  real_remaining <- staged_refit_s2_parallel_core_v1(
    remaining_taxa, events_real, states, masks, species_registry,
    file.path(checkpoint_root, "real_family"),
    paste(code_signature, "real_family", sep = "|"),
    workers
  )
  names(real_remaining) <- remaining_taxa
  placebo_remaining <- staged_refit_s2_parallel_core_v1(
    remaining_taxa, events_placebo, states, masks, species_registry,
    file.path(checkpoint_root, "placebo_p90_family"),
    paste(code_signature, "placebo_p90_family", sep = "|"),
    workers
  )
  names(placebo_remaining) <- remaining_taxa
  full_elapsed <- as.numeric(
    difftime(Sys.time(), full_started, units = "secs")
  )
  real_family <- staged_refit_s2_finalize_family_v1(
    c(real_priority, real_remaining),
    core_taxa,
    "s2_detectability__fixed_49_species",
    "real_start_anchor_s2_detectability"
  )
  placebo_family <- staged_refit_s2_finalize_family_v1(
    c(placebo_priority, placebo_remaining),
    core_taxa,
    "s2_detectability_placebo_p90__fixed_49_species",
    "placebo_offset_p90_s2_detectability"
  )
  placebo_family$primary$offset_days <- 90L
  placebo_family$primary$placebo_seed <- 20260727L
  placebo_family$diagnostics$offset_days <- 90L
  real_family$diagnostics$offset_days <- NA_integer_

  stage1_primary <- utils::read.csv(
    file.path(
      stage1_root, "s1_anchor", "estimates_49x2.csv"
    ),
    stringsAsFactors = FALSE
  )
  delta <- staged_refit_s2_delta_v1(
    real_family$primary,
    stage1_primary,
    "s2_detectability_vs_s1_start_anchor"
  )
  stage1_placebo <- utils::read.csv(
    file.path(
      amendment_root, "s1_anchor_amendment",
      "placebo_estimates_49x2.csv"
    ),
    stringsAsFactors = FALSE
  )
  stage1_placebo <- stage1_placebo[
    stage1_placebo$offset_days == 90, , drop = FALSE
  ]
  placebo_delta <- staged_refit_s2_delta_v1(
    placebo_family$primary,
    stage1_placebo,
    "placebo_p90_s2_vs_s1"
  )
  placebo_tallies <- staged_refit_amendment_tally_v1(
    placebo_family$primary, 90L, real_reporting = 14L, real_count = 19L
  )

  guild <- staged_refit_s2_guild_delta_v1(
    staged_refit_guild_timing_v1(
      real_family$contrasts, species_registry
    )
  )
  distance <- staged_refit_s2_distance_analysis_v1(
    events_distance, states, masks, species_registry,
    terrestrial_denominators,
    file.path(checkpoint_root, "distance_3species"),
    code_signature
  )

  terrestrial_primary <- terrestrial$effects[
    terrestrial$effects$comparison == "active_minus_pre14",
    ,
    drop = FALSE
  ]
  required_summary <- staged_refit_s2_comparison_summary_v1(
    terrestrial_primary,
    pooled_fit$effect,
    guild,
    effort$effects,
    placebo_family$primary
  )

  output_dir <- file.path(output_root, "s2_detectability")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  outputs <- list(
    coverage_start_time = coverage,
    estimates_49x2 = real_family$primary,
    delta_vs_s1 = delta,
    guild_timing = guild,
    distance_bands_3species = distance$effects,
    terrestrial_displacement_by_species = terrestrial_primary,
    pooled_terrestrial_displacement = pooled_fit$effect,
    effort_negative_control_outcomes = effort$effects,
    placebo_p90_estimates_49x2 = placebo_family$primary,
    placebo_p90_tallies = placebo_tallies,
    placebo_p90_delta_vs_s1 = placebo_delta,
    required_four_results_summary = required_summary,
    model_diagnostics = staged_refit_s2_bind_rows_v1(
      real_family$diagnostics,
      placebo_family$diagnostics
    ),
    terrestrial_diagnostics = terrestrial$diagnostics,
    effort_diagnostics = effort$diagnostics,
    pooled_terrestrial_diagnostics = pooled_fit$diagnostic,
    distance_diagnostics = distance$diagnostics
  )
  output_paths <- character()
  for (name in names(outputs)) {
    path <- file.path(output_dir, paste0(name, ".csv"))
    .post_stage4a_write_csv_v1(outputs[[name]], path)
    output_paths <- c(output_paths, path)
  }
  staged_refit_privacy_column_gate_v1(output_paths)

  if (!identical(
      stage1_hashes_before,
      staged_refit_amendment_snapshot_v1(stage1_root)
  )) {
    stop("STAGED_REFIT_S2_HISTORY_GATE: Stage 1 changed",
         call. = FALSE)
  }
  if (!identical(
      amendment_hashes_before,
      staged_refit_amendment_snapshot_v1(amendment_root)
  )) {
    stop("STAGED_REFIT_S2_HISTORY_GATE: amendment output changed",
         call. = FALSE)
  }
  if (!identical(
      parent_hashes_before, staged_refit_parent_hash_snapshot_v1()
  )) {
    stop("STAGED_REFIT_S2_HISTORY_GATE: parent output changed",
         call. = FALSE)
  }

  headline <- staged_refit_amendment_tally_v1(
    real_family$primary,
    offset_days = NA_integer_,
    real_reporting = 14L,
    real_count = 19L
  )
  model_issues <- staged_refit_model_issues_v1(
    staged_refit_s2_bind_rows_v1(
    real_family$diagnostics,
    placebo_family$diagnostics,
    terrestrial$diagnostics
  ))
  distance_issues <- distance$diagnostics[
    distance$diagnostics$status != "completed" |
      distance$diagnostics$singular_fit %in% TRUE |
      distance$diagnostics$converged %in% FALSE,
    ,
    drop = FALSE
  ]
  execution <- list(
    execution_version =
      "post_stage4a_staged_refit_stage2_execution_v1",
    completed_stages = list("s1_anchor_adopted", "s2_detectability"),
    stage1_adoption_record =
      "metadata/post_stage4a_staged_refit_stage2_authorization_v1.yml",
    analysis_status = "post_result_ecologically_motivated_refinement",
    execution_code_commit = execution_code_commit,
    executed_at_utc = format(
      as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"
    ),
    elapsed_seconds = as.numeric(
      difftime(Sys.time(), started, units = "secs")
    ),
    stage_timings_seconds = list(
      priority_case_displacement_effort_and_placebo =
        priority_elapsed,
      remaining_real_and_placebo_families = full_elapsed
    ),
    detectability = list(
      eligible_stage1_checklists = detectability_join$total,
      complete_stage2_checklists = detectability_join$complete,
      coverage_percent =
        100 * detectability_join$complete / detectability_join$total,
      missingness_rule = coverage$missingness_rule[[1L]],
      timezone = "America/Vancouver",
      sunrise_algorithm = "NOAA_90.833_degree_zenith_v1",
      annual_harmonics = "orders_1_and_2_denominator_365",
      observer_experience_covariate =
        "skipped_to_preserve_stage_isolation"
    ),
    engines = list(
      checklist_reporting = "lme4::glmer binomial nAGQ=0",
      conditional_positive_numeric_count = "lme4::lmer REML",
      effort_negative_control_outcomes = "lme4::lmer REML"
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
      stage1_eligible_checklists = nrow(events),
      stage2_complete_checklists = nrow(events_real),
      fixed_family_species = length(core_taxa),
      records_2026_plus_read = 0L
    ),
    joins = list(
      detectability_to_stage1_checklists =
        "one_to_one_217200_rows_PASS",
      links_to_anchor_lookup = "many_to_one_PASS",
      links_to_checklists =
        "many_to_one_then_aggregate_to_one_checklist_PASS",
      species_to_guild = "many_species_to_one_guild_PASS",
      stage2_to_stage1_primary = "one_to_one_98_rows_PASS",
      stage2_to_stage1_placebo_p90 = "one_to_one_98_rows_PASS",
      terrestrial_species_to_checklists =
        "two_species_same_checklist_denominator_PASS",
      archived_to_extended_distance_links =
        "one_to_one_archived_subset_PASS"
    ),
    headline_primary_contrast = lapply(
      seq_len(nrow(headline)),
      function(i) as.list(headline[i, , drop = FALSE])
    ),
    placebo_p90_tallies = lapply(
      seq_len(nrow(placebo_tallies)),
      function(i) as.list(placebo_tallies[i, , drop = FALSE])
    ),
    required_comparison_summary = lapply(
      seq_len(nrow(required_summary)),
      function(i) as.list(required_summary[i, , drop = FALSE])
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
    historical_stage1_output_hashes = as.list(stage1_hashes_before),
    historical_amendment_output_hashes =
      as.list(amendment_hashes_before),
    historical_stage1_outputs_modified = FALSE,
    historical_amendment_outputs_modified = FALSE,
    historical_parent_outputs_modified = FALSE,
    privacy_column_gate = "PASS",
    stage3_started = FALSE,
    gate = "PASS_PENDING_HUMAN_STAGE2_REVIEW_STOP_BEFORE_STAGE3"
  )
  staged_refit_write_yaml_lf_v1(
    execution, file.path(output_root, "execution_record_v1.yml")
  )
  manifest <- staged_refit_output_manifest_v1(output_root)
  .post_stage4a_write_csv_v1(
    manifest, file.path(output_root, "output_hash_manifest_v1.csv")
  )
  message(
    paste0(
      "POST_STAGE4A_STAGED_REFIT_S2_GATE=",
      "PASS_PENDING_HUMAN_REVIEW_STOP_BEFORE_STAGE3"
    )
  )
  invisible(list(
    primary = real_family$primary,
    delta = delta,
    guild = guild,
    terrestrial = terrestrial_primary,
    pooled = pooled_fit$effect,
    effort = effort$effects,
    placebo = placebo_family$primary,
    summary = required_summary,
    distance = distance$effects,
    coverage = coverage
  ))
}
