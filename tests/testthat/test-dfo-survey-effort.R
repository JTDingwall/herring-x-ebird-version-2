test_that("DFO coverage validator distinguishes positive negative and unknown", {
  x <- data.table(
    coverage_cell_id = c("cell_a", "cell_b", "cell_c"),
    analysis_spatial_unit_id = c("unit_a", "unit_b", "unit_c"),
    section_id = c("section_a", "section_b", "section_c"),
    location_id = c("location_a", "location_b", "location_c"),
    stock_assessment_region = c("SoG", "SoG", "SoG"),
    survey_window_start = as.Date(c("2025-03-01", "2025-03-01", "2025-03-01")),
    survey_window_end = as.Date(c("2025-03-07", "2025-03-07", "2025-03-07")),
    monitoring_state = dfo_monitoring_states(),
    source_record_id = c("record_a", "record_b", ""),
    survey_event_id = c("event_a", "event_b", ""),
    survey_date = as.Date(c("2025-03-02", "2025-03-03", NA)),
    survey_start_time = c("08:00", "09:00:00", ""),
    survey_end_time = c("10:00", "11:00:00", ""),
    searched_geometry_reference = c("secure_geom_a_v1", "secure_geom_b_v1", ""),
    survey_method = c("method_a", "method_a", ""),
    survey_effort_value = c(2, 2, NA),
    survey_effort_unit = c("survey_hours", "survey_hours", ""),
    searched_extent_value = c(4, 5, NA),
    searched_extent_unit = c("shoreline_km", "shoreline_km", ""),
    survey_completed = c(TRUE, TRUE, NA),
    spawn_search_performed = c(TRUE, TRUE, NA),
    spawn_detected = c(TRUE, FALSE, NA),
    coverage_fraction = c(0.8, 0.9, NA),
    detection_limit_description = c("visible spawn", "no spawn at method threshold", ""),
    quality_status = c("complete", "complete", "unknown"),
    confidence_status = c("high", "high", "unknown"),
    incomplete_coverage_reason = c("", "", "no survey record in delivery"),
    positive_spawn_evidence = c("spawn_observation_a", "", ""),
    negative_survey_evidence = c("", "completed_search_no_spawn_b", ""),
    provenance_source = "synthetic_fixture_only",
    source_release = "synthetic_fixture_v1",
    provenance_revision_id = "revision_1",
    provenance_revision_timestamp = "2025-04-01T00:00:00Z"
  )
  got <- validate_dfo_survey_effort(x)
  expect_setequal(got$summary$monitoring_state, dfo_monitoring_states())
  expect_equal(sum(got$summary$coverage_cells), 3L)
})

test_that("DFO coverage validator rejects fabricated negatives and broken grain", {
  base <- data.table(
    coverage_cell_id = "cell_a", analysis_spatial_unit_id = "unit_a",
    section_id = "section_a", location_id = "location_a",
    stock_assessment_region = "SoG",
    survey_window_start = as.Date("2025-03-01"),
    survey_window_end = as.Date("2025-03-07"),
    monitoring_state = "surveyed_negative", source_record_id = "record_a",
    survey_event_id = "event_a", survey_date = as.Date("2025-03-02"),
    survey_start_time = "08:00", survey_end_time = "10:00",
    searched_geometry_reference = "secure_geom_a_v1",
    survey_method = "method_a", survey_effort_value = 2,
    survey_effort_unit = "survey_hours", searched_extent_value = 4,
    searched_extent_unit = "shoreline_km", survey_completed = TRUE,
    spawn_search_performed = TRUE, spawn_detected = FALSE,
    coverage_fraction = 0.9,
    detection_limit_description = "no spawn at method threshold",
    quality_status = "complete", confidence_status = "high",
    incomplete_coverage_reason = "", positive_spawn_evidence = "",
    negative_survey_evidence = "completed_search_no_spawn_a",
    provenance_source = "synthetic_fixture_only", source_release = "synthetic_fixture_v1",
    provenance_revision_id = "revision_1",
    provenance_revision_timestamp = "2025-04-01T00:00:00Z"
  )
  missing_effort <- copy(base)
  missing_effort[, survey_effort_value := NA_real_]
  expect_error(validate_dfo_survey_effort(missing_effort), "DFO_SURVEYED_EFFORT")
  contradictory <- copy(base)
  contradictory[, spawn_detected := TRUE]
  expect_error(validate_dfo_survey_effort(contradictory), "DFO_STATE_CONSISTENCY")
  fabricated <- copy(base)
  fabricated[, `:=`(monitoring_state = "unmonitored_unknown",
                    spawn_detected = NA, survey_completed = FALSE,
                    negative_survey_evidence = "")]
  expect_error(validate_dfo_survey_effort(fabricated), "DFO_UNMONITORED_IDENTITY")
  imputed_unknown <- copy(base)
  imputed_unknown[, `:=`(monitoring_state = "unmonitored_unknown",
                         source_record_id = "", survey_event_id = "",
                         survey_date = as.Date(NA), survey_completed = FALSE,
                         spawn_search_performed = FALSE, spawn_detected = FALSE,
                         negative_survey_evidence = "")]
  expect_error(validate_dfo_survey_effort(imputed_unknown), "DFO_UNMONITORED_IDENTITY")
  duplicate <- rbind(base, transform(copy(base), coverage_cell_id = "cell_b"))
  expect_error(validate_dfo_survey_effort(duplicate), "DFO_COVERAGE_GRAIN")
})
