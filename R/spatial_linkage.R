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

candidate_event_links <- function(checklists, events, max_distance_km = 20,
                                  checklist_id_col = NULL, event_id_col = NULL,
                                  expected_max_scale_km = NULL,
                                  truncation_weight_tolerance = 0.01) {
  # This link is many-to-many by design: a checklist links to every event within the
  # radius. Downstream aggregation must join on the stable ids carried here, never on
  # row position. Pass checklist_id_col/event_id_col to attach them.
  if (!is.null(expected_max_scale_km)) {
    residual_weight <- exp(-max_distance_km / expected_max_scale_km)
    if (residual_weight > truncation_weight_tolerance) {
      warning(sprintf(
        "CANDIDATE_RADIUS_TRUNCATION: radius %.3g km leaves kernel weight %.3g at the cutoff for scale %.3g km (> tolerance %.3g); widen max_distance_km",
        max_distance_km, residual_weight, expected_max_scale_km, truncation_weight_tolerance),
        call. = FALSE)
    }
  }
  id_of <- function(obj, id_col) if (is.null(id_col)) NULL else as.character(obj[[id_col]])
  checklist_ids <- id_of(checklists, checklist_id_col)
  event_ids <- id_of(events, event_id_col)
  checklists <- transform_for_linkage(checklists)
  events <- transform_for_linkage(events)
  assert_metric_crs(checklists)
  idx <- sf::st_is_within_distance(checklists, events, dist = max_distance_km * 1000)
  rows <- lapply(seq_along(idx), function(i) {
    if (!length(idx[[i]])) return(NULL)
    distances <- as.numeric(sf::st_distance(checklists[i, ], events[idx[[i]], ], by_element = FALSE)[1, ]) / 1000
    data.table::data.table(checklist_row = i, event_row = idx[[i]], event_distance_km = distances)
  })
  res <- data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
  if (nrow(res)) {
    if (!is.null(checklist_ids)) res[, sampling_event_identifier := checklist_ids[checklist_row]]
    if (!is.null(event_ids)) res[, event_id := event_ids[event_row]]
  }
  res
}

construct_alongshore_segment <- function(line_coordinates, point_xy, length_m) {
  xy <- as.matrix(line_coordinates)[, 1:2, drop = FALSE]
  point_xy <- as.numeric(point_xy)[1:2]
  if (nrow(xy) < 2L || any(!is.finite(xy)) || any(!is.finite(point_xy)) ||
      length(length_m) != 1L || !is.finite(length_m) || length_m <= 0) {
    return(list(status = "invalid_geometry_or_length", coordinates = NULL,
                requested_length_m = length_m, constructed_length_m = NA_real_))
  }
  delta <- xy[-1L, , drop = FALSE] - xy[-nrow(xy), , drop = FALSE]
  segment_length <- sqrt(rowSums(delta^2))
  usable <- which(segment_length > 0)
  if (!length(usable)) {
    return(list(status = "zero_length_shoreline_feature", coordinates = NULL,
                requested_length_m = length_m, constructed_length_m = NA_real_))
  }
  starts <- xy[usable, , drop = FALSE]
  vectors <- delta[usable, , drop = FALSE]
  lengths <- segment_length[usable]
  cumulative_start <- cumsum(c(0, head(lengths, -1L)))
  rel <- sweep(starts, 2L, point_xy, "-")
  projection_fraction <- -rowSums(rel * vectors) / (lengths^2)
  projection_fraction <- pmin(1, pmax(0, projection_fraction))
  projected <- starts + vectors * projection_fraction
  nearest <- which.min(rowSums(sweep(projected, 2L, point_xy, "-")^2))
  centre_distance <- cumulative_start[nearest] + projection_fraction[nearest] * lengths[nearest]
  total_length <- sum(lengths)
  if (total_length + 1e-8 < length_m) {
    return(list(status = "shoreline_feature_shorter_than_requested_length", coordinates = NULL,
                requested_length_m = length_m, constructed_length_m = NA_real_))
  }
  start_distance <- min(max(centre_distance - length_m / 2, 0), total_length - length_m)
  end_distance <- start_distance + length_m
  point_at_distance <- function(distance) {
    i <- max(which(cumulative_start <= distance + 1e-8))
    i <- min(i, length(lengths))
    fraction <- min(1, max(0, (distance - cumulative_start[i]) / lengths[i]))
    starts[i, ] + fraction * vectors[i, ]
  }
  start_xy <- point_at_distance(start_distance)
  end_xy <- point_at_distance(end_distance)
  vertex_distance <- cumulative_start + lengths
  internal <- which(vertex_distance > start_distance + 1e-8 & vertex_distance < end_distance - 1e-8)
  internal_xy <- if (length(internal)) starts[internal, , drop = FALSE] + vectors[internal, , drop = FALSE] else matrix(numeric(), ncol = 2L)
  segment_xy <- rbind(start_xy, internal_xy, end_xy)
  segment_xy <- segment_xy[c(TRUE, rowSums(abs(segment_xy[-1L, , drop = FALSE] - segment_xy[-nrow(segment_xy), , drop = FALSE])) > 1e-8), , drop = FALSE]
  constructed <- sum(sqrt(rowSums((segment_xy[-1L, , drop = FALSE] - segment_xy[-nrow(segment_xy), , drop = FALSE])^2)))
  list(status = "constructed", coordinates = segment_xy,
       requested_length_m = length_m, constructed_length_m = constructed)
}
