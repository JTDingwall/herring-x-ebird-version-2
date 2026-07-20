# Ported and generalized from Version 1 eBird ingestion/processing utilities.

inspect_delimited_header <- function(path, delimiter = NULL, encoding = "UTF-8",
                                     delimiter_candidates = c("\t", ",", ";", "|")) {
  if (!file.exists(path)) stop("HEADER_INPUT: missing file", call. = FALSE)
  con <- file(path, "rb"); on.exit(close(con), add = TRUE)
  raw <- readBin(con, "raw", n = 1048576L)
  newline <- match(as.raw(0x0a), raw, nomatch = 0L)
  if (!newline) stop("HEADER_SCHEMA: no newline in first MiB", call. = FALSE)
  raw <- raw[seq_len(newline - 1L)]
  if (length(raw) && identical(raw[[length(raw)]], as.raw(0x0d))) raw <- raw[-length(raw)]
  bom <- "none"
  if (length(raw) >= 3L && identical(raw[1:3], as.raw(c(0xef, 0xbb, 0xbf)))) {
    bom <- "UTF-8"; raw <- raw[-(1:3)]
  }
  header <- iconv(rawToChar(raw), from = encoding, to = "UTF-8", sub = NA_character_)
  if (is.na(header)) stop("HEADER_ENCODING: invalid configured encoding", call. = FALSE)
  if (is.null(delimiter)) {
    counts <- vapply(delimiter_candidates, function(d) lengths(regmatches(header, gregexpr(d, header, fixed = TRUE))), integer(1L))
    winners <- delimiter_candidates[counts == max(counts)]
    if (max(counts) < 1L || length(winners) != 1L) stop("HEADER_DELIMITER: absent or ambiguous", call. = FALSE)
    delimiter <- winners[[1L]]
  }
  fields <- strsplit(header, delimiter, fixed = TRUE)[[1L]]
  fields <- sub('^"|"$', "", fields)
  if (any(!nzchar(fields)) || anyDuplicated(fields)) stop("HEADER_FIELDS: blank or duplicate fields", call. = FALSE)
  data.table::data.table(delimiter = delimiter, encoding = encoding, bom = bom,
                         field_count = length(fields), source_fields = list(fields))
}

validate_source_field_map <- function(field_map, schemas) {
  assert_columns(field_map, c("dataset", "analysis_field", "source_field", "required"), "source field map")
  if (anyDuplicated(paste(field_map$dataset, field_map$analysis_field, sep = "\u001f"))) {
    stop("FIELD_MAP_KEY: dataset + analysis_field must be unique", call. = FALSE)
  }
  for (dataset in unique(field_map$dataset)) {
    if (is.null(schemas[[dataset]])) stop("FIELD_MAP_SCHEMA: missing schema for ", dataset, call. = FALSE)
    fields <- schemas[[dataset]]$source_fields[[1L]]
    required <- field_map[dataset == field_map$dataset & field_map$required, source_field]
    missing <- setdiff(required, fields)
    if (length(missing)) stop("FIELD_MAP_SCHEMA [", dataset, "]: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}

audit_ebd_sed_keys <- function(ebd, sed, ebd_key = "sampling_event_identifier",
                               sed_key = "sampling_event_identifier") {
  assert_join_cardinality(ebd, sed, stats::setNames(sed_key, ebd_key), "many-to-one", "EBD-to-SED checklist")
  ek <- as.character(ebd[[ebd_key]]); sk <- as.character(sed[[sed_key]])
  if (anyNA(ek) || anyNA(sk) || any(!nzchar(ek)) || any(!nzchar(sk))) {
    stop("EBIRD_JOIN_KEY: missing or blank key", call. = FALSE)
  }
  eu <- unique(ek); su <- unique(sk)
  data.table::data.table(
    relationship = "EBD-to-SED checklist",
    expected_cardinality = "many-to-one",
    ebd_rows = nrow(ebd), sed_rows = nrow(sed),
    ebd_unique_keys = length(eu), sed_unique_keys = length(su),
    ebd_keys_unmatched_to_sed = sum(!eu %in% su),
    sed_keys_without_ebd = sum(!su %in% eu),
    status = if (all(eu %in% su)) "PASS" else "FAIL"
  )
}

resolve_shared_checklists <- function(sed,
  comparison_fields = c("observation_date", "latitude", "longitude", "protocol_name",
                        "duration_minutes", "effort_distance_km", "number_observers",
                        "all_species_reported")) {
  assert_columns(sed, c("sampling_event_identifier", "group_identifier"), "shared checklist SED")
  source_id <- trimws(as.character(sed$sampling_event_identifier))
  if (anyNA(source_id) || any(!nzchar(source_id)) || anyDuplicated(source_id)) {
    stop("SHARED_CHECKLIST_KEY: source IDs must be complete and unique", call. = FALSE)
  }
  group_id <- trimws(as.character(sed$group_identifier)); group_id[!nzchar(group_id) | is.na(group_id)] <- NA_character_
  analysis_id <- ifelse(is.na(group_id), source_id, group_id)
  ord <- order(analysis_id, source_id, method = "radix")
  canonical <- setNames(source_id[ord][!duplicated(analysis_id[ord])], analysis_id[ord][!duplicated(analysis_id[ord])])
  canonical_id <- unname(canonical[analysis_id])
  keep <- source_id == canonical_id
  comparison_fields <- intersect(comparison_fields, names(sed))
  groups <- split(seq_len(nrow(sed)), analysis_id)
  audit <- data.table::rbindlist(lapply(names(groups), function(id) {
    idx <- groups[[id]]
    conflicts <- comparison_fields[vapply(comparison_fields, function(f) {
      length(unique(ifelse(is.na(sed[[f]][idx]), "<NA>", as.character(sed[[f]][idx])))) > 1L
    }, logical(1L))]
    data.table::data.table(group_member_count = length(idx),
      has_effort_disagreement = length(conflicts) > 0L,
      disagreement_fields = paste(conflicts, collapse = ";"))
  }))
  crosswalk <- data.table::data.table(
    source_sampling_event_identifier = source_id,
    analysis_checklist_id = analysis_id,
    canonical_sampling_event_identifier = canonical_id,
    canonical_effort_row = keep
  )
  if (nrow(crosswalk) != nrow(sed) || any(table(crosswalk$analysis_checklist_id, keep)[, "TRUE"] != 1L)) {
    stop("SHARED_CHECKLIST_QA: nondeterministic collapse", call. = FALSE)
  }
  list(canonical_rows = sed[keep, , drop = FALSE], private_crosswalk = crosswalk,
       aggregate_audit = audit[, .(analysis_checklists = .N,
         shared_analysis_checklists = sum(group_member_count > 1L),
         disagreement_groups = sum(has_effort_disagreement))])
}

parse_ebird_count_state <- function(x, ambiguous = FALSE) {
  raw <- trimws(as.character(x)); missing <- is.na(x) | !nzchar(raw)
  numeric_syntax <- !missing & grepl("^[0-9]+$", raw)
  lower_syntax <- !missing & grepl("^(>=|>|at least[[:space:]]+)?[0-9]+\\+?$", raw, ignore.case = TRUE) & !numeric_syntax
  lower <- rep(NA_real_, length(raw))
  lower[lower_syntax] <- as.numeric(gsub("[^0-9]", "", raw[lower_syntax]))
  numeric_count <- rep(NA_real_, length(raw)); numeric_count[numeric_syntax] <- as.numeric(raw[numeric_syntax])
  type <- rep("ambiguous", length(raw))
  type[missing] <- "missing"; type[toupper(raw) == "X" & !missing] <- "X"
  type[lower_syntax] <- "lower_bound"; type[numeric_syntax] <- "numeric"
  type[ambiguous & !missing] <- "ambiguous"
  data.table::data.table(
    detection = as.integer(!missing), numeric_count = numeric_count,
    lower_bound_count = lower, count_type = type,
    ambiguity_flag = as.logical(ambiguous), source_count = raw
  )
}

zero_fill_taxa <- function(checklists, detections, taxa) {
  assert_columns(checklists, "analysis_checklist_id", "eligible checklists")
  assert_columns(detections, c("analysis_checklist_id", "analysis_taxon_id", "detection",
                               "numeric_count", "lower_bound_count", "count_type", "ambiguity_flag"), "detections")
  assert_unique_key(checklists, "analysis_checklist_id", "eligible checklists")
  assert_unique_key(detections, c("analysis_checklist_id", "analysis_taxon_id"), "detections")
  grid <- data.table::CJ(analysis_checklist_id = as.character(checklists$analysis_checklist_id),
                         analysis_taxon_id = as.character(taxa), unique = TRUE)
  out <- merge(grid, detections, by = c("analysis_checklist_id", "analysis_taxon_id"),
               all.x = TRUE, sort = FALSE)
  out[is.na(detection), `:=`(detection = 0L, numeric_count = 0,
    lower_bound_count = 0, count_type = "zero_filled", ambiguity_flag = FALSE)]
  assert_unique_key(out, c("analysis_checklist_id", "analysis_taxon_id"), "zero-filled output")
  out
}

guild_count_bounds <- function(named_rows, ambiguous_rows = NULL) {
  assert_columns(named_rows, c("analysis_checklist_id", "guild_id", "numeric_count",
                               "lower_bound_count", "detection"), "named guild rows")
  named <- data.table::as.data.table(named_rows)[, .(
    guild_any_detection = as.integer(any(detection == 1L)),
    guild_richness = sum(detection == 1L),
    guild_count_lower = sum(ifelse(!is.na(numeric_count), numeric_count,
                           ifelse(!is.na(lower_bound_count), lower_bound_count, 0)))
  ), by = .(analysis_checklist_id, guild_id)]
  named[, guild_count_upper := guild_count_lower]
  if (!is.null(ambiguous_rows) && nrow(ambiguous_rows)) {
    assert_columns(ambiguous_rows, c("analysis_checklist_id", "possible_guild_ids", "lower_bound_count"), "ambiguous guild rows")
    eligible <- data.table::as.data.table(ambiguous_rows)[
      !is.na(possible_guild_ids) & !grepl(";", possible_guild_ids, fixed = TRUE)]
    extra <- eligible[, .(add = sum(lower_bound_count, na.rm = TRUE)),
                      by = .(analysis_checklist_id, guild_id = possible_guild_ids)]
    if (nrow(extra)) named[extra, on = .(analysis_checklist_id, guild_id), guild_count_upper := guild_count_upper + i.add]
  }
  named
}
