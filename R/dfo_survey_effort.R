dfo_monitoring_states <- function() {
  c("surveyed_positive", "surveyed_negative", "unmonitored_unknown")
}

validate_dfo_survey_effort <- function(x) {
  required <- c(
    "coverage_cell_id", "analysis_spatial_unit_id", "survey_window_start",
    "survey_window_end", "monitoring_state", "source_record_id",
    "survey_method", "survey_effort_value", "survey_effort_unit",
    "survey_completed", "spawn_search_performed", "spawn_detected",
    "coverage_fraction", "detection_limit_description", "quality_status",
    "source_release"
  )
  assert_columns(x, required, "DFO survey-effort coverage")
  x <- data.table::copy(data.table::as.data.table(x))
  for (field in c("coverage_cell_id", "analysis_spatial_unit_id", "monitoring_state",
                  "source_record_id", "survey_method", "survey_effort_unit",
                  "detection_limit_description", "quality_status", "source_release")) {
    x[, (field) := trimws(as.character(get(field)))]
  }
  if (anyNA(x$coverage_cell_id) || any(!nzchar(x$coverage_cell_id)) ||
      anyDuplicated(x$coverage_cell_id)) {
    stop("DFO_COVERAGE_KEY: coverage_cell_id must be complete and unique", call. = FALSE)
  }
  if (anyNA(x$analysis_spatial_unit_id) || any(!nzchar(x$analysis_spatial_unit_id))) {
    stop("DFO_SPATIAL_UNIT: generalized analysis spatial units are required", call. = FALSE)
  }
  x[, survey_window_start := as.Date(survey_window_start)]
  x[, survey_window_end := as.Date(survey_window_end)]
  if (anyNA(x$survey_window_start) || anyNA(x$survey_window_end) ||
      any(x$survey_window_end < x$survey_window_start)) {
    stop("DFO_SURVEY_WINDOW: complete ordered dates are required", call. = FALSE)
  }
  if (anyDuplicated(x[, .(analysis_spatial_unit_id, survey_window_start,
                          survey_window_end)])) {
    stop("DFO_COVERAGE_GRAIN: spatial unit by survey window must be unique", call. = FALSE)
  }
  if (any(!x$monitoring_state %in% dfo_monitoring_states())) {
    stop("DFO_MONITORING_STATE: invalid monitoring state", call. = FALSE)
  }
  effort <- suppressWarnings(as.numeric(x$survey_effort_value))
  coverage <- suppressWarnings(as.numeric(x$coverage_fraction))
  as_optional_binary <- function(value, field) {
    if (is.logical(value)) {
      return(value)
    }
    if (is.numeric(value) || is.integer(value)) {
      if (any(!is.na(value) & !value %in% c(0, 1))) {
        stop("DFO_BINARY_FIELD: ", field, " must be exactly 0 or 1", call. = FALSE)
      }
      return(ifelse(is.na(value), NA, value == 1))
    }
    value <- toupper(trimws(as.character(value)))
    value[!nzchar(value)] <- NA_character_
    if (any(!is.na(value) & !value %in% c("0", "1", "FALSE", "TRUE"))) {
      stop("DFO_BINARY_FIELD: ", field, " has an invalid value", call. = FALSE)
    }
    ifelse(is.na(value), NA, value %in% c("1", "TRUE"))
  }
  completed <- as_optional_binary(x$survey_completed, "survey_completed")
  searched <- as_optional_binary(x$spawn_search_performed, "spawn_search_performed")
  detected <- as_optional_binary(x$spawn_detected, "spawn_detected")
  surveyed <- x$monitoring_state %in% c("surveyed_positive", "surveyed_negative")
  if (any(surveyed & (is.na(x$source_record_id) | !nzchar(x$source_record_id))) ||
      any(surveyed & (is.na(x$survey_method) | !nzchar(x$survey_method))) ||
      any(surveyed & (is.na(x$survey_effort_unit) | !nzchar(x$survey_effort_unit))) ||
      any(surveyed & (!is.finite(effort) | effort <= 0)) ||
      any(surveyed & (!is.finite(coverage) | coverage <= 0 | coverage > 1)) ||
      any(surveyed & (is.na(x$detection_limit_description) |
                      !nzchar(x$detection_limit_description))) ||
      any(surveyed & (is.na(x$quality_status) | !nzchar(x$quality_status))) ||
      any(surveyed & (is.na(completed) | is.na(searched) | is.na(detected) |
                      !completed | !searched))) {
    stop("DFO_SURVEYED_EFFORT: surveyed cells require completed positive effort coverage search method quality and detection metadata",
         call. = FALSE)
  }
  if (any(x$monitoring_state == "surveyed_positive" & !is.na(detected) & !detected) ||
      any(x$monitoring_state == "surveyed_negative" & !is.na(detected) & detected)) {
    stop("DFO_STATE_CONSISTENCY: monitoring state conflicts with spawn_detected", call. = FALSE)
  }
  unmonitored_has_record <- !surveyed & !is.na(x$source_record_id) & nzchar(x$source_record_id)
  unmonitored_has_survey_state <- !surveyed &
    (!is.na(completed) | !is.na(searched) | !is.na(detected))
  if (any(unmonitored_has_record) || any(unmonitored_has_survey_state)) {
    stop("DFO_UNMONITORED_IDENTITY: unmonitored cells cannot fabricate source records",
         call. = FALSE)
  }
  if (anyNA(x$source_release) || any(!nzchar(x$source_release))) {
    stop("DFO_SOURCE_RELEASE: every coverage cell requires a versioned source release",
         call. = FALSE)
  }
  x[, survey_effort_value := effort]
  x[, coverage_fraction := coverage]
  x[, `:=`(survey_completed = completed, spawn_search_performed = searched,
           spawn_detected = detected)]
  list(
    data = x,
    summary = x[, .(coverage_cells = .N), by = monitoring_state][
      match(dfo_monitoring_states(), monitoring_state), ]
  )
}
