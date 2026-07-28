#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
correction_commit <- if (length(args)) args[[1L]] else ""
if (!grepl("^[0-9a-f]{40}$", correction_commit)) {
  stop("A committed correction SHA is required", call. = FALSE)
}

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
source(file.path("R", "stage4a_core.R"), local = FALSE)
source(file.path("R", "stage4a_production.R"), local = FALSE)
source(file.path("R", "post_stage4a_sog_event_study_v1.R"), local = FALSE)
source(
  file.path("R", "post_stage4a_distance_band_sensitivity_v2.R"),
  local = FALSE
)
source(file.path("R", "post_stage4a_staged_refit_v1.R"), local = FALSE)

authorization <- staged_refit_authorization_gate_v1()
if (!identical(
    Sys.getenv("POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED"),
    authorization$environment_acknowledgement$value
)) {
  stop("The exact author-set acknowledgement is required", call. = FALSE)
}

root <- "outputs/post_stage4a_staged_refit_v1"
stage_dir <- file.path(root, "s1_anchor")
audit_path <- file.path(stage_dir, "anchor_shift_audit.csv")
preserved_path <- file.path(
  stage_dir, "anchor_shift_audit_prevalidation_v1.csv"
)
execution_path <- file.path(root, "execution_record_v1.yml")
manifest_path <- file.path(root, "output_hash_manifest_v1.csv")
required_outputs <- c(
  file.path(stage_dir, "estimates_49x2.csv"),
  file.path(stage_dir, "delta_vs_parent.csv"),
  file.path(stage_dir, "guild_timing.csv"),
  file.path(stage_dir, "distance_bands_3species.csv"),
  file.path(root, "negative_controls_all_stages.csv")
)
if (!all(file.exists(c(
    audit_path, execution_path, manifest_path, required_outputs
)))) {
  stop("STAGED_REFIT_AUDIT_CORRECTION_GATE: Stage 1 output unavailable",
       call. = FALSE)
}

manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE)
if (anyDuplicated(manifest$file) ||
    !all(file.exists(manifest$file)) ||
    any(vapply(
      manifest$file,
      .post_stage4a_sha256_v1,
      character(1L)
    ) != manifest$sha256)) {
  stop("STAGED_REFIT_AUDIT_CORRECTION_GATE: input manifest mismatch",
       call. = FALSE)
}
protected_result_hashes_before <- vapply(
  required_outputs, .post_stage4a_sha256_v1, character(1L)
)
parent_hashes_before <- staged_refit_parent_hash_snapshot_v1()

if (!file.exists(preserved_path)) {
  copied <- file.copy(audit_path, preserved_path, overwrite = FALSE)
  if (!isTRUE(copied)) {
    stop("STAGED_REFIT_AUDIT_CORRECTION_GATE: preservation failed",
         call. = FALSE)
  }
}
original_audit_hash <- .post_stage4a_sha256_v1(preserved_path)

protected_files <- c(
  event_metadata =
    "data/derived/stage4a_protected/stage4a_event_metadata.tsv.gz",
  source_links_archived =
    "data/derived/stage3_phase2_protected/metadata_source_point_links.tsv.gz",
  source_links_extended = paste0(
    "data/derived/",
    "post_stage4a_distance_band_sensitivity_v2_protected/",
    "link_builder/metadata_source_point_links.tsv.gz"
  )
)
if (!all(file.exists(protected_files))) {
  stop("STAGED_REFIT_AUDIT_CORRECTION_GATE: protected input unavailable",
       call. = FALSE)
}

anchor_lookup <- staged_refit_build_anchor_lookup_v1(
  Sys.getenv("HERRING_EBIRD_V2_HERRING", unset = "")
)
events_all <- .stage4a_prepare_events(
  .stage4a_read_gz(protected_files[["event_metadata"]])
)
selected <- events_all$region == "SoG" &
  events_all$checklist_year >= 2005L &
  events_all$checklist_year <= 2025L
events <- events_all[selected, , drop = FALSE]
if (nrow(events) != 217200L ||
    any(as.integer(events$checklist_year) > 2025L)) {
  stop("STAGED_REFIT_AUDIT_CORRECTION_GATE: event population changed",
       call. = FALSE)
}

archived <- .stage4a_read_gz(
  protected_files[["source_links_archived"]]
)
extended <- .stage4a_read_gz(
  protected_files[["source_links_extended"]]
)
event_tokens <- events$analysis_event_token
parent_selected <- archived[
  archived$analysis_event_token %in% event_tokens, , drop = FALSE
]
archived_anchored <- staged_refit_reanchor_links_v1(
  archived, anchor_lookup
)
anchored_selected <- archived_anchored[
  archived_anchored$analysis_event_token %in% event_tokens,
  ,
  drop = FALSE
]
extended_anchored <- staged_refit_reanchor_links_v1(
  extended, anchor_lookup
)
extended_selected <- extended_anchored[
  extended_anchored$analysis_event_token %in% event_tokens,
  ,
  drop = FALSE
]
audit <- staged_refit_anchor_audit_v1(
  events,
  parent_selected,
  anchored_selected,
  anchor_lookup,
  distribution_links = extended_selected
)

existing_migration <- utils::read.csv(
  file.path(stage_dir, "link_period_migration.csv"),
  stringsAsFactors = FALSE
)
if (!isTRUE(all.equal(
    existing_migration, audit$migration,
    check.attributes = FALSE
))) {
  stop("STAGED_REFIT_AUDIT_CORRECTION_GATE: migration changed",
       call. = FALSE)
}
.post_stage4a_write_csv_v1(audit$anchor_audit, audit_path)

execution <- yaml::read_yaml(execution_path)
correction <- list(
  correction_version =
    "post_stage4a_staged_refit_s1_anchor_audit_correction_v1",
  correction_code_commit = correction_commit,
  corrected_at_utc = format(
    as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"
  ),
  results_known_at_correction = TRUE,
  model_refit = FALSE,
  protected_responses_read = FALSE,
  reason = paste0(
    "Literal NA date tokens were not counted as raw missing values, ",
    "and the shift distribution used the 20 km primary-link universe ",
    "instead of the prespecified 26 km all-linked-event audit universe."
  ),
  original_audit_preserved_as =
    gsub("\\\\", "/", preserved_path),
  original_audit_sha256 = original_audit_hash,
  corrected_linked_source_event_universe =
    "all SoG 2005-2025 source events linked within 26 km",
  fitted_estimates_modified = FALSE
)
existing_corrections <- execution$post_execution_corrections
if (is.null(existing_corrections)) existing_corrections <- list()
execution$post_execution_corrections <- c(
  existing_corrections, list(correction)
)
yaml::write_yaml(execution, execution_path)

protected_result_hashes_after <- vapply(
  required_outputs, .post_stage4a_sha256_v1, character(1L)
)
if (!identical(
    protected_result_hashes_before, protected_result_hashes_after
)) {
  stop("STAGED_REFIT_AUDIT_CORRECTION_GATE: fitted result changed",
       call. = FALSE)
}
if (!identical(
    parent_hashes_before, staged_refit_parent_hash_snapshot_v1()
)) {
  stop("STAGED_REFIT_AUDIT_CORRECTION_GATE: parent output changed",
       call. = FALSE)
}
staged_refit_privacy_column_gate_v1(c(
  audit_path, preserved_path, required_outputs
))
corrected_manifest <- staged_refit_output_manifest_v1(root)
.post_stage4a_write_csv_v1(corrected_manifest, manifest_path)

message(
  "POST_STAGE4A_STAGED_REFIT_S1_ANCHOR_AUDIT_CORRECTION=PASS_NO_MODEL_REFIT"
)
