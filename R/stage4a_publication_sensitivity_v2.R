stage4a_sensitivity_bundle_fields_v2 <- function() {
  c(
    "active_reference_class", "active_near", "contemporaneous_reference",
    "concurrent_links", "time_early_pre", "time_immediate_pre",
    "time_spawn_start", "time_early_egg", "time_late_egg", "time_post",
    "distance_ring_0_0p5", "distance_ring_0p5_1", "distance_ring_1_2",
    "distance_ring_2_3", "distance_ring_3_4", "distance_ring_4_5",
    "distance_ring_5_10", "distance_ring_10_20"
  )
}

.stage4a_sensitivity_sha256_v2 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

.stage4a_sensitivity_release_count_v2 <- function(x, threshold = 20L) {
  ifelse(is.finite(x) & x > 0 & x < threshold, NA_real_, x)
}

.stage4a_sensitivity_bundle_signature_v2 <- function(x, fields) {
  do.call(paste, c(lapply(x[, fields, drop = FALSE], as.character), sep = "\034"))
}

stage4a_sensitivity_transform_bundle_v2 <- function(events, model_version_id) {
  if (!model_version_id %in% c("M27_v2", "M28_v2")) {
    stop("STAGE4A_SENSITIVITY_TRANSFORM: unsupported placebo model", call. = FALSE)
  }
  fields <- stage4a_sensitivity_bundle_fields_v2()
  required <- c("analysis_event_token", "location_cluster_token", "region",
                "checklist_year", fields)
  missing <- setdiff(required, names(events))
  if (length(missing)) stop("STAGE4A_SENSITIVITY_TRANSFORM: missing fields: ",
                            paste(missing, collapse = ", "), call. = FALSE)
  if (anyNA(events[, required, drop = FALSE])) {
    stop("STAGE4A_SENSITIVITY_TRANSFORM: required metadata contains missing values",
         call. = FALSE)
  }
  seed <- if (model_version_id == "M27_v2") 10007L else 20011L
  group <- interaction(events$region, events$checklist_year, drop = TRUE, lex.order = TRUE)
  groups <- split(seq_len(nrow(events)), group)
  source_row <- seq_len(nrow(events))
  for (idx in groups) {
    if (length(idx) < 2L) {
      stop("STAGE4A_SENSITIVITY_TRANSFORM: region-year singleton cannot receive nonzero shift",
           call. = FALSE)
    }
    ordered <- if (model_version_id == "M27_v2") {
      idx[order(events$analysis_event_token[idx], method = "radix")]
    } else {
      idx[order(events$location_cluster_token[idx], events$analysis_event_token[idx],
                method = "radix")]
    }
    offset <- 1L + seed %% (length(ordered) - 1L)
    shifted <- c(tail(ordered, offset), head(ordered, -offset))
    source_row[ordered] <- shifted
  }
  transformed <- events
  transformed[, fields] <- events[source_row, fields, drop = FALSE]
  distance_fields <- grep("^distance_", fields, value = TRUE)
  time_fields <- grep("^time_", fields, value = TRUE)
  distance_total <- rowSums(transformed[, distance_fields, drop = FALSE])
  time_total <- rowSums(transformed[, time_fields, drop = FALSE])
  active_consistent <- transformed$active_near ==
    as.integer(transformed$active_reference_class == "active")
  reference_consistent <- transformed$contemporaneous_reference ==
    as.integer(transformed$active_reference_class == "reference")
  integrity_pass <- all(distance_total == transformed$concurrent_links) &&
    all(time_total <= transformed$concurrent_links) && all(active_consistent) &&
    all(reference_consistent)
  distribution_pass <- all(vapply(groups, function(idx) {
    identical(
      sort(.stage4a_sensitivity_bundle_signature_v2(events[idx, , drop = FALSE], fields),
           method = "radix"),
      sort(.stage4a_sensitivity_bundle_signature_v2(
        transformed[idx, , drop = FALSE], fields), method = "radix")
    )
  }, logical(1L)))
  support_pass <- identical(events$region, transformed$region) &&
    identical(events$checklist_year, transformed$checklist_year)
  fixed_points <- sum(source_row == seq_len(nrow(events)))
  if (!integrity_pass || !distribution_pass || !support_pass || fixed_points != 0L) {
    stop("STAGE4A_SENSITIVITY_TRANSFORM: frozen bundle invariants failed", call. = FALSE)
  }
  regions <- sort(unique(events$region), method = "radix")
  audit <- do.call(rbind, lapply(regions, function(region_name) {
    use <- events$region == region_name
    data.frame(
      model_version_id = model_version_id,
      region = region_name,
      strata = length(unique(events$checklist_year[use])),
      rows = .stage4a_sensitivity_release_count_v2(sum(use)),
      fixed_points = .stage4a_sensitivity_release_count_v2(
        sum(use & source_row == seq_len(nrow(events)))),
      bundle_integrity_pass = integrity_pass,
      regional_temporal_support_pass = support_pass && distribution_pass,
      response_fields_read = 0L,
      stringsAsFactors = FALSE
    )
  }))
  list(events = transformed, audit = audit, source_row = source_row)
}

.stage4a_sensitivity_empty_result_v2 <- function(model_version_id, sensitivity_id,
                                                   region, unit_label, outcome,
                                                   n, status) {
  effect <- data.frame(
    model_version_id, matched_primary_model_id = "M01", sensitivity_id,
    region, unit_label, unit_class = "guild", outcome,
    contrast = "active_near", estimate = NA_real_, standard_error = NA_real_,
    conf_low = NA_real_, conf_high = NA_real_, p_value = NA_real_,
    q_value = NA_real_, n = .stage4a_sensitivity_release_count_v2(n), status,
    stringsAsFactors = FALSE
  )
  diagnostic <- data.frame(
    model_version_id, region, unit_label, outcome, converged = FALSE,
    rank_deficient = NA, status, stringsAsFactors = FALSE
  )
  list(effect = effect, diagnostic = diagnostic, validation = data.frame())
}

stage4a_sensitivity_fit_one_v2 <- function(dat, model_version_id, sensitivity_id,
                                            region, unit_label, outcome,
                                            checkpoint_path, cache_signature) {
  if (file.exists(checkpoint_path)) {
    cached <- readRDS(checkpoint_path)
    if (identical(cached$cache_signature, cache_signature)) return(cached$result)
  }
  if (outcome == "detection") {
    use <- !is.na(dat$detection)
    response <- "detection"
    family <- stats::binomial()
  } else if (outcome == "positive_numeric_count_given_detection") {
    use <- is.finite(dat$numeric_count) & dat$numeric_count > 0
    response <- "log_count"
    family <- stats::gaussian()
  } else stop("STAGE4A_SENSITIVITY_FIT: unsupported outcome", call. = FALSE)
  d <- dat[use, , drop = FALSE]
  if (outcome == "positive_numeric_count_given_detection") {
    d$log_count <- log(d$numeric_count)
  }
  if (nrow(d) < 20L || length(unique(d[[response]])) < 2L) {
    result <- .stage4a_sensitivity_empty_result_v2(
      model_version_id, sensitivity_id, region, unit_label, outcome, nrow(d),
      "failed_insufficient_support"
    )
    saveRDS(list(cache_signature = cache_signature, result = result), checkpoint_path)
    return(result)
  }
  fit <- try(mgcv::bam(
    .stage4a_random_formula(response), data = d, family = family,
    method = "fREML", discrete = TRUE, nthreads = 1L
  ), silent = TRUE)
  if (inherits(fit, "try-error")) {
    result <- .stage4a_sensitivity_empty_result_v2(
      model_version_id, sensitivity_id, region, unit_label, outcome, nrow(d),
      "failed_numerical_fit_no_fallback"
    )
    saveRDS(list(cache_signature = cache_signature, result = result), checkpoint_path)
    return(result)
  }
  summary_fit <- summary(fit)
  coefficients <- summary_fit$p.table
  index <- match("active_near", rownames(coefficients))
  converged <- if (!is.null(fit$converged)) isTRUE(fit$converged) else TRUE
  rank_deficient <- !is.null(fit$rank) && fit$rank < length(stats::coef(fit))
  if (is.na(index)) {
    estimate <- standard_error <- p_value <- NA_real_
    status <- "failed_geometry"
  } else {
    estimate <- coefficients[index, 1L]
    standard_error <- coefficients[index, 2L]
    p_value <- coefficients[index, ncol(coefficients)]
    status <- if (!converged) "failed_convergence" else if
      (!is.finite(estimate) || !is.finite(standard_error) || standard_error <= 0) {
        "failed_geometry"
      } else if (rank_deficient) "completed_with_rank_warning" else "completed"
  }
  effect <- data.frame(
    model_version_id, matched_primary_model_id = "M01", sensitivity_id,
    region, unit_label, unit_class = "guild", outcome,
    contrast = "active_near", estimate, standard_error,
    conf_low = estimate - 1.959963984540054 * standard_error,
    conf_high = estimate + 1.959963984540054 * standard_error,
    p_value, q_value = NA_real_, n = .stage4a_sensitivity_release_count_v2(nrow(d)), status,
    stringsAsFactors = FALSE
  )
  diagnostic <- data.frame(
    model_version_id, region, unit_label, outcome, converged,
    rank_deficient, status, stringsAsFactors = FALSE
  )
  validation_outcome <- if (outcome == "detection") "detection" else "positive_count"
  validation <- .stage4a_cv(d, validation_outcome, family, model_version_id,
                            region, "guild")
  validation$model_version_id <- model_version_id
  validation$sensitivity_id <- sensitivity_id
  validation$unit_label <- unit_label
  validation$outcome <- outcome
  validation <- validation[, c(
    "model_version_id", "sensitivity_id", "region", "unit_label", "outcome",
    "fold", "validation_view", "prediction_support_rule", "n_validation",
    "n_validation_supported", "n_validation_unsupported_factor_levels",
    "privacy_suppressed", "metric_1_name", "metric_1", "metric_2_name", "metric_2",
    "conditional_observer_or_location_BLUP_used"
  )]
  result <- list(effect = effect, diagnostic = diagnostic, validation = validation)
  saveRDS(list(cache_signature = cache_signature, result = result), checkpoint_path)
  result
}

.stage4a_sensitivity_guild_cache_v2 <- function(states, masks) {
  guild <- utils::read.csv("metadata/species_primary_guild.csv", stringsAsFactors = FALSE)
  legacy_cache_path <- "data/derived/stage4a_protected/stage4a_guild_aggregate_cache.rds"
  cache_path <- "data/derived/stage4a_protected/stage4a_publication_guild_cache_v2.rds"
  input_paths <- c(
    "data/derived/stage4a_protected/stage4a_reported_states.tsv.gz",
    "data/derived/stage4a_protected/stage4a_ambiguity_masks.tsv.gz",
    "metadata/species_primary_guild.csv"
  )
  signature <- unname(tools::md5sum(input_paths))
  cache <- if (file.exists(cache_path)) readRDS(cache_path) else if
    (file.exists(legacy_cache_path)) readRDS(legacy_cache_path) else NULL
  if (!is.null(cache) && identical(cache$input_signature, signature)) {
    return(list(guild = guild, guild_states = cache$guild_states,
                guild_masks = cache$guild_masks))
  }
  joined_states <- merge(states, guild[, c("analysis_taxon_id", "primary_guild_id")],
                         by = "analysis_taxon_id", all.x = FALSE)
  keys <- split(seq_len(nrow(joined_states)), paste(
    joined_states$analysis_event_token, joined_states$primary_guild_id, sep = "\034"
  ))
  guild_states <- do.call(rbind, lapply(keys, function(i) data.frame(
    analysis_event_token = joined_states$analysis_event_token[i[1L]],
    analysis_taxon_id = joined_states$primary_guild_id[i[1L]], detection = 1L,
    numeric_count = if (all(is.finite(joined_states$numeric_count[i]))) {
      sum(joined_states$numeric_count[i])
    } else NA_real_,
    lower_bound_count = NA_real_,
    count_type = if (all(is.finite(joined_states$numeric_count[i]))) {
      "numeric"
    } else "unquantified_X",
    ambiguity_flag = any(as.logical(joined_states$ambiguity_flag[i])),
    stringsAsFactors = FALSE
  )))
  joined_masks <- merge(masks, guild[, c("analysis_taxon_id", "primary_guild_id")],
                        by = "analysis_taxon_id")
  guild_masks <- unique(data.frame(
    analysis_event_token = joined_masks$analysis_event_token,
    analysis_taxon_id = joined_masks$primary_guild_id,
    stringsAsFactors = FALSE
  ))
  saveRDS(list(input_signature = signature, guild_states = guild_states,
               guild_masks = guild_masks), cache_path)
  list(guild = guild, guild_states = guild_states, guild_masks = guild_masks)
}

run_stage4a_publication_sensitivity_v2 <- function(
    pre_execution_spec_commit = "d44a4a334b3461152557db54c147078e80901de7",
    execution_code_commit, output_dir = "outputs/stage4a_publication_sensitivity_v2") {
  if (!identical(Sys.getenv("STAGE4A_AUTHORIZED_RESPONSE_ACCESS"),
                 "through_2025_after_lock_ci")) {
    stop("Production requires the authorized through-2025 response-access acknowledgement",
         call. = FALSE)
  }
  required_packages <- c("data.table", "digest", "mgcv", "yaml")
  missing_packages <- required_packages[!vapply(required_packages, requireNamespace,
                                                logical(1L), quietly = TRUE)]
  if (length(missing_packages)) stop("Missing packages: ", paste(missing_packages, collapse = ", "))
  protected_files <- c(
    event_metadata = "data/derived/stage4a_protected/stage4a_event_metadata.tsv.gz",
    reported_states = "data/derived/stage4a_protected/stage4a_reported_states.tsv.gz",
    ambiguity_masks = "data/derived/stage4a_protected/stage4a_ambiguity_masks.tsv.gz"
  )
  if (!all(file.exists(protected_files))) stop("Protected Stage 4A inputs are unavailable")
  protected_hashes <- vapply(protected_files, .stage4a_sensitivity_sha256_v2, character(1L))
  events_all <- .stage4a_prepare_events(.stage4a_read_gz(protected_files[["event_metadata"]]))
  maximum_year <- max(events_all$checklist_year)
  records_2026_plus <- sum(events_all$checklist_year >= 2026)
  if (maximum_year > 2025L || records_2026_plus != 0L) {
    stop("STAGE4A_SENSITIVITY_YEAR_GATE: 2026+ data encountered", call. = FALSE)
  }
  primary <- (events_all$region == "SoG" & events_all$checklist_year >= 2005L) |
    (events_all$region == "WCVI" & events_all$checklist_year >= 2015L)
  events <- events_all[primary, , drop = FALSE]
  if (!all(stage4a_effort_eligible(events$protocol, events$duration_minutes,
                                   events$effort_distance_km, events$observer_count))) {
    stop("STAGE4A_SENSITIVITY_POPULATION_GATE: effort eligibility failed", call. = FALSE)
  }
  stage4a_validate_folds(events)
  states_all <- .stage4a_read_gz(protected_files[["reported_states"]])
  masks_all <- .stage4a_read_gz(protected_files[["ambiguity_masks"]])
  selected_tokens <- events$analysis_event_token
  states <- states_all[states_all$analysis_event_token %in% selected_tokens, , drop = FALSE]
  masks <- masks_all[masks_all$analysis_event_token %in% selected_tokens, , drop = FALSE]
  rm(states_all, masks_all, events_all)
  guild_data <- .stage4a_sensitivity_guild_cache_v2(states, masks)
  guild_ids <- sort(unique(guild_data$guild$primary_guild_id), method = "radix")
  if (length(guild_ids) != 8L) stop("STAGE4A_SENSITIVITY_GUILD_GATE: expected 8 guilds")
  region_events <- split(events, factor(events$region, levels = c("SoG", "WCVI")))
  transformed <- list(M27_v2 = list(), M28_v2 = list())
  transformation_audits <- list()
  for (model in names(transformed)) for (region_name in names(region_events)) {
    value <- stage4a_sensitivity_transform_bundle_v2(region_events[[region_name]], model)
    transformed[[model]][[region_name]] <- value$events
    transformation_audits[[length(transformation_audits) + 1L]] <- value$audit
  }
  wcvi <- region_events[["WCVI"]]
  observer_counts <- sort(table(wcvi$observer_cluster_token), decreasing = TRUE)
  maximum_count <- max(observer_counts)
  dominant_candidates <- sort(names(observer_counts)[observer_counts == maximum_count],
                              method = "radix")
  dominant_observer <- dominant_candidates[1L]
  high_precision <- as.logical(wcvi$high_precision_2km)
  observer_holdout <- wcvi$observer_cluster_token != dominant_observer
  cohort_audits <- list(
    data.frame(model_version_id = "S4A12_WCVI_2KM_v2", region = "WCVI",
      strata = length(unique(wcvi$checklist_year)),
      rows = .stage4a_sensitivity_release_count_v2(sum(high_precision)),
      fixed_points = NA_real_, bundle_integrity_pass = TRUE,
      regional_temporal_support_pass = all(table(wcvi$checklist_year[high_precision]) >= 20L),
      response_fields_read = 0L, stringsAsFactors = FALSE),
    data.frame(model_version_id = "S4A11_WCVI_DOMINANT_OBSERVER_v2", region = "WCVI",
      strata = length(unique(wcvi$checklist_year)),
      rows = .stage4a_sensitivity_release_count_v2(sum(observer_holdout)),
      fixed_points = NA_real_, bundle_integrity_pass = TRUE,
      regional_temporal_support_pass = all(table(wcvi$checklist_year[observer_holdout]) >= 20L),
      response_fields_read = 0L, stringsAsFactors = FALSE)
  )
  transformation_audit <- do.call(rbind, c(transformation_audits, cohort_audits))
  model_map <- data.table::fread("metadata/stage4a_publication_sensitivity_model_map_v2.csv")
  checkpoint_dir <- file.path("data/derived/stage4a_protected",
                              paste0("publication_sensitivity_v2_", substr(execution_code_commit, 1L, 12L)))
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)
  results <- list()
  model_definitions <- list(
    M27_v2 = list(regions = c("SoG", "WCVI")),
    M28_v2 = list(regions = c("SoG", "WCVI")),
    S4A12_WCVI_2KM_v2 = list(regions = "WCVI"),
    S4A11_WCVI_DOMINANT_OBSERVER_v2 = list(regions = "WCVI")
  )
  outcomes <- c("detection", "positive_numeric_count_given_detection")
  for (model_version_id in names(model_definitions)) {
    sensitivity_id <- model_map$sensitivity_id[
      match(model_version_id, model_map$model_version_id)
    ]
    if (length(sensitivity_id) != 1L || is.na(sensitivity_id)) {
      stop("STAGE4A_SENSITIVITY_MODEL_MAP: missing sensitivity identifier")
    }
    for (region_name in model_definitions[[model_version_id]]$regions) {
      model_events <- if (model_version_id %in% c("M27_v2", "M28_v2")) {
        transformed[[model_version_id]][[region_name]]
      } else if (model_version_id == "S4A12_WCVI_2KM_v2") {
        wcvi[high_precision, , drop = FALSE]
      } else wcvi[observer_holdout, , drop = FALSE]
      for (guild_id in guild_ids) {
        denominator <- stage4a_materialize_taxon(
          model_events, guild_data$guild_states, guild_data$guild_masks, guild_id
        )
        for (outcome in outcomes) {
          message("Fitting ", model_version_id, " / ", region_name, " / ",
                  guild_id, " / ", outcome)
          checkpoint <- file.path(checkpoint_dir, paste(
            model_version_id, region_name, guild_id, outcome, "rds", sep = "_"
          ))
          signature <- paste(execution_code_commit, protected_hashes, model_version_id,
                             region_name, guild_id, outcome, sep = "|")
          results[[length(results) + 1L]] <- stage4a_sensitivity_fit_one_v2(
            denominator, model_version_id, sensitivity_id, region_name, guild_id,
            outcome, checkpoint, signature
          )
        }
      }
    }
  }
  effects <- do.call(rbind, lapply(results, `[[`, "effect"))
  diagnostics <- do.call(rbind, lapply(results, `[[`, "diagnostic"))
  validation_rows <- Filter(function(x) nrow(x), lapply(results, `[[`, "validation"))
  validation <- if (length(validation_rows)) do.call(rbind, validation_rows) else data.frame()
  if (nrow(effects) != 96L || nrow(diagnostics) != 96L) {
    stop("STAGE4A_SENSITIVITY_MODEL_ACCOUNTING: expected 96 model components", call. = FALSE)
  }
  family <- interaction(effects$model_version_id, effects$region, effects$outcome,
                        drop = TRUE, lex.order = TRUE)
  for (level in levels(family)) {
    idx <- which(family == level & is.finite(effects$p_value))
    effects$q_value[idx] <- stats::p.adjust(effects$p_value[idx], method = "BH")
  }
  effects <- effects[order(effects$model_version_id, effects$region, effects$outcome,
                           effects$unit_label), , drop = FALSE]
  diagnostics <- diagnostics[order(diagnostics$model_version_id, diagnostics$region,
                                   diagnostics$outcome, diagnostics$unit_label), , drop = FALSE]
  if (nrow(validation)) validation <- validation[order(
    validation$model_version_id, validation$region, validation$outcome,
    validation$unit_label, validation$fold
  ), , drop = FALSE]
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  .stage4a_write_csv(effects, file.path(output_dir, "sensitivity_effect_estimates_v2.csv"))
  .stage4a_write_csv(validation, file.path(output_dir, "matched_validation_v2.csv"))
  .stage4a_write_csv(diagnostics, file.path(output_dir, "model_diagnostics_v2.csv"))
  .stage4a_write_csv(transformation_audit,
                     file.path(output_dir, "transformation_audit_v2.csv"))
  disposition <- utils::read.csv("metadata/stage4a_publication_model_disposition_v2.csv",
                                 stringsAsFactors = FALSE, na.strings = "")
  .stage4a_write_csv(disposition, file.path(output_dir, "model_disposition_v2.csv"))
  code_files <- c("R/stage4a_publication_sensitivity_v2.R",
                  "scripts/run_stage4a_publication_sensitivity_v2.R")
  execution_record <- list(
    execution_version = "stage4a_publication_sensitivity_execution_v2",
    status = "COMPLETE_WITH_EXPLICIT_COMPONENT_STATUS",
    pre_execution_spec_commit = pre_execution_spec_commit,
    execution_code_commit = execution_code_commit,
    protected_input_hashes = as.list(protected_hashes),
    protected_input_paths_released = FALSE,
    maximum_checklist_year_read = maximum_year,
    records_2026_plus_read = records_2026_plus,
    analysis_population_minimum_year = min(events$checklist_year),
    code_hashes = stats::setNames(lapply(code_files, .stage4a_sensitivity_sha256_v2),
                                 code_files),
    results = list(
      expected_model_components = 96L,
      completed_model_components = sum(grepl("^completed", effects$status)),
      failed_model_components = sum(!grepl("^completed", effects$status)),
      placebo_transformations = 4L,
      whole_bundle_invariants_pass = all(transformation_audit$bundle_integrity_pass),
      response_fields_read_for_transformations = sum(transformation_audit$response_fields_read),
      m26_publication_disposition = "RETIRED_WITHOUT_REPLACEMENT"
    )
  )
  yaml_text <- yaml::as.yaml(execution_record, line.sep = "\n")
  .stage4a_write_text_lf(yaml_text, file.path(output_dir, "execution_record_v2.yml"))
  manifest_name <- "output_hash_manifest_v2.csv"
  artifacts <- sort(list.files(output_dir, full.names = TRUE))
  artifacts <- artifacts[basename(artifacts) != manifest_name]
  manifest <- data.frame(
    artifact_path = paste0("outputs/stage4a_publication_sensitivity_v2/", basename(artifacts)),
    sha256 = vapply(artifacts, .stage4a_sensitivity_sha256_v2, character(1L)),
    bytes = as.numeric(file.info(artifacts)$size), stringsAsFactors = FALSE
  )
  .stage4a_write_csv(manifest, file.path(output_dir, manifest_name))
  invisible(list(effects = effects, diagnostics = diagnostics, validation = validation,
                 transformation_audit = transformation_audit, manifest = manifest,
                 execution_record = execution_record))
}
