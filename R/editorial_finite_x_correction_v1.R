editorial_replace_outcome_rows_v1 <- function(
    path, replacement, outcome = "finite_numeric_vs_x") {
  existing <- utils::read.csv(path, stringsAsFactors = FALSE,
                              check.names = FALSE)
  if (!"outcome" %in% names(existing)) {
    stop("EDITORIAL_CORRECTION_SCHEMA_GATE: missing outcome in ", path,
         call. = FALSE)
  }
  existing <- existing[existing$outcome != outcome, , drop = FALSE]
  missing_from_replacement <- setdiff(names(existing), names(replacement))
  missing_from_existing <- setdiff(names(replacement), names(existing))
  if (length(missing_from_replacement) || length(missing_from_existing)) {
    stop(
      "EDITORIAL_CORRECTION_SCHEMA_GATE: incompatible columns in ", path,
      call. = FALSE
    )
  }
  replacement <- replacement[, names(existing), drop = FALSE]
  editorial_write_csv_v1(rbind(existing, replacement), path)
}

editorial_write_output_manifest_v1 <- function(output_dir) {
  manifest_path <- file.path(output_dir, "output_hash_manifest.csv")
  output_files <- list.files(output_dir, full.names = TRUE)
  output_files <- output_files[
    normalizePath(output_files, winslash = "/", mustWork = FALSE) !=
      normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
  ]
  manifest <- data.frame(
    file = gsub("\\\\", "/", output_files),
    sha256 = vapply(output_files, editorial_sha256_v1, character(1L)),
    stringsAsFactors = FALSE
  )
  editorial_write_csv_v1(manifest, manifest_path)
}

editorial_process_finite_x_taxon_v1 <- function(
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
  outcome <- "finite_numeric_vs_x"
  checkpoint <- file.path(
    checkpoint_dir, paste(taxon_id, outcome, "rds", sep = "_")
  )
  model <- editorial_fit_model_v1(
    dat, outcome, taxon_id, unit_label, checkpoint,
    paste(run_signature, taxon_id, outcome, sep = "|"),
    base_design, frozen_effects
  )
  list(model = model, observed = observed, finite_summary = finite_summary)
}

run_editorial_finite_x_correction_v1 <- function(
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
  required_outputs <- file.path(
    output_dir,
    c(
      "active_minus_pre_contrasts.csv", "absolute_predictions.csv",
      "model_diagnostics.csv", "model_term_support.csv",
      "execution_record.yml"
    )
  )
  if (!all(file.exists(required_outputs))) {
    stop("EDITORIAL_CORRECTION_OUTPUT_GATE: completed core outputs required",
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
  if (!all(file.exists(protected_files))) {
    stop("Frozen through-2025 protected inputs are unavailable", call. = FALSE)
  }
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
    links$analysis_event_token %in% events$analysis_event_token, , drop = FALSE
  ]
  classified <- post_stage4a_classify_links_v1(selected_links)
  classified$herring_source_token <- selected_links$herring_source_token
  classified <- classified[!is.na(classified$term), , drop = FALSE]
  joint <- post_stage4a_add_joint_exposure_v1(events, links)
  events <- joint$events
  rm(links, joint)
  period_zone_support <- editorial_inventory_v1(
    events, selected_links, data.table::as.data.table(classified),
    character(), data.frame(
      analysis_role = character(), outcome = character(),
      status = character(), singular_fit = logical()
    )
  )$support

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
  base_design <- editorial_base_design_v1(events)
  run_signature <- paste(
    "finite_x_source_label_correction_v1",
    editorial_sha256_v1("docs/editorial_requested_analysis_spec.md"),
    editorial_sha256_v1("R/editorial_requested_analysis_v1.R"),
    editorial_sha256_v1("R/editorial_finite_x_correction_v1.R"),
    observed_hashes, sep = "|", collapse = "|"
  )
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)

  workers <- suppressWarnings(as.integer(Sys.getenv(
    "EDITORIAL_REQUESTED_ANALYSIS_WORKERS", "4"
  )))
  if (is.na(workers) || workers < 1L) workers <- 1L
  workers <- min(workers, length(core_taxa))
  process_one <- function(taxon_id) {
    editorial_process_finite_x_taxon_v1(
      taxon_id, events, states, masks, species_registry, checkpoint_dir,
      run_signature, base_design, frozen_effects, period_zone_support
    )
  }
  if (workers == 1L) {
    results <- lapply(core_taxa, process_one)
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
        source(file.path("R", "editorial_finite_x_correction_v1.R"),
               local = FALSE)
        NULL
      })
      parallel::clusterExport(
        cluster,
        c(
          "events", "states", "masks", "species_registry", "checkpoint_dir",
          "run_signature", "base_design", "frozen_effects",
          "period_zone_support"
        ),
        envir = environment()
      )
      parallel::parLapply(cluster, core_taxa, function(taxon_id) {
        editorial_process_finite_x_taxon_v1(
          taxon_id, events, states, masks, species_registry, checkpoint_dir,
          run_signature, base_design, frozen_effects, period_zone_support
        )
      })
    }, finally = {
      parallel::stopCluster(cluster)
    })
  }

  contrasts <- editorial_adjust_bh_v1(do.call(
    rbind, lapply(results, function(x) x$model$contrasts)
  ))
  diagnostics <- do.call(
    rbind, lapply(results, function(x) x$model$diagnostics)
  )
  term_support <- do.call(
    rbind, lapply(results, function(x) x$model$term_support)
  )
  prediction_parts <- lapply(results, function(x) x$model$predictions)
  prediction_parts <- prediction_parts[
    vapply(prediction_parts, nrow, integer(1L)) > 0L
  ]
  predictions <- if (length(prediction_parts)) {
    do.call(rbind, prediction_parts)
  } else {
    utils::read.csv(
      file.path(output_dir, "absolute_predictions.csv"),
      stringsAsFactors = FALSE, nrows = 0L, check.names = FALSE
    )
  }
  observed <- do.call(rbind, lapply(results, `[[`, "observed"))
  finite_summary <- do.call(rbind, lapply(results, `[[`, "finite_summary"))

  editorial_write_csv_v1(
    contrasts, file.path(output_dir, "finite_vs_x_results.csv")
  )
  editorial_write_csv_v1(
    finite_summary, file.path(output_dir, "finite_vs_x_observed_summary.csv")
  )
  editorial_write_csv_v1(
    observed, file.path(output_dir, "observed_summaries.csv")
  )
  editorial_replace_outcome_rows_v1(
    file.path(output_dir, "model_diagnostics.csv"), diagnostics
  )
  editorial_replace_outcome_rows_v1(
    file.path(output_dir, "model_term_support.csv"), term_support
  )
  editorial_replace_outcome_rows_v1(
    file.path(output_dir, "absolute_predictions.csv"), predictions
  )

  execution_path <- file.path(output_dir, "execution_record.yml")
  execution <- yaml::read_yaml(execution_path)
  execution$finite_x_source_label_correction <- "PASS"
  execution$finite_x_source_labels <- c("X", "unquantified_X")
  execution$finite_x_correction_code_commit <- code_commit
  execution$finite_x_corrected_at_utc <- format(
    as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"
  )
  yaml::write_yaml(execution, execution_path)

  output_files <- list.files(output_dir, full.names = TRUE)
  editorial_privacy_column_gate_v1(output_files)
  editorial_write_output_manifest_v1(output_dir)
  message("EDITORIAL_FINITE_X_CORRECTION_GATE=PASS_PENDING_QA_AND_HANDOFF")
  invisible(list(
    contrasts = contrasts, diagnostics = diagnostics,
    finite_summary = finite_summary
  ))
}
