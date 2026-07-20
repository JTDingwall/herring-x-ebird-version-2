assign_distance_ring <- function(distance_km, breaks = c(0, 1, 2, 3, 4, 5, 10, 25, 50)) {
  if (any(diff(breaks) <= 0)) stop("Distance breaks must be strictly increasing", call. = FALSE)
  cut(distance_km, breaks = breaks, right = FALSE, include.lowest = TRUE,
      labels = paste0(head(breaks, -1), "-", tail(breaks, -1), "km"))
}

assign_event_time_bin <- function(event_day, bins) {
  out <- rep(NA_character_, length(event_day))
  for (nm in names(bins)) {
    bounds <- unlist(bins[[nm]])
    hit <- !is.na(event_day) & event_day >= bounds[[1]] & event_day <= bounds[[2]]
    if (any(hit & !is.na(out))) stop("Event-time bins overlap", call. = FALSE)
    out[hit] <- nm
  }
  factor(out, levels = names(bins))
}

spatial_kernel <- function(distance_km, scale_km, kernel = c("exponential", "gaussian")) {
  kernel <- match.arg(kernel)
  if (scale_km <= 0) stop("scale_km must be positive", call. = FALSE)
  ifelse(
    is.na(distance_km), NA_real_,
    if (kernel == "exponential") exp(-distance_km / scale_km) else exp(-0.5 * (distance_km / scale_km)^2)
  )
}

temporal_kernel <- function(event_day, duration_days, pre_days = 0, shape = c("boxcar", "exponential_decay", "triangular")) {
  shape <- match.arg(shape)
  if (duration_days <= 0) stop("duration_days must be positive", call. = FALSE)
  x <- rep(0, length(event_day))
  valid <- !is.na(event_day) & event_day >= -pre_days
  if (shape == "boxcar") {
    x[valid & event_day <= duration_days] <- 1
  } else if (shape == "exponential_decay") {
    x[valid] <- exp(-pmax(event_day[valid], 0) / duration_days)
  } else {
    x[valid & event_day <= duration_days] <- pmax(0, 1 - pmax(event_day[valid & event_day <= duration_days], 0) / duration_days)
  }
  x
}

additive_spawn_exposure <- function(candidate_links, scale_km, duration_days,
                                    intensity_col = NULL,
                                    spatial = "exponential",
                                    temporal = "exponential_decay") {
  required <- c("sampling_event_identifier", "event_distance_km", "event_day")
  assert_columns(candidate_links, required, "candidate links")
  x <- data.table::copy(candidate_links)
  x[, spatial_weight := spatial_kernel(event_distance_km, scale_km, spatial)]
  x[, temporal_weight := temporal_kernel(event_day, duration_days, shape = temporal)]
  if (is.null(intensity_col)) {
    x[, event_weight := 1]
  } else {
    assert_columns(x, intensity_col, "candidate links")
    x[, event_weight := log1p(pmax(get(intensity_col), 0))]
  }
  x[, .(
    additive_exposure = sum(spatial_weight * temporal_weight * event_weight, na.rm = TRUE),
    contributing_events = sum(spatial_weight * temporal_weight > 0, na.rm = TRUE)
  ), by = sampling_event_identifier]
}
