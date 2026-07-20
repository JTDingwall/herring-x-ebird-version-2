parse_ebird_count <- function(x) {
  x <- trimws(as.character(x))
  numeric_value <- suppressWarnings(as.numeric(x))
  data.table::data.table(
    source_count = x,
    detection = as.integer(!is.na(x) & nzchar(x)),
    numeric_count = numeric_value,
    count_type = data.table::fifelse(is.na(x) | !nzchar(x), "missing",
      data.table::fifelse(x == "X", "X",
        data.table::fifelse(!is.na(numeric_value), "numeric", "other_non_numeric")))
  )
}

build_guild_outcomes <- function(checklist_species, species_registry) {
  required <- c("sampling_event_identifier", "legacy_analysis_taxon_id", "detection", "numeric_count", "count_type")
  assert_columns(checklist_species, required, "checklist-species table")
  reg <- species_registry[, .(legacy_analysis_taxon_id, guild_id)]
  x <- merge(checklist_species, reg, by = "legacy_analysis_taxon_id", all.x = TRUE, sort = FALSE)
  if (anyNA(x$guild_id)) stop("Checklist-species rows contain taxa absent from species registry", call. = FALSE)
  x[, .(
    guild_any_detection = as.integer(any(detection == 1L, na.rm = TRUE)),
    guild_richness = sum(detection == 1L, na.rm = TRUE),
    guild_numeric_total = sum(numeric_count, na.rm = TRUE),
    guild_numeric_species = sum(!is.na(numeric_count)),
    guild_has_unquantified_detection = any(detection == 1L & count_type != "numeric", na.rm = TRUE),
    guild_max_numeric_count = if (all(is.na(numeric_count))) NA_real_ else max(numeric_count, na.rm = TRUE)
  ), by = .(sampling_event_identifier, guild_id)]
}

aggregation_thresholds <- function(counts, group, probs = c(0.90, 0.95, 0.99)) {
  x <- data.table::data.table(group = group, count = counts)
  x[!is.na(count) & count > 0, .(
    probability = probs,
    threshold = as.numeric(stats::quantile(count, probs = probs, na.rm = TRUE, type = 8))
  ), by = group]
}
