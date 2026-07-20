core_detection_formula <- function(response = "detection", include_kernel = FALSE) {
  exposure <- if (include_kernel) "s(additive_exposure, k = 6)" else "te(event_day, log1p_event_distance_km, k = c(8, 6))"
  stats::as.formula(paste(
    response, "~", exposure,
    "+ s(calendar_day, bs = 'cc', k = 12)",
    "+ log_duration + log1p_effort_distance + number_observers",
    "+ log1p_prior_observer_checklists + minutes_from_sunrise + protocol",
    "+ factor(year) + s(event_id, bs = 're') + s(observer_id, bs = 're') + s(location_id, bs = 're')"
  ))
}
