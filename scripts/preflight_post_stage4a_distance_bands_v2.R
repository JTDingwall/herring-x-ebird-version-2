#!/usr/bin/env Rscript

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
source(file.path("R", "stage4a_core.R"), local = FALSE)
source(file.path("R", "stage4a_production.R"), local = FALSE)
source(file.path("R", "post_stage4a_sog_event_study_v1.R"), local = FALSE)

required_packages <- c("data.table", "digest", "yaml")
missing <- required_packages[!vapply(
  required_packages, requireNamespace, logical(1L), quietly = TRUE
)]
if (length(missing)) {
  stop("Missing packages: ", paste(missing, collapse = ", "),
       call. = FALSE)
}

link_path <- file.path(
  "data", "derived",
  "post_stage4a_distance_band_sensitivity_v2_protected",
  "link_builder", "metadata_source_point_links.tsv.gz"
)
archived_link_path <- file.path(
  "data", "derived", "stage3_phase2_protected",
  "metadata_source_point_links.tsv.gz"
)
event_path <- file.path(
  "data", "derived", "stage4a_protected",
  "stage4a_event_metadata.tsv.gz"
)
state_path <- file.path(
  "data", "derived", "stage4a_protected",
  "stage4a_reported_states.tsv.gz"
)
mask_path <- file.path(
  "data", "derived", "stage4a_protected",
  "stage4a_ambiguity_masks.tsv.gz"
)
stopifnot(all(file.exists(c(
  link_path, archived_link_path, event_path, state_path, mask_path
))))

links <- .stage4a_read_gz(link_path)
archived <- .stage4a_read_gz(archived_link_path)
events_all <- .stage4a_read_gz(event_path)
if (nrow(events_all) != 239934L ||
    any(as.integer(events_all$checklist_year) > 2025L)) {
  stop("PREFLIGHT_EVENT_SCOPE_GATE: protected event population changed",
       call. = FALSE)
}
events_all <- .stage4a_prepare_events(events_all)
selected <- events_all$region == "SoG" &
  events_all$checklist_year >= 2005L &
  events_all$checklist_year <= 2025L
if (anyNA(selected) || sum(selected) != 217200L) {
  stop("PREFLIGHT_SOG_SCOPE_GATE: expected 217200 events",
       call. = FALSE)
}
events <- events_all[selected, , drop = FALSE]
rm(events_all)

key <- function(x) paste(
  x$analysis_event_token, x$herring_source_token, sep = "\r"
)
inner_new <- links[as.numeric(links$distance_km) <= 20, , drop = FALSE]
if (nrow(inner_new) != nrow(archived) ||
    !setequal(key(inner_new), key(archived))) {
  stop("PREFLIGHT_ARCHIVED_LINK_RECONCILIATION_GATE: 0-20 km changed",
       call. = FALSE)
}
new_index <- match(key(archived), key(inner_new))
if (anyNA(new_index) ||
    max(abs(
      as.numeric(archived$distance_km) -
        as.numeric(inner_new$distance_km[new_index])
    )) > 0.0011 ||
    !identical(
      as.integer(archived$event_day),
      as.integer(inner_new$event_day[new_index])
    )) {
  stop("PREFLIGHT_ARCHIVED_LINK_VALUE_GATE: 0-20 km changed",
       call. = FALSE)
}
if (any(as.numeric(links$distance_km) < 0 |
        as.numeric(links$distance_km) > 26.0001)) {
  stop("PREFLIGHT_EXTENDED_LINK_RANGE_GATE: invalid distance",
       call. = FALSE)
}

event_tokens <- as.character(events$analysis_event_token)
selected_links <- links[
  as.character(links$analysis_event_token) %in% event_tokens &
    as.integer(links$event_day) >= -28L &
    as.integer(links$event_day) <= 28L,
  ,
  drop = FALSE
]
match_index <- match(selected_links$analysis_event_token, event_tokens)
if (anyNA(match_index) ||
    any(as.integer(selected_links$checklist_year) !=
        as.integer(events$checklist_year[match_index]))) {
  stop("PREFLIGHT_LINK_EVENT_JOIN_GATE: expected many-to-one join failed",
       call. = FALSE)
}
if (anyDuplicated(key(selected_links))) {
  stop("PREFLIGHT_LINK_KEY_GATE: duplicate checklist-source links",
       call. = FALSE)
}

period <- rep(NA_character_, nrow(selected_links))
day <- as.integer(selected_links$event_day)
period[day >= -28L & day <= -15L] <- "baseline"
period[day >= -14L & day <= -8L] <- "early_pre"
period[day >= -7L & day <= -1L] <- "immediate_pre"
period[day >= 0L & day <= 3L] <- "spawn_start"
period[day >= 4L & day <= 14L] <- "early_egg"
period[day >= 15L & day <= 28L] <- "late_egg"

distance <- as.numeric(selected_links$distance_km)
breaks <- seq(0, 26, by = 2)
band_index <- findInterval(
  distance, breaks, rightmost.closed = TRUE, all.inside = TRUE
)
band_index[band_index == length(breaks)] <- length(breaks) - 1L
band_min <- breaks[band_index]
band_max <- breaks[band_index + 1L]
band <- paste0("band_", band_min, "_", band_max)
term <- paste("db", band, period, sep = "_")

link_dt <- data.table::data.table(
  analysis_event_token = selected_links$analysis_event_token,
  term = term
)
counts <- link_dt[, .(exposure_links = .N),
                  by = .(analysis_event_token, term)]
wide <- data.table::dcast(
  counts, analysis_event_token ~ term,
  value.var = "exposure_links", fill = 0L
)
event_dt <- data.table::as.data.table(data.table::copy(events))
event_dt[, row_order__ := .I]
joined <- merge(
  event_dt, wide, by = "analysis_event_token",
  all.x = TRUE, sort = FALSE
)
data.table::setorder(joined, row_order__)
joined[, row_order__ := NULL]
if (nrow(joined) != nrow(events) ||
    anyDuplicated(joined$analysis_event_token)) {
  stop("PREFLIGHT_EXPOSURE_AGGREGATION_GATE: event grain changed",
       call. = FALSE)
}
terms <- as.vector(outer(
  paste0("band_", breaks[-length(breaks)], "_", breaks[-1L]),
  c(
    "baseline", "early_pre", "immediate_pre",
    "spawn_start", "early_egg", "late_egg"
  ),
  function(b, p) paste("db", b, p, sep = "_")
))
for (term_now in terms) {
  if (!term_now %in% names(joined)) joined[, (term_now) := 0L]
  data.table::set(
    joined, which(is.na(joined[[term_now]])), term_now, 0L
  )
}

states_all <- .stage4a_read_gz(state_path)
masks_all <- .stage4a_read_gz(mask_path)
if (nrow(states_all) != 1169612L || nrow(masks_all) != 5834L) {
  stop("PREFLIGHT_RESPONSE_CACHE_GATE: protected cache changed",
       call. = FALSE)
}
states <- states_all[
  states_all$analysis_event_token %in% event_tokens, , drop = FALSE
]
masks <- masks_all[
  masks_all$analysis_event_token %in% event_tokens, , drop = FALSE
]
registry <- utils::read.csv(
  "metadata/canonical_species_registry.csv",
  stringsAsFactors = FALSE
)
target_id <- registry$analysis_taxon_id[
  registry$common_name == "Bald Eagle"
]
if (!identical(target_id, "atx_fc0a9b777dcd")) {
  stop("PREFLIGHT_TAXON_GATE: Bald Eagle mismatch", call. = FALSE)
}
denominator <- stage4a_materialize_taxon(
  as.data.frame(joined), states, masks, target_id
)
rm(states_all, masks_all, states, masks)

outcomes <- list(
  detection = rep(TRUE, nrow(denominator)),
  positive_numeric_count_given_detection =
    denominator$detection == 1L &
    is.finite(denominator$numeric_count) &
    denominator$numeric_count > 0
)
support_rows <- list()
row_index <- 1L
for (outcome in names(outcomes)) {
  model_rows <- outcomes[[outcome]]
  for (term_now in terms) {
    bits <- strsplit(sub("^db_band_", "", term_now), "_",
                     fixed = TRUE)[[1L]]
    support_rows[[row_index]] <- data.frame(
      outcome = outcome,
      band = paste0("band_", bits[[1L]], "_", bits[[2L]]),
      band_label = paste0(bits[[1L]], "\u2013", bits[[2L]], " km"),
      period = paste(bits[-c(1L, 2L)], collapse = "_"),
      exposed_model_rows = sum(
        model_rows & denominator[[term_now]] > 0L
      ),
      stringsAsFactors = FALSE
    )
    row_index <- row_index + 1L
  }
}
support <- do.call(rbind, support_rows)
if (any(support$exposed_model_rows < 0L)) {
  stop("PREFLIGHT_SUPPORT_GATE: invalid support count", call. = FALSE)
}

aggregate_dir <- file.path(
  "outputs", "post_stage4a_distance_band_sensitivity_v2_preflight"
)
dir.create(aggregate_dir, recursive = TRUE, showWarnings = FALSE)
utils::write.csv(
  support,
  file.path(aggregate_dir, "candidate_2km_model_term_support_v2.csv"),
  row.names = FALSE, quote = TRUE, na = ""
)
summary <- aggregate(
  exposed_model_rows ~ outcome + band + band_label,
  support,
  FUN = min
)
names(summary)[names(summary) == "exposed_model_rows"] <-
  "minimum_period_exposed_model_rows"
utils::write.csv(
  summary,
  file.path(aggregate_dir, "candidate_2km_band_minimum_support_v2.csv"),
  row.names = FALSE, quote = TRUE, na = ""
)
record <- list(
  status = "PASS_PENDING_CONCRETE_BAND_LOCK",
  analysis_status = "response_aware_support_only_no_model_fit",
  maximum_checklist_year_read = 2025L,
  records_2026_plus_read = 0L,
  response_models_fit = 0L,
  archived_0_20km_links_reconciled = TRUE,
  candidate_bands = 13L,
  minimum_release_cell_size = 20L,
  protected_extended_links_committed = FALSE,
  exact_coordinates_released = FALSE,
  identifiers_released = FALSE
)
yaml::write_yaml(
  record,
  file.path(aggregate_dir, "preflight_execution_record_v2.yml")
)
message("POST_STAGE4A_DISTANCE_BAND_V2_PREFLIGHT=PASS")
