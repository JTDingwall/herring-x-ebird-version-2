#!/usr/bin/env Rscript

# Outcome-support and geometry-only selection between the two authorized
# conventional exposure sensitivities. This script does not fit a model,
# calculate a coefficient, or read an existing effect estimate.

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
library_path <- Sys.getenv("EDITORIAL_R_LIBRARY", "")
if (nzchar(library_path)) .libPaths(c(library_path, .libPaths()))

source(file.path("R", "stage4a_core.R"), local = FALSE)
source(file.path("R", "stage4a_production.R"), local = FALSE)
source(file.path("R", "post_stage4a_sog_event_study_v1.R"), local = FALSE)
source(file.path("R", "editorial_requested_analysis_v1.R"), local = FALSE)
source(file.path("R", "editorial_sensitivity_v1.R"), local = FALSE)

acknowledgement <- "through_2025_editorial_post_result_v1"
if (!identical(
    Sys.getenv("EDITORIAL_REQUESTED_ANALYSIS_AUTHORIZED"),
    acknowledgement)) {
  stop("Exact editorial analysis acknowledgement is required", call. = FALSE)
}

protected_root <- Sys.getenv("EDITORIAL_PROTECTED_ROOT", "")
if (!nzchar(protected_root)) {
  stop("EDITORIAL_PROTECTED_ROOT must point to the frozen data/derived root",
       call. = FALSE)
}

output_dir <- "outputs/conventional_exposure_sensitivity_v1"
selection_path <- file.path(output_dir, "design_selection.csv")
final_result_path <- file.path(
  output_dir, "conventional_exposure_sensitivity_results.csv"
)
if (file.exists(final_result_path)) {
  stop(
    "DESIGN_SELECTION_TIMING_GATE: final results already exist; ",
    "the design choice may not be rewritten post-fit",
    call. = FALSE
  )
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
  stop("CONVENTIONAL_PROTECTED_INPUT_HASH_GATE: mismatch", call. = FALSE)
}

events_all <- .stage4a_read_gz(protected_files[["event_metadata"]])
if (nrow(events_all) != 239934L ||
    any(as.integer(events_all$checklist_year) > 2025L)) {
  stop("CONVENTIONAL_THROUGH_2025_EVENT_GATE: failed", call. = FALSE)
}
events_all <- .stage4a_prepare_events(events_all)
selected <- events_all$region == "SoG" &
  events_all$checklist_year >= 2005L &
  events_all$checklist_year <= 2025L
if (anyNA(selected) || sum(selected) != 217200L) {
  stop("CONVENTIONAL_SOG_POPULATION_GATE: expected 217200", call. = FALSE)
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
events <- post_stage4a_add_joint_exposure_v1(events, links)$events
rm(links, selected_links)

states_all <- .stage4a_read_gz(protected_files[["reported_states"]])
masks_all <- .stage4a_read_gz(protected_files[["ambiguity_masks"]])
if (nrow(states_all) != 1169612L || nrow(masks_all) != 5834L) {
  stop("CONVENTIONAL_SPARSE_STATE_CARDINALITY_GATE: failed", call. = FALSE)
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
  stop("CONVENTIONAL_SPECIES_FAMILY_GATE: expected 49 species",
       call. = FALSE)
}

terms <- post_stage4a_exposure_terms_v1()
outcomes <- c(
  "checklist_reporting", "conditional_positive_numeric_count"
)

component_support <- function(candidate, candidate_events) {
  do.call(rbind, lapply(core_taxa, function(taxon_id) {
    unit_label <- species_registry$common_name[
      match(taxon_id, species_registry$analysis_taxon_id)
    ]
    dat <- stage4a_materialize_taxon(
      candidate_events, states, masks, taxon_id
    )
    do.call(rbind, lapply(outcomes, function(outcome) {
      if (outcome == "checklist_reporting") {
        use <- !is.na(dat$detection)
        response <- dat$detection[use]
      } else {
        use <- is.finite(dat$numeric_count) & dat$numeric_count > 0
        response <- log(dat$numeric_count[use])
      }
      d <- dat[use, , drop = FALSE]
      exposed <- vapply(
        terms, function(term) sum(d[[term]] > 0L), integer(1L)
      )
      grouping_levels <- c(
        event_block_token = length(unique(d$event_block_token)),
        observer_cluster_token = length(unique(d$observer_cluster_token)),
        location_cluster_token = length(unique(d$location_cluster_token))
      )
      adequate <- nrow(d) >= 20L &&
        all(exposed >= 20L) &&
        length(unique(response)) >= 2L &&
        all(grouping_levels >= 2L)
      data.frame(
        candidate = candidate,
        analysis_taxon_id = taxon_id,
        species = unit_label,
        outcome = outcome,
        model_rows = nrow(d),
        minimum_exposed_rows_across_12_terms = min(exposed),
        adequate_support = adequate,
        stringsAsFactors = FALSE
      )
    }))
  }))
}

candidate_ids <- c("single_event", "nearest_event")
candidate_results <- lapply(candidate_ids, function(candidate) {
  transformed <- editorial_sensitivity_transform_v1(
    candidate, events, classified
  )
  candidate_events <- transformed$events
  design <- editorial_base_design_v1(candidate_events)
  support <- component_support(candidate, candidate_events)
  outcome_counts <- vapply(outcomes, function(outcome) {
    sum(support$adequate_support[support$outcome == outcome])
  }, integer(1L))
  data.frame(
    candidate = candidate,
    retained_checklists = nrow(candidate_events),
    retained_fraction = nrow(candidate_events) / nrow(events),
    fixed_effect_columns = ncol(design),
    fixed_effect_rank = qr(design)$rank,
    overall_minimum_exposed_rows_across_12_terms = min(vapply(
      terms, function(term) sum(candidate_events[[term]] > 0L), integer(1L)
    )),
    supported_checklist_reporting_components =
      outcome_counts[["checklist_reporting"]],
    supported_conditional_count_components =
      outcome_counts[["conditional_positive_numeric_count"]],
    stringsAsFactors = FALSE
  )
})
selection <- do.call(rbind, candidate_results)

single_count <- selection$supported_conditional_count_components[
  selection$candidate == "single_event"
]
nearest_count <- selection$supported_conditional_count_components[
  selection$candidate == "nearest_event"
]
single_reporting <- selection$supported_checklist_reporting_components[
  selection$candidate == "single_event"
]
nearest_reporting <- selection$supported_checklist_reporting_components[
  selection$candidate == "nearest_event"
]

if (!identical(single_reporting, 49L) ||
    !identical(nearest_reporting, 49L) ||
    single_count >= nearest_count ||
    nearest_count < 40L) {
  stop(
    "CONVENTIONAL_DESIGN_DECISION_GATE: observed support does not match ",
    "the prerecordable nearest-event decision conditions",
    call. = FALSE
  )
}

selection$selected <- selection$candidate == "nearest_event"
selection$decision_basis <- ifelse(
  selection$selected,
  paste0(
    "selected before fitting: full-rank geometry; support-qualified under ",
    "the existing component gate for all 49 reporting and ",
    nearest_count, " of 49 conditional-count components"
  ),
  paste0(
    "not selected: although preferred if adequate, the complete ",
    "single-event subset retained only ", single_count,
    " of 49 conditional-count components under the existing support gate"
  )
)
selection$selection_used_effect_estimates <- FALSE
selection$models_fitted_during_selection <- 0L
selection$records_2026_plus_read <- 0L
selection$protected_rows_released <- 0L
selection$event_metadata_sha256 <- observed_hashes[["event_metadata"]]
selection$source_links_sha256 <- observed_hashes[["source_links"]]
selection$reported_states_sha256 <- observed_hashes[["reported_states"]]
selection$ambiguity_masks_sha256 <- observed_hashes[["ambiguity_masks"]]
selection$recorded_at_utc <- format(
  as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"
)

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
editorial_write_csv_v1(selection, selection_path)
editorial_privacy_column_gate_v1(selection_path)
message(
  "CONVENTIONAL_DESIGN_SELECTION=nearest_event; ",
  "single_event_count_support=", single_count,
  "; nearest_event_count_support=", nearest_count,
  "; models_fitted=0"
)
