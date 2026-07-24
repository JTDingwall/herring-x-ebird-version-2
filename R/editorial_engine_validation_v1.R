editorial_validation_species_v1 <- function(outcome) {
  if (outcome == "checklist_reporting") {
    c("Iceland Gull", "Ring-billed Gull", "Brandt's Cormorant")
  } else if (outcome == "conditional_positive_numeric_count") {
    c("Glaucous-winged Gull", "Ring-billed Gull", "American Crow")
  } else {
    stop("Unsupported validation outcome: ", outcome, call. = FALSE)
  }
}

editorial_glmmtmb_variances_v1 <- function(fit) {
  values <- c(
    event_block_variance = NA_real_,
    observer_variance = NA_real_,
    location_variance = NA_real_
  )
  variance <- glmmTMB::VarCorr(fit)$cond
  mapping <- c(
    event_block_token = "event_block_variance",
    observer_cluster_token = "observer_variance",
    location_cluster_token = "location_variance"
  )
  for (group in names(mapping)) {
    if (group %in% names(variance)) {
      values[[mapping[[group]]]] <- as.numeric(variance[[group]][1L, 1L])
    }
  }
  values
}

editorial_glmmtmb_fit_one_v1 <- function(
    dat, outcome, taxon_id, species, primary) {
  if (outcome == "checklist_reporting") {
    use <- !is.na(dat$detection)
    dat$model_response <- dat$detection
    family <- stats::binomial()
    engine <- "glmmTMB_binomial_logit_Laplace"
  } else {
    use <- is.finite(dat$numeric_count) & dat$numeric_count > 0
    dat$model_response <- dat$numeric_count
    family <- glmmTMB::truncated_nbinom2()
    engine <- "glmmTMB_zero_truncated_nbinom2"
  }
  d <- dat[use, , drop = FALSE]
  if (nrow(d) < 20L) {
    stop("EDITORIAL_ENGINE_SUPPORT_GATE: fewer than 20 model rows",
         call. = FALSE)
  }
  fit <- glmmTMB::glmmTMB(
    editorial_formula_v1("model_response"), data = d, family = family,
    control = glmmTMB::glmmTMBControl(
      optCtrl = list(iter.max = 10000L, eval.max = 10000L)
    )
  )
  beta <- glmmTMB::fixef(fit)$cond
  covariance <- as.matrix(stats::vcov(fit)$cond)
  optimizer_code <- fit$fit$convergence
  pd_hessian <- isTRUE(fit$sdr$pdHess)
  random_variances <- editorial_glmmtmb_variances_v1(fit)
  singular <- any(
    is.finite(random_variances) & random_variances < 1e-8
  )
  status <- if (identical(as.integer(optimizer_code), 0L) && pd_hessian) {
    if (singular) "completed_with_singular_warning" else "completed"
  } else {
    "failed_convergence"
  }
  effects <- editorial_compound_effects_v1(
    beta, covariance, taxon_id, species, outcome, nrow(d), status
  )$contrasts
  primary_key <- paste(
    primary$analysis_taxon_id, primary$outcome, primary$comparison, sep = "|"
  )
  effect_key <- paste(
    effects$analysis_taxon_id, effects$outcome, effects$comparison, sep = "|"
  )
  index <- match(effect_key, primary_key)
  effects$engine <- engine
  effects$primary_estimate <- primary$estimate[index]
  effects$primary_standard_error <- primary$standard_error[index]
  effects$primary_conf_low <- primary$conf_low[index]
  effects$primary_conf_high <- primary$conf_high[index]
  effects$primary_ratio <- primary$ratio[index]
  effects$primary_q_value <- primary$q_value[index]
  effects$estimate_difference_from_primary <-
    effects$estimate - effects$primary_estimate
  effects$direction_concordant <- ifelse(
    is.finite(effects$estimate) & is.finite(effects$primary_estimate),
    sign(effects$estimate) == sign(effects$primary_estimate), NA
  )
  gradient <- fit$sdr$gradient.fixed
  diagnostics <- data.frame(
    analysis_taxon_id = taxon_id,
    species = species,
    outcome = outcome,
    engine = engine,
    n = editorial_release_count_v1(nrow(d)),
    event_blocks = editorial_release_count_v1(length(unique(
      d$event_block_token
    ))),
    observer_clusters = editorial_release_count_v1(length(unique(
      d$observer_cluster_token
    ))),
    generalized_locations = editorial_release_count_v1(length(unique(
      d$location_cluster_token
    ))),
    optimizer_code = optimizer_code,
    positive_definite_hessian = pd_hessian,
    maximum_absolute_gradient = if (is.null(gradient)) NA_real_ else
      max(abs(gradient)),
    singular_fit = singular,
    event_block_variance =
      random_variances[["event_block_variance"]],
    observer_variance = random_variances[["observer_variance"]],
    location_variance = random_variances[["location_variance"]],
    dispersion_parameter = unname(stats::sigma(fit)),
    convergence_message = paste(fit$fit$message, collapse = " | "),
    status = status,
    stringsAsFactors = FALSE
  )
  list(results = effects, diagnostics = diagnostics)
}

editorial_validation_slug_v1 <- function(x) {
  tolower(gsub("[^a-z0-9]+", "_", x))
}

editorial_collate_engine_validation_v1 <- function(output_dir) {
  collate <- function(prefix, final) {
    paths <- list.files(
      output_dir, pattern = paste0("^", prefix, "__.*\\.csv$"),
      full.names = TRUE
    )
    if (!length(paths)) return(invisible(NULL))
    rows <- lapply(paths, utils::read.csv, stringsAsFactors = FALSE,
                   check.names = FALSE)
    editorial_write_csv_v1(do.call(rbind, rows), file.path(output_dir, final))
  }
  collate("engine_validation_results", "engine_validation_results.csv")
  collate(
    "engine_validation_diagnostics", "engine_validation_diagnostics.csv"
  )
  invisible(TRUE)
}

run_editorial_engine_validation_component_v1 <- function(
    protected_root, species, outcome,
    output_dir = "outputs/editorial_requested_analysis_v1",
    code_commit = NA_character_) {
  acknowledgement <- "through_2025_editorial_post_result_v1"
  if (!identical(
      Sys.getenv("EDITORIAL_REQUESTED_ANALYSIS_AUTHORIZED"), acknowledgement)) {
    stop("Exact editorial analysis acknowledgement is required", call. = FALSE)
  }
  if (!requireNamespace("glmmTMB", quietly = TRUE)) {
    stop("glmmTMB is unavailable in the configured validation library",
         call. = FALSE)
  }
  if (!species %in% editorial_validation_species_v1(outcome)) {
    stop("Species is not frozen for this validation outcome", call. = FALSE)
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
  if (sum(selected) != 217200L) {
    stop("EDITORIAL_SOG_POPULATION_GATE: expected 217200", call. = FALSE)
  }
  events <- events_all[selected, , drop = FALSE]
  rm(events_all)
  links <- .stage4a_read_gz(protected_files[["source_links"]])
  events <- post_stage4a_add_joint_exposure_v1(events, links)$events
  rm(links)
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
  registry <- utils::read.csv(
    "metadata/canonical_species_registry.csv", stringsAsFactors = FALSE
  )
  taxon_id <- registry$analysis_taxon_id[
    match(species, registry$common_name)
  ]
  if (length(taxon_id) != 1L || is.na(taxon_id)) {
    stop("Frozen validation species did not resolve", call. = FALSE)
  }
  dat <- stage4a_materialize_taxon(events, states, masks, taxon_id)
  primary <- utils::read.csv(
    file.path(output_dir, "active_minus_pre_contrasts.csv"),
    stringsAsFactors = FALSE
  )
  component <- editorial_glmmtmb_fit_one_v1(
    dat, outcome, taxon_id, species, primary
  )
  slug <- editorial_validation_slug_v1(species)
  suffix <- paste(slug, outcome, sep = "__")
  results_path <- file.path(
    output_dir, paste0("engine_validation_results__", suffix, ".csv")
  )
  diagnostics_path <- file.path(
    output_dir, paste0("engine_validation_diagnostics__", suffix, ".csv")
  )
  editorial_write_csv_v1(component$results, results_path)
  editorial_write_csv_v1(component$diagnostics, diagnostics_path)
  editorial_collate_engine_validation_v1(output_dir)
  editorial_privacy_column_gate_v1(c(results_path, diagnostics_path))
  record <- list(
    analysis_version = "editorial_engine_validation_v1",
    code_commit = code_commit,
    species = species,
    outcome = outcome,
    glmmTMB_version = as.character(
      utils::packageVersion("glmmTMB")
    ),
    TMB_version = as.character(utils::packageVersion("TMB")),
    completed_at_utc = format(
      as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"
    ),
    protected_input_hashes = as.list(observed_hashes),
    records_2026_plus_read = 0L,
    protected_rows_released = 0L,
    privacy_column_gate = "PASS"
  )
  yaml::write_yaml(
    record, file.path(
      output_dir, paste0("engine_validation_execution__", suffix, ".yml")
    )
  )
  message("EDITORIAL_ENGINE_VALIDATION_GATE=PASS component=", suffix)
  invisible(component)
}
