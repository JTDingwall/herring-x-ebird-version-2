assert_metric_crs <- function(x) {
  if (!requireNamespace("sf", quietly = TRUE)) stop("Package 'sf' is required", call. = FALSE)
  crs <- sf::st_crs(x)
  if (is.na(crs)) stop("Spatial object has no CRS", call. = FALSE)
  if (isTRUE(sf::st_is_longlat(x))) stop("Distance operations require a projected CRS", call. = FALSE)
  units <- tolower(crs$units_gdal %||% "")
  if (!units %in% c("metre", "meter", "metres", "meters", "m")) {
    stop("Projected CRS must use metre units", call. = FALSE)
  }
  invisible(TRUE)
}

transform_for_linkage <- function(x, epsg = 3005L) {
  if (!requireNamespace("sf", quietly = TRUE)) stop("Package 'sf' is required", call. = FALSE)
  if (is.na(sf::st_crs(x))) stop("Cannot transform geometry without a declared source CRS", call. = FALSE)
  sf::st_transform(x, epsg)
}

candidate_event_links <- function(checklists, events, max_distance_km = 20) {
  checklists <- transform_for_linkage(checklists)
  events <- transform_for_linkage(events)
  assert_metric_crs(checklists)
  idx <- sf::st_is_within_distance(checklists, events, dist = max_distance_km * 1000)
  rows <- lapply(seq_along(idx), function(i) {
    if (!length(idx[[i]])) return(NULL)
    distances <- as.numeric(sf::st_distance(checklists[i, ], events[idx[[i]], ], by_element = FALSE)[1, ]) / 1000
    data.table::data.table(checklist_row = i, event_row = idx[[i]], event_distance_km = distances)
  })
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}
