#!/usr/bin/env Rscript

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
suppressPackageStartupMessages({
  library(data.table)
  library(digest)
})
source(file.path("R", "stage4a_core.R"), local = FALSE)
source(file.path("R", "stage4a_production.R"), local = FALSE)
source(file.path("R", "post_stage4a_sog_event_study_v1.R"), local = FALSE)
source(file.path("R", "post_stage4a_distance_band_sensitivity_v2.R"),
       local = FALSE)

protected_dir <- file.path(
  "data", "derived", "post_stage4a_distance_band_followup_v1_protected"
)
output_dir <- "outputs/post_stage4a_distance_band_followup_v1_preflight"
dir.create(protected_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

candidates <- c(
  "American Robin", "Chestnut-backed Chickadee", "Dark-eyed Junco"
)
candidate_file <- file.path(protected_dir, "control_candidates.txt")
extract_file <- file.path(
  protected_dir, "control_candidate_rows_pre2026.tsv"
)
if (!file.exists(candidate_file) ||
    !identical(readLines(candidate_file, warn = FALSE), candidates)) {
  stop("CONTROL_PREFLIGHT_CANDIDATE_LOCK_GATE: pattern file mismatch",
       call. = FALSE)
}

if (!file.exists(extract_file) || file.info(extract_file)$size == 0) {
  ebd_path <- Sys.getenv("HERRING_EBIRD_V2_EBD", unset = "")
  if (!nzchar(ebd_path) || !file.exists(ebd_path)) {
    stop("CONTROL_PREFLIGHT_EBD_GATE: configured EBD unavailable",
         call. = FALSE)
  }
  status <- system2(
    "powershell",
    c(
      "-NoProfile", "-ExecutionPolicy", "Bypass",
      "-File", "scripts/run_ebd_streaming_tool.ps1",
      "-Mode", "focal", "-EbdEnv", "HERRING_EBIRD_V2_EBD",
      "-Patterns", shQuote(candidate_file),
      "-Output", shQuote(extract_file)
    )
  )
  if (!identical(status, 0L) ||
      !file.exists(extract_file) || file.info(extract_file)$size == 0) {
    stop("CONTROL_PREFLIGHT_EXTRACTION_GATE: streaming extraction failed",
         call. = FALSE)
  }
}

ebd_names <- c(
  "CATEGORY", "TAXON CONCEPT ID", "COMMON NAME", "SCIENTIFIC NAME",
  "OBSERVATION COUNT", "BEHAVIOR CODE",
  "SAMPLING EVENT IDENTIFIER", "OBSERVATION DATE"
)
ebd <- fread(
  extract_file, sep = "\t", header = TRUE, select = ebd_names,
  quote = "", na.strings = c("", "NA"), showProgress = FALSE
)
setnames(
  ebd, ebd_names,
  c(
    "category", "taxon_concept_id", "common_name", "scientific_name",
    "observation_count", "behavior_code", "source_id", "observation_date"
  )
)
ebd[, observation_date := as.IDate(observation_date)]
if (any(ebd$observation_date > as.IDate("2025-12-31"), na.rm = TRUE)) {
  stop("CONTROL_PREFLIGHT_YEAR_GATE: 2026+ response row persisted",
       call. = FALSE)
}
ebd <- ebd[category == "species" & common_name %chin% candidates]
if (!setequal(unique(ebd$common_name), candidates)) {
  stop("CONTROL_PREFLIGHT_TAXON_GATE: candidate missing from extract",
       call. = FALSE)
}
taxonomy <- ebd[, .(
  scientific_name = paste(sort(unique(scientific_name)), collapse = ";"),
  source_taxon_concepts = uniqueN(taxon_concept_id)
), by = common_name]
if (any(grepl(";", taxonomy$scientific_name, fixed = TRUE))) {
  stop("CONTROL_PREFLIGHT_TAXONOMY_GATE: scientific-name ambiguity",
       call. = FALSE)
}

sed_cache <- readRDS(file.path(
  "outputs", "input_audit_local", "stage2", "sed_stage2_cache.rds"
))
if (!identical(sort(names(sed_cache)), sort(c(
    "checklists", "cross_private", "shared_audit"
)))) {
  stop("CONTROL_PREFLIGHT_SED_CACHE_GATE: unexpected cache schema",
       call. = FALSE)
}
cross <- as.data.table(sed_cache$cross_private)[
  , .(source_id, analysis_id)
]
if (anyDuplicated(cross$source_id)) {
  stop("CONTROL_PREFLIGHT_SOURCE_JOIN_GATE: crosswalk source duplicated",
       call. = FALSE)
}
setkey(cross, source_id)
ebd <- cross[ebd, on = "source_id", nomatch = 0L]
if (!nrow(ebd)) {
  stop("CONTROL_PREFLIGHT_SOURCE_JOIN_GATE: no candidate rows joined",
       call. = FALSE)
}

parse_state <- function(x) {
  raw <- trimws(as.character(x))
  numeric_syntax <- grepl("^[0-9]+$", raw)
  lower_syntax <- grepl(
    "^(>=|>|at least[[:space:]]+)?[0-9]+[+]?$",
    raw, ignore.case = TRUE
  ) & !numeric_syntax
  data.table(
    count_state = fifelse(
      toupper(raw) == "X", "X",
      fifelse(
        numeric_syntax, "numeric",
        fifelse(lower_syntax, "lower_bound", "ambiguity_affected")
      )
    ),
    numeric_count = fifelse(numeric_syntax, as.numeric(raw), NA_real_),
    lower_bound_count = fifelse(
      lower_syntax, as.numeric(gsub("[^0-9]", "", raw)), NA_real_
    )
  )
}
states <- parse_state(ebd$observation_count)
ebd[, c("count_state", "numeric_count", "lower_bound_count") := states]
collapsed <- ebd[, {
  signatures <- unique(paste(
    count_state, numeric_count, lower_bound_count, sep = "|"
  ))
  if (length(signatures) == 1L) {
    .(
      count_state = count_state[[1L]],
      numeric_count = numeric_count[[1L]],
      lower_bound_count = lower_bound_count[[1L]],
      source_report_disagreement = FALSE
    )
  } else {
    .(
      count_state = "ambiguity_affected",
      numeric_count = NA_real_,
      lower_bound_count = NA_real_,
      source_report_disagreement = TRUE
    )
  }
}, by = .(analysis_id, common_name)]
if (anyDuplicated(collapsed[, .(analysis_id, common_name)])) {
  stop("CONTROL_PREFLIGHT_COLLAPSE_GATE: duplicate analysis outcome",
       call. = FALSE)
}

hash_analysis_event <- function(x) {
  substr(vapply(
    paste0("analysis_event|", x),
    digest, character(1L), algo = "sha256", serialize = FALSE
  ), 1L, 24L)
}
collapsed[, analysis_event_token := hash_analysis_event(analysis_id)]

events_all <- .stage4a_prepare_events(.stage4a_read_gz(file.path(
  "data", "derived", "stage4a_protected", "stage4a_event_metadata.tsv.gz"
)))
if (nrow(events_all) != 239934L ||
    any(as.integer(events_all$checklist_year) > 2025L)) {
  stop("CONTROL_PREFLIGHT_EVENT_GATE: protected population changed",
       call. = FALSE)
}
selected <- events_all$region == "SoG" &
  events_all$checklist_year >= 2005L &
  events_all$checklist_year <= 2025L
if (anyNA(selected) || sum(selected) != 217200L) {
  stop("CONTROL_PREFLIGHT_SOG_GATE: expected 217200 rows", call. = FALSE)
}
events <- events_all[selected, , drop = FALSE]
rm(events_all)
event_tokens <- events$analysis_event_token
if (anyDuplicated(event_tokens)) {
  stop("CONTROL_PREFLIGHT_EVENT_KEY_GATE: duplicate event token",
       call. = FALSE)
}
collapsed <- collapsed[analysis_event_token %chin% event_tokens]

archived_path <- file.path(
  "data", "derived", "stage3_phase2_protected",
  "metadata_source_point_links.tsv.gz"
)
extended_path <- file.path(
  "data", "derived",
  "post_stage4a_distance_band_sensitivity_v2_protected",
  "link_builder", "metadata_source_point_links.tsv.gz"
)
archived <- .stage4a_read_gz(archived_path)
extended <- .stage4a_read_gz(extended_path)
link_key <- function(x) paste(
  x$analysis_event_token, x$herring_source_token, sep = "\r"
)
archived_key <- link_key(archived)
extended_key <- link_key(extended)
if (anyDuplicated(archived_key) || anyDuplicated(extended_key) ||
    !all(archived_key %in% extended_key)) {
  stop("CONTROL_PREFLIGHT_LINK_RECONCILIATION_GATE: failed",
       call. = FALSE)
}
archived$link_provenance__ <- "archived_0_20"
extra <- extended[!extended_key %in% archived_key, , drop = FALSE]
if (!nrow(extra) || any(as.numeric(extra$distance_km) < 20 |
                        as.numeric(extra$distance_km) > 26.0001)) {
  stop("CONTROL_PREFLIGHT_LINK_EXTENSION_GATE: expected 20-26 only",
       call. = FALSE)
}
extra$link_provenance__ <- "new_20_26"
links <- rbind(archived, extra)
joint <- post_stage4a_add_distance_band_exposure_v2(events, links)
events <- joint$events
rm(archived, extended, extra, links, joint)

terms <- post_stage4a_distance_band_terms_v2()
support_rows <- vector("list", length(candidates))
for (i in seq_along(candidates)) {
  nm <- candidates[[i]]
  z <- collapsed[common_name == nm]
  idx <- match(event_tokens, z$analysis_event_token)
  detection <- ifelse(is.na(idx), 0L, 1L)
  ambiguity <- !is.na(idx) &
    z$count_state[idx] == "ambiguity_affected"
  detection[ambiguity] <- NA_integer_
  numeric_count <- z$numeric_count[idx]
  positive <- is.finite(numeric_count) & numeric_count > 0
  term_count_support <- vapply(
    terms, function(term) sum(events[[term]][positive] > 0L), integer(1L)
  )
  term_detection_support <- vapply(
    terms, function(term) sum(events[[term]][!is.na(detection)] > 0L),
    integer(1L)
  )
  support_rows[[i]] <- data.table(
    common_name = nm,
    scientific_name = taxonomy$scientific_name[
      match(nm, taxonomy$common_name)
    ],
    eligible_checklists = nrow(events),
    model_rows_detection = sum(!is.na(detection)),
    detected_checklists = sum(detection == 1L, na.rm = TRUE),
    structural_unknown_checklists = sum(is.na(detection)),
    positive_numeric_model_rows = sum(positive),
    minimum_detection_term_support = min(term_detection_support),
    minimum_positive_numeric_term_support = min(term_count_support),
    all_78_detection_terms_at_least_20 =
      all(term_detection_support >= 20L),
    all_78_positive_numeric_terms_at_least_20 =
      all(term_count_support >= 20L),
    source_rows_released = FALSE
  )
}
support <- rbindlist(support_rows)
support[, selected_role := fifelse(
  common_name == "American Robin", "mandatory_control",
  "candidate_second_control"
)]
second <- support[
  common_name != "American Robin" &
    all_78_detection_terms_at_least_20 &
    all_78_positive_numeric_terms_at_least_20
][order(
  -minimum_positive_numeric_term_support,
  -positive_numeric_model_rows,
  common_name
)][1L]
if (nrow(second) != 1L) {
  stop("CONTROL_PREFLIGHT_SELECTION_GATE: no eligible second control",
       call. = FALSE)
}
support[, recommended_for_fit := common_name %chin%
          c("American Robin", second$common_name)]
support[, candidate_order__ := match(common_name, candidates)]
setorder(support, candidate_order__)
support[, candidate_order__ := NULL]
fwrite(
  support,
  file.path(output_dir, "control_candidate_support_v1.csv"),
  quote = TRUE, na = ""
)

selection <- c(
  "selection_version: post_stage4a_distance_band_followup_control_selection_v1",
  "selection_basis: locked_support_only_rule",
  "effects_inspected_before_selection: false",
  "mandatory_control: American Robin",
  paste0("selected_second_control: ", second$common_name),
  paste0(
    "selected_second_minimum_positive_numeric_term_support: ",
    second$minimum_positive_numeric_term_support
  ),
  paste0(
    "selected_second_total_positive_numeric_model_rows: ",
    second$positive_numeric_model_rows
  ),
  "all_78_terms_pass_minimum_20: true",
  "registered_49_species_family_changed: false",
  "controls_enter_primary_BH_family: false",
  "final_gate: PASS_PENDING_COMMITTED_SELECTION_BEFORE_EFFECT_FIT"
)
writeLines(
  selection,
  file.path(protected_dir, "control_selection_candidate_v1.yml"),
  useBytes = TRUE
)
message(
  "CONTROL_PREFLIGHT_PASS: second control recommended by locked rule = ",
  second$common_name
)
