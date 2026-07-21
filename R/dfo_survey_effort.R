dfo_monitoring_states <- function() {
  c("surveyed_positive", "surveyed_negative", "unmonitored_unknown")
}

validate_dfo_survey_effort <- function(x) {
  required <- c(
    "coverage_cell_id", "analysis_spatial_unit_id", "section_id", "location_id",
    "stock_assessment_region", "survey_window_start", "survey_window_end",
    "monitoring_state", "source_record_id", "survey_event_id", "survey_date",
    "survey_start_time", "survey_end_time", "searched_geometry_reference",
    "survey_method", "survey_effort_value", "survey_effort_unit",
    "searched_extent_value", "searched_extent_unit",
    "survey_completed", "spawn_search_performed", "spawn_detected",
    "coverage_fraction", "detection_limit_description", "quality_status",
    "confidence_status", "incomplete_coverage_reason", "positive_spawn_evidence",
    "negative_survey_evidence", "provenance_source", "source_release",
    "provenance_revision_id", "provenance_revision_timestamp"
  )
  assert_columns(x, required, "DFO survey-effort coverage")
  x <- data.table::copy(data.table::as.data.table(x))
  text_fields <- c("coverage_cell_id", "analysis_spatial_unit_id", "section_id",
    "location_id", "stock_assessment_region", "monitoring_state", "source_record_id",
    "survey_event_id", "survey_start_time", "survey_end_time",
    "searched_geometry_reference", "survey_method", "survey_effort_unit",
    "searched_extent_unit", "detection_limit_description", "quality_status",
    "confidence_status", "incomplete_coverage_reason", "positive_spawn_evidence",
    "negative_survey_evidence", "provenance_source", "source_release",
    "provenance_revision_id", "provenance_revision_timestamp")
  for (field in text_fields) {
    x[, (field) := trimws(as.character(get(field)))]
    x[is.na(get(field)), (field) := ""]
  }
  if (anyNA(x$coverage_cell_id) || any(!nzchar(x$coverage_cell_id)) ||
      anyDuplicated(x$coverage_cell_id)) {
    stop("DFO_COVERAGE_KEY: coverage_cell_id must be complete and unique", call. = FALSE)
  }
  if (anyNA(x$analysis_spatial_unit_id) || any(!nzchar(x$analysis_spatial_unit_id))) {
    stop("DFO_SPATIAL_UNIT: generalized analysis spatial units are required", call. = FALSE)
  }
  for (field in c("section_id", "location_id", "stock_assessment_region",
                  "provenance_source", "source_release", "provenance_revision_id",
                  "provenance_revision_timestamp")) {
    if (anyNA(x[[field]]) || any(!nzchar(x[[field]]))) {
      stop("DFO_PROVENANCE_AND_LOCATION: complete section location region and revision provenance are required",
           call. = FALSE)
    }
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
  extent <- suppressWarnings(as.numeric(x$searched_extent_value))
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
  event_present <- nzchar(x$survey_event_id) | nzchar(x$source_record_id)
  x[, survey_date := as.Date(survey_date)]
  valid_time <- function(value) !nzchar(value) | grepl("^([01][0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$", value)
  if (any(event_present & is.na(x$survey_date)) ||
      any(!valid_time(x$survey_start_time)) || any(!valid_time(x$survey_end_time))) {
    stop("DFO_EVENT_TIME: event records require a date and optional times must be HH:MM or HH:MM:SS",
         call. = FALSE)
  }
  if (any(surveyed & (is.na(x$source_record_id) | !nzchar(x$source_record_id))) ||
      any(surveyed & !nzchar(x$survey_event_id)) ||
      any(surveyed & !nzchar(x$searched_geometry_reference)) ||
      any(surveyed & (is.na(x$survey_method) | !nzchar(x$survey_method))) ||
      any(surveyed & (is.na(x$survey_effort_unit) | !nzchar(x$survey_effort_unit))) ||
      any(surveyed & !nzchar(x$searched_extent_unit)) ||
      any(surveyed & (!is.finite(effort) | effort <= 0)) ||
      any(surveyed & (!is.finite(extent) | extent <= 0)) ||
      any(surveyed & (!is.finite(coverage) | coverage <= 0 | coverage > 1)) ||
      any(surveyed & (is.na(x$detection_limit_description) |
                      !nzchar(x$detection_limit_description))) ||
      any(surveyed & (!nzchar(x$quality_status) | !nzchar(x$confidence_status))) ||
      any(surveyed & (is.na(completed) | is.na(searched) | is.na(detected) |
                      !completed | !searched))) {
    stop("DFO_SURVEYED_EFFORT: surveyed cells require completed positive effort coverage search method quality and detection metadata",
         call. = FALSE)
  }
  if (any(x$monitoring_state == "surveyed_positive" & !is.na(detected) & !detected) ||
      any(x$monitoring_state == "surveyed_negative" & !is.na(detected) & detected)) {
    stop("DFO_STATE_CONSISTENCY: monitoring state conflicts with spawn_detected", call. = FALSE)
  }
  positive <- x$monitoring_state == "surveyed_positive"
  negative <- x$monitoring_state == "surveyed_negative"
  if (any(positive & (!nzchar(x$positive_spawn_evidence) | nzchar(x$negative_survey_evidence))) ||
      any(negative & (!nzchar(x$negative_survey_evidence) | nzchar(x$positive_spawn_evidence))) ||
      any(!surveyed & (nzchar(x$positive_spawn_evidence) | nzchar(x$negative_survey_evidence)))) {
    stop("DFO_EVIDENCE_STATE: positive and explicit negative evidence must be mutually exclusive and match monitoring state",
         call. = FALSE)
  }
  incomplete <- !surveyed
  incomplete_event <- incomplete & event_present
  if (any(incomplete & !is.na(detected)) || any(incomplete & !is.na(completed) & completed) ||
      any(incomplete_event & !nzchar(x$incomplete_coverage_reason))) {
    stop("DFO_UNMONITORED_IDENTITY: unknown coverage cannot carry a detection or completed-survey claim and incomplete events require a reason",
         call. = FALSE)
  }
  orphan_identity <- xor(nzchar(x$survey_event_id), nzchar(x$source_record_id))
  if (any(orphan_identity)) {
    stop("DFO_EVENT_IDENTITY: survey_event_id and source_record_id must be jointly present or absent",
         call. = FALSE)
  }
  x[, survey_effort_value := effort]
  x[, searched_extent_value := extent]
  x[, coverage_fraction := coverage]
  x[, `:=`(survey_completed = completed, spawn_search_performed = searched,
           spawn_detected = detected)]
  list(
    data = x,
    summary = x[, .(coverage_cells = .N), by = monitoring_state][
      match(dfo_monitoring_states(), monitoring_state), ]
  )
}
