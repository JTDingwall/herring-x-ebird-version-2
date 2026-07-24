editorial_link_count_support_taxon_v1 <- function(
    dat, taxon_id, unit_label) {
  terms <- post_stage4a_exposure_terms_v1()
  rows <- list()
  position <- 0L
  for (term in terms) {
    link_count <- as.integer(dat[[term]])
    for (value in sort(unique(link_count))) {
      use <- link_count == value
      n <- sum(use)
      reported <- use & dat$detection == 1L & !is.na(dat$detection)
      finite <- reported & dat$count_type == "numeric" &
        is.finite(dat$numeric_count) & dat$numeric_count > 0
      unquantified_x <- reported &
        editorial_is_unquantified_x_v1(dat$count_type)
      release <- n >= 20L
      release_reported <- release && sum(reported) >= 20L
      release_finite <- release && sum(finite) >= 20L
      release_x <- release && sum(unquantified_x) >= 20L
      pieces <- strsplit(sub("^es_", "", term), "_", fixed = TRUE)[[1L]]
      position <- position + 1L
      rows[[position]] <- data.frame(
        analysis_taxon_id = taxon_id,
        species = unit_label,
        term = term,
        zone = pieces[[1L]],
        period = paste(pieces[-1L], collapse = "_"),
        link_count = value,
        checklist_rows = if (release) n else NA_real_,
        reported_checklists = if (release_reported) sum(reported) else
          NA_real_,
        reporting_proportion = if (release_reported) sum(reported) / n else
          NA_real_,
        positive_finite_numeric_reports =
          if (release_finite) sum(finite) else NA_real_,
        positive_finite_numeric_median =
          if (release_finite) stats::median(dat$numeric_count[finite]) else
            NA_real_,
        unquantified_x_reports =
          if (release_x) sum(unquantified_x) else NA_real_,
        suppressed_below_20 = !release,
        observed_unadjusted = TRUE,
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, rows)
}

run_editorial_linearity_diagnostics_v1 <- function(
    protected_root, output_dir = "outputs/editorial_requested_analysis_v1",
    code_commit = NA_character_) {
  acknowledgement <- "through_2025_editorial_post_result_v1"
  if (!identical(
      Sys.getenv("EDITORIAL_REQUESTED_ANALYSIS_AUTHORIZED"), acknowledgement)) {
    stop("Exact editorial analysis acknowledgement is required", call. = FALSE)
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
  rows <- lapply(core_taxa, function(taxon_id) {
    label <- species_registry$common_name[
      match(taxon_id, species_registry$analysis_taxon_id)
    ]
    dat <- stage4a_materialize_taxon(
      events, states, masks, taxon_id
    )
    editorial_link_count_support_taxon_v1(dat, taxon_id, label)
  })
  output <- do.call(rbind, rows)
  output_path <- file.path(output_dir, "link_count_outcome_support.csv")
  editorial_write_csv_v1(output, output_path)
  editorial_privacy_column_gate_v1(output_path)
  execution <- list(
    analysis_version = "editorial_linearity_diagnostics_v1",
    code_commit = code_commit,
    executed_at_utc = format(
      as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"
    ),
    species = length(core_taxa),
    eligible_checklists = nrow(events),
    response_fields_used_only_for_privacy_safe_aggregation = TRUE,
    protected_input_hashes = as.list(observed_hashes),
    records_2026_plus_read = 0L,
    protected_rows_released = 0L,
    privacy_column_gate = "PASS"
  )
  yaml::write_yaml(
    execution, file.path(output_dir, "linearity_execution_record.yml")
  )
  message("EDITORIAL_LINEARITY_SUPPORT_GATE=PASS_PENDING_QA_AND_HANDOFF")
  invisible(output)
}
