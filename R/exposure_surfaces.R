assign_distance_ring <- function(distance_km, breaks = c(0, 0.5, 1, 2, 3, 4, 5, 10, 20)) {
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
  required <- c("analysis_checklist_id", "source_record_id", "event_distance_km", "event_day")
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
    contributing_events = data.table::uniqueN(source_record_id[spatial_weight * temporal_weight > 0])
  ), by = analysis_checklist_id]
}

event_window_membership <- function(candidate_links, rules) {
  assert_columns(candidate_links,
                 c("analysis_checklist_id", "source_record_id", "event_distance_km", "event_day"),
                 "candidate links")
  required_rules <- c("window_id", "max_distance_km", "pre_days", "post_days")
  assert_columns(rules, required_rules, "event-window rules")
  if (anyDuplicated(rules$window_id)) stop("window_id must be unique", call. = FALSE)

  out <- lapply(seq_len(nrow(rules)), function(i) {
    rule <- rules[i, ]
    hit <- candidate_links$event_distance_km <= rule$max_distance_km &
      candidate_links$event_day >= -rule$pre_days &
      candidate_links$event_day <= rule$post_days
    data.table::data.table(
      analysis_checklist_id = candidate_links$analysis_checklist_id[hit],
      source_record_id = candidate_links$source_record_id[hit],
      window_id = rule$window_id
    )
  })
  data.table::rbindlist(out, use.names = TRUE, fill = TRUE)
}

summarise_event_membership <- function(membership) {
  assert_columns(membership,
                 c("analysis_checklist_id", "source_record_id", "window_id"),
                 "event membership")
  membership[, .(
    event_count = data.table::uniqueN(source_record_id),
    source_record_ids = paste(sort(unique(source_record_id)), collapse = "|")
  ), by = c("analysis_checklist_id", "window_id")]
}

kernel_truncation_audit <- function(candidate_links, production_radius_km,
                                    wider_radius_km, scale_km, duration_days,
                                    exposure_tolerance, intensity_col = NULL,
                                    spatial = "exponential",
                                    temporal = "exponential_decay") {
  required <- c("analysis_checklist_id", "source_record_id",
                "event_distance_km", "event_day")
  assert_columns(candidate_links, required, "kernel truncation links")
  if (length(production_radius_km) != 1L || !is.finite(production_radius_km) ||
      production_radius_km <= 0 || length(wider_radius_km) != 1L ||
      !is.finite(wider_radius_km) || wider_radius_km <= production_radius_km) {
    stop("KERNEL_TRUNCATION_RADIUS: wider radius must be finite and exceed production radius",
         call. = FALSE)
  }
  if (length(exposure_tolerance) != 1L || !is.finite(exposure_tolerance) ||
      exposure_tolerance < 0 || exposure_tolerance >= 1) {
    stop("KERNEL_TRUNCATION_TOLERANCE: tolerance must be in [0, 1)", call. = FALSE)
  }
  x <- data.table::copy(data.table::as.data.table(candidate_links))
  x[, analysis_checklist_id := trimws(as.character(analysis_checklist_id))]
  x[, source_record_id := trimws(as.character(source_record_id))]
  if (anyNA(x$analysis_checklist_id) || any(!nzchar(x$analysis_checklist_id)) ||
      anyNA(x$source_record_id) || any(!nzchar(x$source_record_id)) ||
      anyDuplicated(x[, .(analysis_checklist_id, source_record_id)])) {
    stop("KERNEL_TRUNCATION_IDENTITY: link pairs must be complete and unique", call. = FALSE)
  }
  if (any(!is.finite(x$event_distance_km)) || any(x$event_distance_km < 0) ||
      any(x$event_distance_km > wider_radius_km + 1e-7)) {
    stop("KERNEL_TRUNCATION_DISTANCE: links must be finite and bounded by wider radius",
         call. = FALSE)
  }
  x[, spatial_weight := spatial_kernel(event_distance_km, scale_km, spatial)]
  x[, temporal_weight := temporal_kernel(event_day, duration_days, shape = temporal)]
  if (is.null(intensity_col)) {
    x[, event_weight := 1]
  } else {
    assert_columns(x, intensity_col, "kernel truncation links")
    intensity <- suppressWarnings(as.numeric(x[[intensity_col]]))
    if (any(!is.finite(intensity)) || any(intensity < 0)) {
      stop("KERNEL_TRUNCATION_INTENSITY: intensity must be finite and nonnegative",
           call. = FALSE)
    }
    x[, event_weight := log1p(intensity)]
  }
  x[, weighted_exposure := spatial_weight * temporal_weight * event_weight]
  out <- x[, .(
    production_radius_exposure = sum(weighted_exposure[event_distance_km <= production_radius_km]),
    wider_radius_exposure = sum(weighted_exposure),
    omitted_exposure = sum(weighted_exposure[event_distance_km > production_radius_km]),
    omitted_contributing_events = data.table::uniqueN(
      source_record_id[event_distance_km > production_radius_km & weighted_exposure > 0])
  ), by = analysis_checklist_id]
  out[, relative_omission := ifelse(wider_radius_exposure > 0,
    omitted_exposure / wider_radius_exposure, 0)]
  out[, `:=`(
    exposure_tolerance = exposure_tolerance,
    truncation_status = ifelse(relative_omission <= exposure_tolerance, "PASS", "FAIL")
  )]
  out[]
}
