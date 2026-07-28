staged_refit_amendment_version_v1 <- function() {
  "post_stage4a_staged_refit_amendment_v1"
}

staged_refit_amendment_gate_v1 <- function(
    path = "metadata/post_stage4a_staged_refit_amendment_v1.yml") {
  if (!file.exists(path)) {
    stop("STAGED_REFIT_AMENDMENT_GATE: record unavailable",
         call. = FALSE)
  }
  amendment <- yaml::read_yaml(path)
  if (
    !identical(
      amendment$amendment_version,
      "post_stage4a_staged_refit_amendment_v1"
    ) ||
      !identical(
        amendment$decision,
        "REPLACE_SPECIES_NEGATIVE_CONTROLS_WITH_OUTCOME_AND_TIMING_CONTROLS"
      ) ||
      !identical(
        amendment$superseded$species_negative_controls$status,
        "retained_as_record_not_reported_as_controls"
      ) ||
      !identical(
        as.numeric(amendment$added_placebo_exposure$offsets_days),
        c(-180, -90, 90, 180)
      ) ||
      !setequal(
        amendment$added_negative_control_outcomes$outcomes,
        c(
          "log_duration_minutes",
          "log_effort_distance_plus_one",
          "number_observers"
        )
      )
  ) {
    stop("STAGED_REFIT_AMENDMENT_GATE: scope mismatch",
         call. = FALSE)
  }
  invisible(amendment)
}

staged_refit_amendment_snapshot_v1 <- function(
    directory = "outputs/post_stage4a_staged_refit_v1") {
  files <- sort(list.files(
    directory, recursive = TRUE, full.names = TRUE
  ))
  if (!length(files)) {
    stop("STAGED_REFIT_AMENDMENT_HISTORY_GATE: Stage 1 output unavailable",
         call. = FALSE)
  }
  hashes <- vapply(files, .post_stage4a_sha256_v1, character(1L))
  names(hashes) <- gsub("\\\\", "/", files)
  hashes
}

staged_refit_amendment_verify_stage1_manifest_v1 <- function() {
  path <- file.path(
    "outputs", "post_stage4a_staged_refit_v1",
    "output_hash_manifest_v1.csv"
  )
  manifest <- utils::read.csv(path, stringsAsFactors = FALSE)
  if (
    anyDuplicated(manifest$file) ||
      !all(file.exists(manifest$file)) ||
      any(vapply(
        manifest$file, .post_stage4a_sha256_v1, character(1L)
      ) != manifest$sha256)
  ) {
    stop("STAGED_REFIT_AMENDMENT_HISTORY_GATE: Stage 1 manifest failed",
         call. = FALSE)
  }
  invisible(manifest)
}

staged_refit_amendment_effort_spec_v1 <- function() {
  data.frame(
    outcome = c(
      "log_duration_minutes",
      "log_effort_distance_plus_one",
      "number_observers"
    ),
    response_column = c(
      "log_duration", "log_effort_distance", "observer_count"
    ),
    effect_scale = c(
      "log_ratio", "log_ratio", "additive_observers"
    ),
    stringsAsFactors = FALSE
  )
}

staged_refit_amendment_effort_formula_v1 <- function(
    response_column) {
  effort_terms <- c(
    "log_duration", "log_effort_distance", "observer_count"
  )
  if (!response_column %in% effort_terms) {
    stop("STAGED_REFIT_AMENDMENT_EFFORT_FORMULA_GATE: response",
         call. = FALSE)
  }
  fixed <- c(
    post_stage4a_exposure_terms_v1(),
    "factor(checklist_year)", "protocol",
    setdiff(effort_terms, response_column)
  )
  stats::as.formula(paste(
    response_column, "~", paste(fixed, collapse = " + "),
    "+ (1 | event_block_token) + (1 | observer_cluster_token) +",
    "(1 | location_cluster_token)"
  ))
}

staged_refit_amendment_fit_effort_v1 <- function(
    events, outcome, checkpoint_path, cache_signature) {
  if (file.exists(checkpoint_path)) {
    cached <- readRDS(checkpoint_path)
    if (identical(cached$cache_signature, cache_signature)) {
      return(cached$result)
    }
  }
  spec <- staged_refit_amendment_effort_spec_v1()
  row <- spec[spec$outcome == outcome, , drop = FALSE]
  if (nrow(row) != 1L) {
    stop("STAGED_REFIT_AMENDMENT_EFFORT_OUTCOME_GATE: unknown outcome",
         call. = FALSE)
  }
  response <- row$response_column[[1L]]
  use <- is.finite(events[[response]])
  dat <- events[use, , drop = FALSE]
  if (
    nrow(dat) != nrow(events) ||
      length(unique(dat[[response]])) < 2L
  ) {
    stop("STAGED_REFIT_AMENDMENT_EFFORT_SUPPORT_GATE: response",
         call. = FALSE)
  }
  exposure_terms <- post_stage4a_exposure_terms_v1()
  support <- vapply(
    exposure_terms, function(term) sum(dat[[term]] > 0L), integer(1L)
  )
  if (any(support < 20L)) {
    stop("STAGED_REFIT_AMENDMENT_EFFORT_SUPPORT_GATE: exposure",
         call. = FALSE)
  }
  formula <- staged_refit_amendment_effort_formula_v1(response)
  fit <- try(
    lme4::lmer(
      formula,
      data = dat,
      REML = TRUE,
      control = lme4::lmerControl(
        optimizer = "nloptwrap",
        calc.derivs = TRUE,
        optCtrl = list(maxeval = 10000L)
      )
    ),
    silent = TRUE
  )
  if (inherits(fit, "try-error")) {
    stop(
      "STAGED_REFIT_AMENDMENT_EFFORT_FIT_GATE: failed; no fallback: ",
      substr(gsub("[\r\n]+", " ", as.character(fit)), 1L, 240L),
      call. = FALSE
    )
  }
  beta <- lme4::fixef(fit)
  covariance <- as.matrix(stats::vcov(fit))
  contrast <- staged_refit_wald_v1(
    beta,
    covariance,
    staged_refit_s1_contrast_weights_v1()$active_minus_pre14
  )
  singular <- lme4::isSingular(fit, tol = 1e-4)
  optimizer_code <- fit@optinfo$conv$opt
  classification <- .post_stage4a_model_messages_v1(
    optimizer_code, fit@optinfo$conv$lme4$messages, singular
  )
  rank_deficient <- length(beta) < ncol(stats::model.matrix(
    lme4::nobars(formula), dat
  ))
  status <- if (!classification$converged) {
    "failed_convergence"
  } else if (singular) {
    "completed_with_singular_warning"
  } else if (rank_deficient) {
    "completed_with_rank_deficiency_warning"
  } else {
    "completed"
  }
  estimate <- unname(contrast[["estimate"]])
  standard_error <- unname(contrast[["standard_error"]])
  conf_low <- unname(contrast[["conf_low"]])
  conf_high <- unname(contrast[["conf_high"]])
  effect_scale <- row$effect_scale[[1L]]
  effect <- data.frame(
    amendment_version = staged_refit_amendment_version_v1(),
    stage = "s1_anchor_amendment",
    analysis_variant = "real_start_anchor",
    outcome = outcome,
    response_column = response,
    comparison = "active_minus_pre14",
    estimate = estimate,
    standard_error = standard_error,
    conf_low = conf_low,
    conf_high = conf_high,
    p_value = unname(contrast[["p_value"]]),
    q_value_bh_3_outcomes = NA_real_,
    effect_scale = effect_scale,
    multiplicative_effect = if (effect_scale == "log_ratio") {
      exp(estimate)
    } else {
      NA_real_
    },
    multiplicative_conf_low = if (effect_scale == "log_ratio") {
      exp(conf_low)
    } else {
      NA_real_
    },
    multiplicative_conf_high = if (effect_scale == "log_ratio") {
      exp(conf_high)
    } else {
      NA_real_
    },
    additive_observer_effect = if (
      effect_scale == "additive_observers"
    ) {
      estimate
    } else {
      NA_real_
    },
    n = nrow(dat),
    status = status,
    stringsAsFactors = FALSE
  )
  diagnostic <- data.frame(
    amendment_version = staged_refit_amendment_version_v1(),
    stage = "s1_anchor_amendment",
    analysis_variant = "real_start_anchor",
    outcome = outcome,
    engine = "lme4_lmer_REML",
    n = nrow(dat),
    converged = classification$converged,
    singular_fit = singular,
    rank_deficient = rank_deficient,
    convergence_message = classification$message,
    status = status,
    stringsAsFactors = FALSE
  )
  result <- list(effect = effect, diagnostic = diagnostic)
  saveRDS(
    list(cache_signature = cache_signature, result = result),
    checkpoint_path
  )
  result
}

staged_refit_amendment_fit_effort_set_v1 <- function(
    events, checkpoint_dir, cache_signature, analysis_variant) {
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)
  outcomes <- staged_refit_amendment_effort_spec_v1()$outcome
  results <- lapply(outcomes, function(outcome) {
    result <- staged_refit_amendment_fit_effort_v1(
      events,
      outcome,
      file.path(checkpoint_dir, paste0(outcome, ".rds")),
      paste(cache_signature, analysis_variant, outcome, sep = "|")
    )
    result$effect$analysis_variant <- analysis_variant
    result$diagnostic$analysis_variant <- analysis_variant
    result
  })
  effects <- do.call(rbind, lapply(results, `[[`, "effect"))
  diagnostics <- do.call(rbind, lapply(results, `[[`, "diagnostic"))
  effects$q_value_bh_3_outcomes <- stats::p.adjust(
    effects$p_value, method = "BH"
  )
  list(effects = effects, diagnostics = diagnostics)
}

staged_refit_amendment_events_from_links_v1 <- function(
    events, links) {
  event_tokens <- as.character(events$analysis_event_token)
  selected <- links[
    as.character(links$analysis_event_token) %in% event_tokens,
    ,
    drop = FALSE
  ]
  counts <- table(selected$analysis_event_token)
  observed <- as.integer(counts[event_tokens])
  observed[is.na(observed)] <- 0L
  adjusted_events <- events
  adjusted_events$concurrent_links <- observed
  joint <- post_stage4a_add_joint_exposure_v1(
    adjusted_events, selected
  )
  if (
    nrow(joint$events) != nrow(events) ||
      anyDuplicated(joint$events$analysis_event_token)
  ) {
    stop("STAGED_REFIT_AMENDMENT_LINK_AGGREGATION_GATE: cardinality",
         call. = FALSE)
  }
  list(
    events = joint$events,
    selected_links = selected,
    checklists_with_links = sum(observed > 0L),
    link_rows = nrow(selected)
  )
}

staged_refit_amendment_placebo_events_v1 <- function(
    events, widened_links, anchor_lookup, offset_days) {
  if (!offset_days %in% c(-180L, -90L, 90L, 180L)) {
    stop("STAGED_REFIT_AMENDMENT_PLACEBO_OFFSET_GATE: unsupported",
         call. = FALSE)
  }
  anchored <- staged_refit_reanchor_links_v1(
    widened_links, anchor_lookup
  )
  # Fake anchor = real StartDate anchor + offset. Therefore:
  # checklist - fake anchor = Stage 1 event_day - offset.
  anchored$event_day <- anchored$event_day - as.integer(offset_days)
  use <- anchored$event_day >= -28L & anchored$event_day <= 28L
  staged_refit_amendment_events_from_links_v1(
    events, anchored[use, , drop = FALSE]
  )
}

staged_refit_amendment_pool_detection_v1 <- function(
    first, second) {
  if (length(first) != length(second)) {
    stop("STAGED_REFIT_AMENDMENT_POOL_GATE: length mismatch",
         call. = FALSE)
  }
  out <- rep(NA_integer_, length(first))
  any_detected <- first == 1L | second == 1L
  both_absent <- first == 0L & second == 0L
  out[any_detected %in% TRUE] <- 1L
  out[both_absent %in% TRUE] <- 0L
  out
}

staged_refit_amendment_pool_control_v1 <- function(controls) {
  required <- c("American Robin", "Chestnut-backed Chickadee")
  if (!setequal(names(controls), required)) {
    stop("STAGED_REFIT_AMENDMENT_POOL_GATE: species mismatch",
         call. = FALSE)
  }
  first <- controls[[required[[1L]]]]$data
  second <- controls[[required[[2L]]]]$data
  if (
    nrow(first) != nrow(second) ||
      !identical(
        as.character(first$analysis_event_token),
        as.character(second$analysis_event_token)
      )
  ) {
    stop("STAGED_REFIT_AMENDMENT_POOL_JOIN_GATE: event order",
         call. = FALSE)
  }
  dat <- first
  dat$detection <- staged_refit_amendment_pool_detection_v1(
    first$detection, second$detection
  )
  dat$numeric_count <- NA_real_
  dat$count_type <- "pooled_reporting_only"
  list(
    data = dat,
    taxon_id = "terrestrial_pool_robin_chickadee_v1",
    species = "American Robin + Chestnut-backed Chickadee"
  )
}

staged_refit_amendment_fit_pool_v1 <- function(
    pool, checkpoint_path, cache_signature, analysis_variant) {
  result <- staged_refit_s1_fit_component_v1(
    pool$data,
    pool$taxon_id,
    pool$species,
    "terrestrial_attention_displacement_pool",
    "checklist_reporting",
    checkpoint_path,
    paste(cache_signature, analysis_variant, "pool", sep = "|")
  )
  effect <- result$contrasts[
    result$contrasts$comparison == "active_minus_pre14",
    ,
    drop = FALSE
  ]
  effect$analysis_variant <- analysis_variant
  effect$pool_members <- paste(
    "American Robin", "Chestnut-backed Chickadee", sep = "; "
  )
  diagnostic <- result$diagnostic
  diagnostic$analysis_variant <- analysis_variant
  list(effect = effect, diagnostic = diagnostic)
}

staged_refit_amendment_fit_terrestrial_species_v1 <- function(
    controls, checkpoint_dir, cache_signature, analysis_variant) {
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)
  result <- staged_refit_fit_controls_v1(
    controls, checkpoint_dir,
    paste(cache_signature, analysis_variant, sep = "|")
  )
  effects <- staged_refit_adjust_bh_v1(
    staged_refit_flatten_models_v1(result, "contrasts"),
    paste0("terrestrial_displacement_2_species__", analysis_variant)
  )
  effects <- effects[
    effects$comparison == "active_minus_pre14", , drop = FALSE
  ]
  effects$analysis_variant <- analysis_variant
  diagnostics <- staged_refit_flatten_models_v1(
    result, "diagnostic"
  )
  diagnostics$analysis_variant <- analysis_variant
  list(effects = effects, diagnostics = diagnostics)
}

staged_refit_amendment_primary_family_v1 <- function(
    events, states, masks, species_registry, core_taxa,
    checkpoint_dir, cache_signature, analysis_variant, workers) {
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)
  results <- staged_refit_parallel_core_v1(
    core_taxa,
    events,
    states,
    masks,
    species_registry,
    checkpoint_dir,
    cache_signature,
    workers
  )
  names(results) <- core_taxa
  contrasts <- staged_refit_adjust_bh_v1(
    staged_refit_flatten_models_v1(results, "contrasts"),
    paste0(analysis_variant, "__fixed_49_species")
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
    stop("STAGED_REFIT_AMENDMENT_PRIMARY_FAMILY_GATE: 49 x 2",
         call. = FALSE)
  }
  primary$analysis_variant <- analysis_variant
  diagnostics$analysis_variant <- analysis_variant
  list(primary = primary, diagnostics = diagnostics)
}

staged_refit_amendment_tally_v1 <- function(
    primary, offset_days = NA_integer_,
    real_reporting = 14L, real_count = 19L) {
  rows <- lapply(unique(primary$outcome), function(outcome_now) {
    x <- primary[primary$outcome == outcome_now, , drop = FALSE]
    real <- if (outcome_now == "checklist_reporting") {
      real_reporting
    } else {
      real_count
    }
    data.frame(
      offset_days = offset_days,
      outcome = outcome_now,
      positive_bh_q_lt_0_05 = sum(
        x$estimate > 0 & x$q_value < 0.05, na.rm = TRUE
      ),
      negative_bh_q_lt_0_05 = sum(
        x$estimate < 0 & x$q_value < 0.05, na.rm = TRUE
      ),
      estimable_species = sum(
        is.finite(x$estimate) & is.finite(x$standard_error)
      ),
      real_start_anchor_positive_bh = real,
      positive_tally_fraction_of_real = sum(
        x$estimate > 0 & x$q_value < 0.05, na.rm = TRUE
      ) / real,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

staged_refit_amendment_delta_v1 <- function(
    variant, real, label) {
  variant_key <- paste(
    variant$analysis_taxon_id, variant$outcome, sep = "\r"
  )
  real_key <- paste(real$analysis_taxon_id, real$outcome, sep = "\r")
  if (
    length(variant_key) != 98L ||
      length(real_key) != 98L ||
      anyDuplicated(variant_key) ||
      anyDuplicated(real_key)
  ) {
    stop("STAGED_REFIT_AMENDMENT_DELTA_GATE: key cardinality",
         call. = FALSE)
  }
  index <- match(variant_key, real_key)
  if (anyNA(index)) {
    stop("STAGED_REFIT_AMENDMENT_DELTA_GATE: unmatched",
         call. = FALSE)
  }
  data.frame(
    analysis_variant = label,
    analysis_taxon_id = variant$analysis_taxon_id,
    species = variant$species,
    outcome = variant$outcome,
    real_estimate = real$estimate[index],
    variant_estimate = variant$estimate,
    estimate_delta = variant$estimate - real$estimate[index],
    real_q_value = real$q_value[index],
    variant_q_value = variant$q_value,
    changed_direction =
      sign(variant$estimate) != sign(real$estimate[index]),
    changed_bh_significance =
      (variant$q_value < 0.05) != (real$q_value[index] < 0.05),
    real_status = real$status[index],
    variant_status = variant$status,
    stringsAsFactors = FALSE
  )
}

staged_refit_amendment_long_span_v1 <- function(
    events, archived_links, extended_links, anchor_lookup,
    herring_path, protected_output_path) {
  event_tokens <- as.character(events$analysis_event_token)
  selected_archived <- archived_links[
    archived_links$analysis_event_token %in% event_tokens,
    ,
    drop = FALSE
  ]
  selected_extended <- extended_links[
    extended_links$analysis_event_token %in% event_tokens,
    ,
    drop = FALSE
  ]
  linked_tokens <- unique(selected_extended$herring_source_token)
  index <- match(linked_tokens, anchor_lookup$herring_source_token)
  if (anyNA(index)) {
    stop("STAGED_REFIT_AMENDMENT_LONG_SPAN_GATE: lookup",
         call. = FALSE)
  }
  candidates <- anchor_lookup[index, , drop = FALSE]
  candidates <- candidates[
    candidates$anchor_shift_days == 36L, , drop = FALSE
  ]
  if (nrow(candidates) != 1L) {
    stop("STAGED_REFIT_AMENDMENT_LONG_SPAN_GATE: expected one event",
         call. = FALSE)
  }
  token <- as.character(candidates$herring_source_token[[1L]])

  raw <- data.table::fread(
    herring_path,
    select = c(
      "Year", "StatisticalArea", "Section", "LocationCode",
      "SpawnNumber", "StartDate", "EndDate"
    ),
    colClasses = "character",
    na.strings = NULL,
    showProgress = FALSE
  )
  raw[, source_row__ := .I]
  for (name in setdiff(names(raw), "source_row__")) {
    data.table::set(
      raw, j = name, value = staged_refit_clean_v1(raw[[name]])
    )
  }
  raw[, event_year__ := suppressWarnings(as.integer(Year))]
  raw[, source_identity__ := paste(
    source_row__, event_year__, StatisticalArea, Section,
    LocationCode, SpawnNumber, sep = "|"
  )]
  raw[, herring_source_token := staged_refit_hash_token_v1(
    "herring_source", source_identity__
  )]
  raw_hit <- raw[herring_source_token == token]
  if (nrow(raw_hit) != 1L) {
    stop("STAGED_REFIT_AMENDMENT_LONG_SPAN_GATE: raw join",
         call. = FALSE)
  }
  start <- data.table::as.IDate(raw_hit$StartDate)
  end <- data.table::as.IDate(raw_hit$EndDate)
  span <- as.integer(end - start)
  if (!identical(span, 72L)) {
    stop("STAGED_REFIT_AMENDMENT_LONG_SPAN_GATE: expected 72 days",
         call. = FALSE)
  }
  primary_links <- selected_archived[
    selected_archived$herring_source_token == token,
    ,
    drop = FALSE
  ]
  extended_event_links <- selected_extended[
    selected_extended$herring_source_token == token,
    ,
    drop = FALSE
  ]
  anchored_primary <- staged_refit_reanchor_links_v1(
    primary_links, anchor_lookup
  )
  stage1_window_links <- sum(!is.na(
    post_stage4a_classify_links_v1(anchored_primary)$period
  ))
  midpoint_window_links <- sum(!is.na(
    post_stage4a_classify_links_v1(primary_links)$period
  ))
  protected <- data.frame(
    herring_source_token = token,
    event_year = candidates$event_year[[1L]],
    recorded_span_days = span,
    anchor_shift_days = 36L,
    primary_20km_link_count = nrow(primary_links),
    extended_26km_link_count = nrow(extended_event_links),
    primary_distinct_checklists =
      length(unique(primary_links$analysis_event_token)),
    midpoint_window_link_count = midpoint_window_links,
    start_anchor_window_link_count = stage1_window_links,
    stringsAsFactors = FALSE
  )
  dir.create(
    dirname(protected_output_path),
    recursive = TRUE,
    showWarnings = FALSE
  )
  utils::write.table(
    protected,
    protected_output_path,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = ""
  )
  public <- data.frame(
    audit_event_label = "long_span_event_36day_v1",
    recorded_span_days = span,
    anchor_shift_days = 36L,
    primary_20km_link_count = nrow(primary_links),
    extended_26km_link_count = nrow(extended_event_links),
    primary_distinct_checklists =
      length(unique(primary_links$analysis_event_token)),
    midpoint_window_link_count = midpoint_window_links,
    start_anchor_window_link_count = stage1_window_links,
    identifier_withheld_from_committed_output = TRUE,
    stringsAsFactors = FALSE
  )
  list(
    token = token,
    public = public,
    primary_links = primary_links
  )
}

staged_refit_amendment_reconcile_wide_links_v1 <- function(
    archived_links, widened_links) {
  archived_key <- paste(
    archived_links$analysis_event_token,
    archived_links$herring_source_token,
    sep = "\r"
  )
  overlap <- widened_links[
    widened_links$event_day >= -90L &
      widened_links$event_day <= 120L,
    ,
    drop = FALSE
  ]
  overlap_key <- paste(
    overlap$analysis_event_token,
    overlap$herring_source_token,
    sep = "\r"
  )
  if (
    anyDuplicated(archived_key) ||
      anyDuplicated(overlap_key) ||
      length(archived_key) != length(overlap_key)
  ) {
    stop("STAGED_REFIT_AMENDMENT_WIDE_LINK_GATE: key cardinality",
         call. = FALSE)
  }
  index <- match(archived_key, overlap_key)
  if (
    anyNA(index) ||
      any(archived_links$event_day != overlap$event_day[index]) ||
      max(abs(
        archived_links$distance_km - overlap$distance_km[index]
      )) > 0.0011
  ) {
    stop("STAGED_REFIT_AMENDMENT_WIDE_LINK_GATE: overlap mismatch",
         call. = FALSE)
  }
  data.frame(
    archived_rows = nrow(archived_links),
    widened_rows = nrow(widened_links),
    widened_min_midpoint_day = min(widened_links$event_day),
    widened_max_midpoint_day = max(widened_links$event_day),
    overlap_rows = nrow(overlap),
    overlap_one_to_one_reconciliation = "PASS",
    stringsAsFactors = FALSE
  )
}

run_post_stage4a_staged_refit_amendment_s1_v1 <- function(
    execution_code_commit,
    placebo_seed = 20260727L,
    output_root =
      "outputs/post_stage4a_staged_refit_amendment_v1") {
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
  amendment <- staged_refit_amendment_gate_v1()
  if (!identical(
      Sys.getenv("POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED"),
      authorization$environment_acknowledgement$value
  )) {
    stop("The exact author-set acknowledgement is required",
         call. = FALSE)
  }
  if (!identical(as.integer(placebo_seed), 20260727L)) {
    stop("STAGED_REFIT_AMENDMENT_SEED_GATE: unexpected seed",
         call. = FALSE)
  }
  staged_refit_amendment_verify_stage1_manifest_v1()
  stage1_hashes_before <- staged_refit_amendment_snapshot_v1()
  parent_hashes_before <- staged_refit_parent_hash_snapshot_v1()

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
    source_links_placebo = paste0(
      "data/derived/post_stage4a_staged_refit_amendment_v1/",
      "placebo_link_builder/metadata_source_point_links.tsv.gz"
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
    stop("STAGED_REFIT_AMENDMENT_INPUT_GATE: protected input unavailable",
         call. = FALSE)
  }
  protected_hashes <- vapply(
    protected_files, .post_stage4a_sha256_v1, character(1L)
  )
  if (
    protected_hashes[["source_links_archived"]] !=
      "f26197d0a71fd177e77774ec9e5596563c127ec8eb0f948042aff51ad805567b" ||
      protected_hashes[["source_links_extended"]] !=
        "06a34a4d3880f2dd3a969d9976b901eff855ff7362e86ae40d75a38edd697dc2"
  ) {
    stop("STAGED_REFIT_AMENDMENT_INPUT_HASH_GATE: frozen link mismatch",
         call. = FALSE)
  }

  herring_path <- Sys.getenv("HERRING_EBIRD_V2_HERRING", unset = "")
  anchor_lookup <- staged_refit_build_anchor_lookup_v1(herring_path)
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
    stop("STAGED_REFIT_AMENDMENT_POPULATION_GATE: changed",
         call. = FALSE)
  }
  stage4a_validate_folds(events)

  archived_links <- .stage4a_read_gz(
    protected_files[["source_links_archived"]]
  )
  extended_links <- .stage4a_read_gz(
    protected_files[["source_links_extended"]]
  )
  widened_links <- .stage4a_read_gz(
    protected_files[["source_links_placebo"]]
  )
  wide_link_audit <- staged_refit_amendment_reconcile_wide_links_v1(
    archived_links, widened_links
  )
  midpoint_joint <- post_stage4a_add_joint_exposure_v1(
    events, archived_links
  )
  anchored_links <- staged_refit_reanchor_links_v1(
    archived_links, anchor_lookup
  )
  start_joint <- post_stage4a_add_joint_exposure_v1(
    events, anchored_links
  )
  events_midpoint <- midpoint_joint$events
  events_start <- start_joint$events

  protected_root <- file.path(
    "data", "derived", "post_stage4a_staged_refit_amendment_v1"
  )
  checkpoint_root <- file.path(protected_root, "checkpoints")
  dir.create(checkpoint_root, recursive = TRUE, showWarnings = FALSE)
  long_span <- staged_refit_amendment_long_span_v1(
    events,
    archived_links,
    extended_links,
    anchor_lookup,
    herring_path,
    file.path(protected_root, "long_span_event_identifier_v1.tsv")
  )
  exclusion_links <- anchored_links[
    anchored_links$herring_source_token != long_span$token,
    ,
    drop = FALSE
  ]
  exclusion_joint <- staged_refit_amendment_events_from_links_v1(
    events, exclusion_links
  )
  events_exclusion <- exclusion_joint$events

  states_all <- .stage4a_read_gz(protected_files[["reported_states"]])
  masks_all <- .stage4a_read_gz(protected_files[["ambiguity_masks"]])
  if (nrow(states_all) != 1169612L || nrow(masks_all) != 5834L) {
    stop("STAGED_REFIT_AMENDMENT_STATE_GATE: cardinality",
         call. = FALSE)
  }
  tokens <- events$analysis_event_token
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
  core_taxa <- support_registry$analysis_taxon_id[
    support_registry$named_species_recommendation == "named_species_core"
  ]
  if (length(core_taxa) != 49L || anyDuplicated(core_taxa)) {
    stop("STAGED_REFIT_AMENDMENT_FAMILY_GATE: fixed 49",
         call. = FALSE)
  }
  workers <- post_stage4a_worker_count_v1(length(core_taxa))
  cache_signature <- paste(
    execution_code_commit,
    .post_stage4a_sha256_v1(
      "R/post_stage4a_staged_refit_amendment_v1.R"
    ),
    .post_stage4a_sha256_v1(
      "metadata/post_stage4a_staged_refit_amendment_v1.yml"
    ),
    protected_hashes,
    sep = "|",
    collapse = "|"
  )

  effort_real <- staged_refit_amendment_fit_effort_set_v1(
    events_start,
    file.path(checkpoint_root, "effort_real"),
    cache_signature,
    "real_start_anchor"
  )
  effort_exclusion <- staged_refit_amendment_fit_effort_set_v1(
    events_exclusion,
    file.path(checkpoint_root, "effort_long_span_exclusion"),
    cache_signature,
    "long_span_event_excluded"
  )

  controls_midpoint <- staged_refit_load_control_denominators_v1(
    events_midpoint, protected_files[["control_extract"]]
  )
  controls_start <- staged_refit_load_control_denominators_v1(
    events_start, protected_files[["control_extract"]]
  )
  controls_exclusion <- staged_refit_load_control_denominators_v1(
    events_exclusion, protected_files[["control_extract"]]
  )
  terrestrial_midpoint <-
    staged_refit_amendment_fit_terrestrial_species_v1(
      controls_midpoint,
      file.path(checkpoint_root, "terrestrial_midpoint"),
      cache_signature,
      "original_midpoint_anchor"
    )
  terrestrial_exclusion <-
    staged_refit_amendment_fit_terrestrial_species_v1(
      controls_exclusion,
      file.path(checkpoint_root, "terrestrial_long_span_exclusion"),
      cache_signature,
      "long_span_event_excluded"
    )
  historical_terrestrial <- utils::read.csv(
    file.path(
      "outputs", "post_stage4a_staged_refit_v1",
      "negative_controls_all_stages.csv"
    ),
    stringsAsFactors = FALSE
  )
  historical_terrestrial <- historical_terrestrial[
    historical_terrestrial$comparison == "active_minus_pre14",
    ,
    drop = FALSE
  ]
  if (
    nrow(historical_terrestrial) != 4L ||
      !setequal(
        historical_terrestrial$species,
        c("American Robin", "Chestnut-backed Chickadee")
      )
  ) {
    stop("STAGED_REFIT_AMENDMENT_HISTORY_GATE: terrestrial rows",
         call. = FALSE)
  }
  historical_terrestrial$analysis_variant <- "real_start_anchor"
  historical_terrestrial$analysis_role <-
    "terrestrial_attention_displacement"
  historical_terrestrial$reporting_role <-
    "terrestrial_attention_displacement_not_negative_control"
  terrestrial_midpoint$effects$analysis_role <-
    "terrestrial_attention_displacement"
  terrestrial_exclusion$effects$analysis_role <-
    "terrestrial_attention_displacement"
  terrestrial_midpoint$effects$reporting_role <-
    "terrestrial_attention_displacement_not_negative_control"
  terrestrial_exclusion$effects$reporting_role <-
    "terrestrial_attention_displacement_not_negative_control"

  pool_midpoint <- staged_refit_amendment_pool_control_v1(
    controls_midpoint
  )
  pool_start <- staged_refit_amendment_pool_control_v1(
    controls_start
  )
  pool_exclusion <- staged_refit_amendment_pool_control_v1(
    controls_exclusion
  )
  pooled_results <- list(
    staged_refit_amendment_fit_pool_v1(
      pool_midpoint,
      file.path(checkpoint_root, "pool_midpoint.rds"),
      cache_signature,
      "original_midpoint_anchor"
    ),
    staged_refit_amendment_fit_pool_v1(
      pool_start,
      file.path(checkpoint_root, "pool_start.rds"),
      cache_signature,
      "real_start_anchor"
    ),
    staged_refit_amendment_fit_pool_v1(
      pool_exclusion,
      file.path(checkpoint_root, "pool_long_span_exclusion.rds"),
      cache_signature,
      "long_span_event_excluded"
    )
  )
  pooled_effects <- do.call(rbind, lapply(
    pooled_results, `[[`, "effect"
  ))
  pooled_diagnostics <- do.call(rbind, lapply(
    pooled_results, `[[`, "diagnostic"
  ))

  real_primary <- utils::read.csv(
    file.path(
      "outputs", "post_stage4a_staged_refit_v1",
      "s1_anchor", "estimates_49x2.csv"
    ),
    stringsAsFactors = FALSE
  )
  exclusion_family <- staged_refit_amendment_primary_family_v1(
    events_exclusion,
    states,
    masks,
    species_registry,
    core_taxa,
    file.path(checkpoint_root, "long_span_exclusion_family"),
    paste(cache_signature, "long_span_exclusion_family", sep = "|"),
    "long_span_event_excluded",
    workers
  )
  exclusion_delta <- staged_refit_amendment_delta_v1(
    exclusion_family$primary,
    real_primary,
    "long_span_event_excluded"
  )
  exclusion_tally <- staged_refit_amendment_tally_v1(
    exclusion_family$primary
  )
  exclusion_tally$analysis_variant <- "long_span_event_excluded"

  offsets <- as.integer(
    amendment$added_placebo_exposure$offsets_days
  )
  set.seed(placebo_seed)
  execution_order <- sample(offsets, length(offsets), replace = FALSE)
  placebo_results <- list()
  placebo_support <- list()
  for (offset in execution_order) {
    placebo_joint <- staged_refit_amendment_placebo_events_v1(
      events, widened_links, anchor_lookup, offset
    )
    label <- paste0(
      "placebo_offset_",
      if (offset < 0L) "m" else "p",
      abs(offset)
    )
    fitted <- staged_refit_amendment_primary_family_v1(
      placebo_joint$events,
      states,
      masks,
      species_registry,
      core_taxa,
      file.path(checkpoint_root, label),
      paste(cache_signature, label, sep = "|"),
      label,
      workers
    )
    fitted$primary$offset_days <- offset
    fitted$primary$placebo_seed <- placebo_seed
    fitted$diagnostics$offset_days <- offset
    placebo_results[[as.character(offset)]] <- fitted
    placebo_support[[as.character(offset)]] <- data.frame(
      offset_days = offset,
      fake_anchor_rule = "real_start_anchor_plus_offset_days",
      selected_link_rows = placebo_joint$link_rows,
      checklists_with_selected_links =
        placebo_joint$checklists_with_links,
      model_rows = nrow(placebo_joint$events),
      stringsAsFactors = FALSE
    )
    rm(placebo_joint)
  }
  placebo_estimates <- do.call(rbind, lapply(
    placebo_results, `[[`, "primary"
  ))
  placebo_diagnostics <- do.call(rbind, lapply(
    placebo_results, `[[`, "diagnostics"
  ))
  placebo_support <- do.call(rbind, placebo_support)
  placebo_tallies <- do.call(rbind, lapply(
    names(placebo_results),
    function(name) {
      staged_refit_amendment_tally_v1(
        placebo_results[[name]]$primary,
        as.integer(name)
      )
    }
  ))
  placebo_tallies <- placebo_tallies[
    order(placebo_tallies$offset_days, placebo_tallies$outcome),
    ,
    drop = FALSE
  ]
  placebo_estimates <- placebo_estimates[
    order(
      placebo_estimates$offset_days,
      placebo_estimates$outcome,
      placebo_estimates$species
    ),
    ,
    drop = FALSE
  ]

  output_dir <- file.path(output_root, "s1_anchor_amendment")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  # Rebuild a stable common schema after preserving the historical rows.
  all_names <- Reduce(
    union,
    list(
      names(terrestrial_midpoint$effects),
      names(historical_terrestrial),
      names(terrestrial_exclusion$effects)
    )
  )
  align <- function(x) {
    for (name in setdiff(all_names, names(x))) x[[name]] <- NA
    x[, all_names, drop = FALSE]
  }
  terrestrial_effects <- do.call(rbind, list(
    align(terrestrial_midpoint$effects),
    align(historical_terrestrial),
    align(terrestrial_exclusion$effects)
  ))
  terrestrial_effects$reporting_role <-
    "terrestrial_attention_displacement_not_negative_control"

  outputs <- list(
    effort_negative_control_outcomes =
      effort_real$effects,
    effort_negative_control_diagnostics =
      effort_real$diagnostics,
    effort_long_span_exclusion =
      effort_exclusion$effects,
    terrestrial_displacement_by_anchor =
      terrestrial_effects,
    pooled_terrestrial_displacement =
      pooled_effects,
    pooled_terrestrial_diagnostics =
      pooled_diagnostics,
    placebo_estimates_49x2 =
      placebo_estimates,
    placebo_tallies =
      placebo_tallies,
    placebo_support =
      placebo_support,
    placebo_diagnostics =
      placebo_diagnostics,
    long_span_event_audit =
      long_span$public,
    long_span_exclusion_estimates_49x2 =
      exclusion_family$primary,
    long_span_exclusion_delta =
      exclusion_delta,
    long_span_exclusion_tallies =
      exclusion_tally,
    long_span_exclusion_diagnostics =
      exclusion_family$diagnostics,
    widened_link_reconciliation =
      wide_link_audit
  )
  output_paths <- character()
  for (name in names(outputs)) {
    path <- file.path(output_dir, paste0(name, ".csv"))
    .post_stage4a_write_csv_v1(outputs[[name]], path)
    output_paths <- c(output_paths, path)
  }
  staged_refit_privacy_column_gate_v1(output_paths)

  if (!identical(
      stage1_hashes_before, staged_refit_amendment_snapshot_v1()
  )) {
    stop("STAGED_REFIT_AMENDMENT_HISTORY_GATE: Stage 1 changed",
         call. = FALSE)
  }
  if (!identical(
      parent_hashes_before, staged_refit_parent_hash_snapshot_v1()
  )) {
    stop("STAGED_REFIT_AMENDMENT_HISTORY_GATE: parent changed",
         call. = FALSE)
  }
  execution <- list(
    execution_version =
      "post_stage4a_staged_refit_amendment_execution_v1",
    analysis_status =
      "results_known_post_stage1_control_strategy_amendment",
    amendment_record =
      "metadata/post_stage4a_staged_refit_amendment_v1.yml",
    original_species_control_output_status =
      "retained_unchanged_reclassified_as_terrestrial_displacement",
    execution_code_commit = execution_code_commit,
    executed_at_utc = format(
      as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"
    ),
    elapsed_seconds = as.numeric(
      difftime(Sys.time(), started, units = "secs")
    ),
    placebo = list(
      seed = placebo_seed,
      randomness_used_for_execution_order_only = TRUE,
      fake_anchor_assignment_is_fixed = TRUE,
      execution_order_offsets_days = as.list(execution_order),
      reported_order_offsets_days = as.list(sort(offsets))
    ),
    population = list(
      region = "SoG",
      years = c(2005L, 2025L),
      eligible_checklists = nrow(events),
      fixed_family_species = length(core_taxa),
      records_2026_plus_read = 0L
    ),
    long_span_event = list(
      public_label = "long_span_event_36day_v1",
      identifier_stored_only_in_protected_output = TRUE,
      recorded_span_days = 72L,
      anchor_shift_days = 36L,
      primary_20km_link_count =
        long_span$public$primary_20km_link_count[[1L]],
      stage1_window_link_count =
        long_span$public$start_anchor_window_link_count[[1L]]
    ),
    joins = list(
      widened_to_archived_link_overlap =
        "one_to_one_PASS_no_historical_difference",
      links_to_anchor_lookup = "many_to_one_PASS",
      links_to_checklists =
        "many_to_one_then_aggregate_to_one_checklist_PASS",
      terrestrial_species_to_checklists =
        "two_species_same_checklist_denominator_PASS",
      variant_to_real_primary =
        "one_to_one_98_rows_PASS"
    ),
    engines = list(
      bird_reporting = "lme4::glmer binomial nAGQ=0",
      bird_positive_count = "lme4::lmer REML",
      effort_negative_control_outcomes = "lme4::lmer REML"
    ),
    model_status_counts = list(
      placebo = as.list(table(placebo_diagnostics$status)),
      long_span_exclusion = as.list(table(
        exclusion_family$diagnostics$status
      )),
      effort = as.list(table(effort_real$diagnostics$status)),
      pooled_displacement = as.list(table(pooled_diagnostics$status))
    ),
    protected_input_hashes = as.list(protected_hashes),
    historical_stage1_output_hashes = as.list(stage1_hashes_before),
    historical_stage1_outputs_modified = FALSE,
    historical_parent_outputs_modified = FALSE,
    protected_identifier_output_committed = FALSE,
    privacy_column_gate = "PASS",
    stage2_started = FALSE,
    gate =
      "PASS_PENDING_HUMAN_AMENDED_STAGE1_REVIEW_STOP_BEFORE_STAGE2"
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
      "POST_STAGE4A_STAGED_REFIT_AMENDMENT_S1_GATE=",
      "PASS_PENDING_HUMAN_REVIEW_STOP_BEFORE_STAGE2"
    )
  )
  invisible(outputs)
}
