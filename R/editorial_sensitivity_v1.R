editorial_sensitivity_ids_v1 <- function() {
  c(
    "binary_any_link", "nearest_event", "cap_8", "single_event",
    "stationary_only", "high_precision_2km", "observer_four_cell",
    "block_four_cell_20"
  )
}

editorial_sensitivity_transform_v1 <- function(
    sensitivity_id, events, classified_links) {
  if (!sensitivity_id %in% editorial_sensitivity_ids_v1()) {
    stop("Unknown editorial sensitivity: ", sensitivity_id, call. = FALSE)
  }
  terms <- post_stage4a_exposure_terms_v1()
  if (anyDuplicated(events$analysis_event_token)) {
    stop("EDITORIAL_SENSITIVITY_EVENT_KEY_GATE: duplicate checklist",
         call. = FALSE)
  }
  transformed <- events
  detail <- "unchanged"

  if (sensitivity_id == "binary_any_link") {
    transformed[terms] <- lapply(
      transformed[terms], function(x) as.integer(x > 0L)
    )
    detail <- "each joint period-by-zone additive count replaced by 0/1"
  } else if (sensitivity_id == "cap_8") {
    transformed[terms] <- lapply(
      transformed[terms], function(x) pmin(as.integer(x), 8L)
    )
    detail <- "each joint period-by-zone additive count capped at 8"
  } else if (sensitivity_id == "nearest_event") {
    transformed[terms] <- lapply(transformed[terms], function(x) {
      rep.int(0L, length(x))
    })
    ordered <- classified_links[order(
      classified_links$analysis_event_token,
      classified_links$distance_km,
      classified_links$herring_source_token,
      method = "radix"
    ), , drop = FALSE]
    nearest <- ordered[
      !duplicated(ordered$analysis_event_token),
      c("analysis_event_token", "term"), drop = FALSE
    ]
    if (anyDuplicated(nearest$analysis_event_token)) {
      stop("EDITORIAL_NEAREST_EVENT_KEY_GATE: duplicate checklist",
           call. = FALSE)
    }
    event_index <- match(
      nearest$analysis_event_token, transformed$analysis_event_token
    )
    if (anyNA(event_index) || !all(nearest$term %in% terms)) {
      stop("EDITORIAL_NEAREST_EVENT_JOIN_GATE: unmatched row or term",
           call. = FALSE)
    }
    for (term in terms) {
      index <- event_index[nearest$term == term]
      transformed[[term]][index] <- 1L
    }
    detail <- paste0(
      "one minimum-distance modeled-window source link retained per ",
      "checklist; source-token tie break"
    )
  } else if (sensitivity_id == "single_event") {
    transformed <- transformed[
      transformed$concurrent_links == 1L, , drop = FALSE
    ]
    detail <- "checklists with exactly one concurrent source-event link"
  } else if (sensitivity_id == "stationary_only") {
    transformed <- transformed[
      tolower(as.character(transformed$protocol)) == "stationary",
      , drop = FALSE
    ]
    detail <- "stationary eligible checklists only"
  } else if (sensitivity_id == "high_precision_2km") {
    transformed <- transformed[
      as.logical(transformed$high_precision_2km), , drop = FALSE
    ]
    detail <- paste0(
      "frozen high_precision_2km cohort: stationary plus traveling ",
      "checklists at most 2 km"
    )
  } else {
    phase_links <- classified_links[
      classified_links$period %in%
        c("early_pre", "immediate_pre", "spawn_start", "early_egg"),
      c("analysis_event_token", "period", "zone"), drop = FALSE
    ]
    phase_links$phase <- ifelse(
      phase_links$period %in% c("early_pre", "immediate_pre"),
      "pre", "active"
    )
    link_cells <- unique(rbind(
      data.frame(
        analysis_event_token = classified_links$analysis_event_token,
        cell = classified_links$zone, stringsAsFactors = FALSE
      ),
      data.frame(
        analysis_event_token = phase_links$analysis_event_token,
        cell = phase_links$phase, stringsAsFactors = FALSE
      )
    ))
    metadata <- events[
      , c(
        "analysis_event_token", "observer_cluster_token",
        "event_block_token"
      ), drop = FALSE
    ]
    joined <- merge(
      link_cells, metadata, by = "analysis_event_token",
      all.x = TRUE, sort = FALSE
    )
    if (nrow(joined) != nrow(link_cells) ||
        anyNA(joined$observer_cluster_token) ||
        anyNA(joined$event_block_token)) {
      stop("EDITORIAL_FOUR_CELL_JOIN_GATE: expected many-to-one",
           call. = FALSE)
    }
    if (sensitivity_id == "observer_four_cell") {
      represented <- unique(joined[
        , c("observer_cluster_token", "cell"), drop = FALSE
      ])
      counts <- table(represented$observer_cluster_token)
      keep <- names(counts)[counts == 4L]
      transformed <- transformed[
        transformed$observer_cluster_token %in% keep, , drop = FALSE
      ]
      detail <- paste0(
        "observer clusters represented in near, reference, pre, and active ",
        "marginal support cells"
      )
    } else {
      represented <- unique(joined[
        , c("analysis_event_token", "event_block_token", "cell"),
        drop = FALSE
      ])
      cell_counts <- stats::xtabs(
        ~ event_block_token + cell, data = represented
      )
      required <- c("near", "reference", "pre", "active")
      if (!all(required %in% colnames(cell_counts))) {
        stop("EDITORIAL_BLOCK_CELL_GATE: required cell absent",
             call. = FALSE)
      }
      keep <- rownames(cell_counts)[
        apply(cell_counts[, required, drop = FALSE] >= 20L, 1L, all)
      ]
      transformed <- transformed[
        transformed$event_block_token %in% keep, , drop = FALSE
      ]
      detail <- paste0(
        "event blocks with at least 20 linked checklists in each of ",
        "near, reference, pre, and active marginal support cells"
      )
    }
  }

  transformed$protocol <- factor(
    tolower(as.character(transformed$protocol)),
    levels = c("stationary", "traveling")
  )
  if (!nrow(transformed) || anyDuplicated(transformed$analysis_event_token)) {
    stop("EDITORIAL_SENSITIVITY_TRANSFORM_GATE: empty or duplicate result",
         call. = FALSE)
  }
  event_links <- rowSums(transformed[terms])
  audit <- data.frame(
    sensitivity_id = sensitivity_id,
    retained_checklists = editorial_release_count_v1(nrow(transformed)),
    retained_fraction = nrow(transformed) / nrow(events),
    event_blocks = editorial_release_count_v1(length(unique(
      transformed$event_block_token
    ))),
    observer_clusters = editorial_release_count_v1(length(unique(
      transformed$observer_cluster_token
    ))),
    generalized_locations = editorial_release_count_v1(length(unique(
      transformed$location_cluster_token
    ))),
    transformed_event_link_total =
      editorial_release_count_v1(sum(event_links)),
    checklists_with_transformed_links =
      editorial_release_count_v1(sum(event_links > 0L)),
    maximum_transformed_link_total = max(event_links),
    changed_component = detail,
    unchanged_components = paste0(
      "outcome; eligibility except named cohort restriction; periods; zones; ",
      "covariates; three random-intercept groups; A14 contrast"
    ),
    response_fields_read_for_transform = 0L,
    stringsAsFactors = FALSE
  )
  list(events = transformed, audit = audit)
}

editorial_sensitivity_process_taxon_v1 <- function(
    taxon_id, sensitivity_id, events, states, masks, species_registry,
    checkpoint_dir, run_signature, base_design) {
  unit_label <- species_registry$common_name[
    match(taxon_id, species_registry$analysis_taxon_id)
  ]
  if (length(unit_label) != 1L || is.na(unit_label)) {
    stop("Unresolved species label for ", taxon_id, call. = FALSE)
  }
  dat <- stage4a_materialize_taxon(events, states, masks, taxon_id)
  outcomes <- c(
    "checklist_reporting", "conditional_positive_numeric_count"
  )
  models <- lapply(outcomes, function(outcome) {
    checkpoint <- file.path(
      checkpoint_dir,
      paste(sensitivity_id, taxon_id, outcome, "rds", sep = "_")
    )
    empty_frozen_effects <- data.frame(
      analysis_taxon_id = character(), outcome = character(),
      contrast = character(), estimate = numeric()
    )
    editorial_fit_model_v1(
      dat, outcome, taxon_id, unit_label, checkpoint,
      paste(run_signature, sensitivity_id, taxon_id, outcome, sep = "|"),
      base_design, empty_frozen_effects, compute_predictions = FALSE
    )
  })
  names(models) <- outcomes
  list(models = models)
}

editorial_sensitivity_compare_v1 <- function(
    sensitivity_id, contrasts, diagnostics, primary_contrasts, audit) {
  contrasts <- editorial_adjust_bh_v1(contrasts)
  contrasts$sensitivity_id <- sensitivity_id
  contrasts$sensitivity_q_value <- contrasts$q_value
  contrasts$q_value <- NULL
  primary_key <- paste(
    primary_contrasts$analysis_taxon_id, primary_contrasts$outcome,
    primary_contrasts$comparison, sep = "|"
  )
  sensitivity_key <- paste(
    contrasts$analysis_taxon_id, contrasts$outcome,
    contrasts$comparison, sep = "|"
  )
  index <- match(sensitivity_key, primary_key)
  contrasts$primary_estimate <- primary_contrasts$estimate[index]
  contrasts$primary_standard_error <- primary_contrasts$standard_error[index]
  contrasts$primary_conf_low <- primary_contrasts$conf_low[index]
  contrasts$primary_conf_high <- primary_contrasts$conf_high[index]
  contrasts$primary_ratio <- primary_contrasts$ratio[index]
  contrasts$primary_ratio_conf_low <- primary_contrasts$ratio_conf_low[index]
  contrasts$primary_ratio_conf_high <- primary_contrasts$ratio_conf_high[index]
  contrasts$primary_q_value <- primary_contrasts$q_value[index]
  contrasts$primary_status <- primary_contrasts$status[index]
  contrasts$estimate_difference_from_primary <-
    contrasts$estimate - contrasts$primary_estimate
  contrasts$direction_concordant <- ifelse(
    is.finite(contrasts$estimate) & is.finite(contrasts$primary_estimate),
    sign(contrasts$estimate) == sign(contrasts$primary_estimate), NA
  )
  diagnostic_key <- paste(
    diagnostics$analysis_taxon_id, diagnostics$outcome, sep = "|"
  )
  contrast_diagnostic_key <- paste(
    contrasts$analysis_taxon_id, contrasts$outcome, sep = "|"
  )
  diagnostic_index <- match(contrast_diagnostic_key, diagnostic_key)
  contrasts$model_n <- diagnostics$n[diagnostic_index]
  contrasts$model_event_blocks <- diagnostics$event_blocks[diagnostic_index]
  contrasts$model_observer_clusters <-
    diagnostics$observer_clusters[diagnostic_index]
  contrasts$model_generalized_locations <-
    diagnostics$generalized_locations[diagnostic_index]
  contrasts$retained_checklists <- audit$retained_checklists[[1L]]
  contrasts$retained_fraction <- audit$retained_fraction[[1L]]
  contrasts$changed_component <- audit$changed_component[[1L]]
  contrasts
}

editorial_collate_sensitivity_outputs_v1 <- function(output_dir) {
  collate <- function(prefix, final_name) {
    paths <- list.files(
      output_dir, pattern = paste0("^", prefix, "__.*\\.csv$"),
      full.names = TRUE
    )
    if (!length(paths)) return(invisible(NULL))
    pieces <- lapply(paths, utils::read.csv, stringsAsFactors = FALSE,
                     check.names = FALSE)
    editorial_write_csv_v1(
      do.call(rbind, pieces), file.path(output_dir, final_name)
    )
  }
  collate("sensitivity_comparisons", "sensitivity_comparisons.csv")
  collate("sensitivity_diagnostics", "sensitivity_diagnostics.csv")
  collate("sensitivity_support", "sensitivity_support.csv")
  invisible(TRUE)
}

run_editorial_sensitivities_v1 <- function(
    protected_root, sensitivity_ids = editorial_sensitivity_ids_v1(),
    output_dir = "outputs/editorial_requested_analysis_v1",
    checkpoint_dir =
      "data/derived/editorial_requested_analysis_v1/sensitivity_checkpoints",
    code_commit = NA_character_) {
  acknowledgement <- "through_2025_editorial_post_result_v1"
  if (!identical(
      Sys.getenv("EDITORIAL_REQUESTED_ANALYSIS_AUTHORIZED"), acknowledgement)) {
    stop("Exact editorial analysis acknowledgement is required", call. = FALSE)
  }
  unknown <- setdiff(sensitivity_ids, editorial_sensitivity_ids_v1())
  if (length(unknown)) {
    stop("Unknown sensitivity IDs: ", paste(unknown, collapse = ", "),
         call. = FALSE)
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
  if (anyNA(selected) || sum(selected) != 217200L) {
    stop("EDITORIAL_SOG_POPULATION_GATE: expected 217200", call. = FALSE)
  }
  events <- events_all[selected, , drop = FALSE]
  rm(events_all)
  stage4a_validate_folds(events)

  links <- .stage4a_read_gz(protected_files[["source_links"]])
  selected_links <- links[
    links$analysis_event_token %in% events$analysis_event_token,
    , drop = FALSE
  ]
  classified <- post_stage4a_classify_links_v1(selected_links)
  classified$herring_source_token <- selected_links$herring_source_token
  classified$distance_km <- selected_links$distance_km
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
  primary_contrasts <- utils::read.csv(
    file.path(output_dir, "active_minus_pre_contrasts.csv"),
    stringsAsFactors = FALSE
  )
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)

  workers <- suppressWarnings(as.integer(Sys.getenv(
    "EDITORIAL_REQUESTED_ANALYSIS_WORKERS", "4"
  )))
  if (is.na(workers) || workers < 1L) workers <- 1L
  workers <- min(workers, length(core_taxa))
  run_signature <- paste(
    editorial_sha256_v1("docs/editorial_requested_analysis_spec.md"),
    editorial_sha256_v1("R/editorial_requested_analysis_v1.R"),
    editorial_sha256_v1("R/editorial_sensitivity_v1.R"),
    observed_hashes, sep = "|", collapse = "|"
  )

  for (sensitivity_id in sensitivity_ids) {
    message("EDITORIAL_SENSITIVITY_START=", sensitivity_id)
    transformed <- editorial_sensitivity_transform_v1(
      sensitivity_id, events, classified
    )
    sensitivity_events <- transformed$events
    base_design <- editorial_base_design_v1(sensitivity_events)
    if (workers == 1L) {
      results <- lapply(core_taxa, function(taxon_id) {
        editorial_sensitivity_process_taxon_v1(
          taxon_id, sensitivity_id, sensitivity_events, states, masks,
          species_registry, checkpoint_dir, run_signature, base_design
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
          source(file.path("R", "editorial_sensitivity_v1.R"),
                 local = FALSE)
          NULL
        })
        parallel::clusterExport(
          cluster,
          c(
            "sensitivity_id", "sensitivity_events", "states", "masks",
            "species_registry", "checkpoint_dir", "run_signature",
            "base_design"
          ),
          envir = environment()
        )
        parallel::parLapply(cluster, core_taxa, function(taxon_id) {
          editorial_sensitivity_process_taxon_v1(
            taxon_id, sensitivity_id, sensitivity_events, states, masks,
            species_registry, checkpoint_dir, run_signature, base_design
          )
        })
      }, finally = {
        parallel::stopCluster(cluster)
      })
    }
    contrasts <- editorial_flatten_models_v1(results, "contrasts")
    diagnostics <- editorial_flatten_models_v1(results, "diagnostics")
    diagnostics$sensitivity_id <- sensitivity_id
    comparisons <- editorial_sensitivity_compare_v1(
      sensitivity_id, contrasts, diagnostics, primary_contrasts,
      transformed$audit
    )
    editorial_write_csv_v1(
      comparisons, file.path(
        output_dir,
        paste0("sensitivity_comparisons__", sensitivity_id, ".csv")
      )
    )
    editorial_write_csv_v1(
      diagnostics, file.path(
        output_dir,
        paste0("sensitivity_diagnostics__", sensitivity_id, ".csv")
      )
    )
    editorial_write_csv_v1(
      transformed$audit, file.path(
        output_dir,
        paste0("sensitivity_support__", sensitivity_id, ".csv")
      )
    )
    editorial_collate_sensitivity_outputs_v1(output_dir)
    editorial_privacy_column_gate_v1(list.files(
      output_dir, full.names = TRUE
    ))
    message("EDITORIAL_SENSITIVITY_COMPLETE=", sensitivity_id)
  }

  execution <- list(
    analysis_version = "editorial_sensitivity_v1",
    analysis_status =
      "frozen_post_result_exploratory_refinement_not_preregistered",
    code_commit = code_commit,
    sensitivity_ids = as.list(sensitivity_ids),
    executed_at_utc = format(
      as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"
    ),
    eligible_checklists = nrow(events),
    support_qualified_species = length(core_taxa),
    workers = workers,
    protected_input_hashes = as.list(observed_hashes),
    records_2026_plus_read = 0L,
    protected_rows_released = 0L,
    privacy_column_gate = "PASS"
  )
  yaml::write_yaml(
    execution, file.path(output_dir, "sensitivity_execution_record.yml")
  )
  message("EDITORIAL_SENSITIVITY_GATE=PASS_PENDING_QA_AND_HANDOFF")
  invisible(TRUE)
}
