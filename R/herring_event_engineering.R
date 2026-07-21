required_herring_source_fields <- function() {
  c(
    "Region", "Year", "StatisticalArea", "Section", "LocationCode",
    "LocationName", "SpawnNumber", "StartDate", "EndDate", "Longitude",
    "Latitude", "Length", "Width", "Method", "Surface", "Macrocystis",
    "Understory"
  )
}

validate_herring_schema <- function(x, field_map = NULL) {
  if (!is.null(field_map)) {
    missing_names <- setdiff(required_herring_source_fields(), names(field_map))
    if (length(missing_names)) {
      stop("Herring field map is incomplete: ", paste(missing_names, collapse = ", "), call. = FALSE)
    }
    source_fields <- unname(unlist(field_map[required_herring_source_fields()]))
  } else {
    source_fields <- required_herring_source_fields()
  }
  assert_columns(x, source_fields, "herring source")
  invisible(TRUE)
}

stable_event_id <- function(year, location_code, section, spawn_number) {
  key <- paste(year, location_code, section, spawn_number, sep = "::")
  paste0("evt_", substr(vapply(key, digest::digest, character(1),
                              algo = "sha256", serialize = FALSE), 1, 16))
}

stable_source_record_id <- function(x, source_sha256) {
  validate_herring_schema(x)
  canonical <- apply(as.data.frame(x)[required_herring_source_fields()], 1L, function(z) {
    paste(ifelse(is.na(z), "<NA>", z), collapse = "\u001f")
  })
  paste0("hsr_", substr(vapply(seq_len(nrow(x)), function(i) {
    digest::digest(paste(source_sha256, i, canonical[[i]], sep = "\u001e"),
                   algo = "sha256", serialize = FALSE)
  }, character(1L)), 1L, 20L))
}

representative_event_date <- function(start_date, end_date) {
  start_date <- as.Date(start_date)
  end_date <- as.Date(end_date)
  as.Date(ifelse(
    !is.na(start_date) & !is.na(end_date),
    floor((as.numeric(start_date) + as.numeric(end_date)) / 2),
    ifelse(!is.na(start_date), as.numeric(start_date), as.numeric(end_date))
  ), origin = "1970-01-01")
}

classify_herring_quality <- function(start_date, end_date, length_m, width_m,
                                     intensity_index, assessment_method,
                                     geometry_present = TRUE) {
  # `intensity_index` carries the relative spawn index (an extent/component-based
  # intensity), not a physical egg-thickness measurement; it was previously
  # mis-named `egg_thickness`.
  has_date <- !is.na(start_date) | !is.na(end_date)
  has_intensity_component <- !is.na(length_m) | !is.na(width_m) | !is.na(intensity_index)
  method_known <- !is.na(assessment_method) & nzchar(trimws(assessment_method))
  tier <- ifelse(has_date & geometry_present & has_intensity_component & method_known, "high",
          ifelse(has_date & geometry_present, "moderate", "limited"))
  factor(tier, levels = c("high", "moderate", "limited"))
}

derive_herring_event_fields <- function(x, field_map = NULL,
                                        require_unique_event_id = FALSE) {
  validate_herring_schema(x, field_map)
  col <- function(nm) if (is.null(field_map)) nm else unname(field_map[[nm]])
  out <- data.table::copy(data.table::as.data.table(x))
  out[, event_id := stable_event_id(get(col("Year")), get(col("LocationCode")),
                                    get(col("Section")), get(col("SpawnNumber")))]
  # Opt-in guard: the event_id natural key (Year::LocationCode::Section::SpawnNumber)
  # silently collides duplicate/re-surveyed rows into one event. Enable this once the
  # source table is confirmed to be one row per event so the collision fails loud.
  if (require_unique_event_id && anyDuplicated(out$event_id) > 0L) {
    stop("EVENT_ID_UNIQUENESS: duplicate event_id natural keys; ",
         "one row per event is required when require_unique_event_id = TRUE",
         call. = FALSE)
  }
  out[, event_date := representative_event_date(get(col("StartDate")), get(col("EndDate")))]
  out[, component_surface_missing := is.na(get(col("Surface")))]
  out[, component_macrocystis_missing := is.na(get(col("Macrocystis")))]
  out[, component_understory_missing := is.na(get(col("Understory")))]
  out[, intensity_missing := component_surface_missing & component_macrocystis_missing &
        component_understory_missing]
  out[, relative_spawn_index := {
    z <- cbind(get(col("Surface")), get(col("Macrocystis")), get(col("Understory")))
    ans <- rowSums(z, na.rm = TRUE)
    ans[rowSums(!is.na(z)) == 0L] <- NA_real_
    ans
  }]
  out[, event_quality_tier := classify_herring_quality(
    get(col("StartDate")), get(col("EndDate")),
    get(col("Length")), get(col("Width")),
    relative_spawn_index, get(col("Method")),
    !is.na(get(col("Latitude"))) & !is.na(get(col("Longitude")))
  )]
  out
}

event_complex_components <- function(candidate_pairs) {
  assert_columns(candidate_pairs, c("event_id_a", "event_id_b", "linked"), "event pairs")
  ids <- sort(unique(c(candidate_pairs$event_id_a, candidate_pairs$event_id_b)))
  parent <- stats::setNames(ids, ids)
  root <- function(x) {
    while (parent[[x]] != x) x <- parent[[x]]
    x
  }
  for (i in which(candidate_pairs$linked %in% TRUE)) {
    a <- root(candidate_pairs$event_id_a[[i]])
    b <- root(candidate_pairs$event_id_b[[i]])
    if (a != b) parent[[b]] <- a
  }
  roots <- vapply(ids, root, character(1))
  groups <- match(roots, unique(roots))
  data.table::data.table(event_id = ids, event_complex_id = sprintf("complex_%05d", groups))
}

anti_chain_event_complexes <- function(events, maximum_temporal_span_days = 21,
                                       maximum_spatial_bbox_diameter_km = 25) {
  required <- c("original_complex_id", "source_record_id", "event_date", "x_m", "y_m", "region")
  assert_columns(events, required, "event-complex anti-chaining input")
  x <- data.table::copy(data.table::as.data.table(events))
  if (anyDuplicated(x$source_record_id)) {
    stop("EVENT_COMPLEX_ANTI_CHAIN: source records must be unique", call. = FALSE)
  }
  data.table::setorder(x, original_complex_id, event_date, source_record_id, na.last = TRUE)
  assigned <- integer(nrow(x))
  for (original in unique(x$original_complex_id)) {
    rows <- which(x$original_complex_id == original)
    clusters <- list()
    for (row in rows) {
      selected <- NA_integer_
      for (cluster_index in seq_along(clusters)) {
        candidate <- c(clusters[[cluster_index]], row)
        dates <- as.Date(x$event_date[candidate])
        temporal_span <- if (anyNA(dates)) Inf else as.numeric(max(dates) - min(dates))
        xx <- x$x_m[candidate]; yy <- x$y_m[candidate]
        spatial_span <- if (any(!is.finite(xx)) || any(!is.finite(yy))) Inf else
          sqrt(diff(range(xx))^2 + diff(range(yy))^2) / 1000
        same_region <- data.table::uniqueN(x$region[candidate], na.rm = FALSE) == 1L
        if (same_region && temporal_span <= maximum_temporal_span_days &&
            spatial_span <= maximum_spatial_bbox_diameter_km) {
          selected <- cluster_index
          break
        }
      }
      if (is.na(selected)) {
        clusters[[length(clusters) + 1L]] <- row
        selected <- length(clusters)
      } else {
        clusters[[selected]] <- c(clusters[[selected]], row)
      }
      assigned[row] <- selected
    }
  }
  x[, anti_chain_sequence := assigned]
  x[, anti_chain_complex_id := paste0(
    "ac2_", substr(vapply(paste(original_complex_id, anti_chain_sequence, sep = "|"),
      digest::digest, character(1L), algo = "sha256", serialize = FALSE), 1L, 16L)
  )]
  x[, .(source_record_id, original_complex_id, anti_chain_complex_id, anti_chain_sequence)]
}
