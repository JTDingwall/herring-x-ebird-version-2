test_that("DFO coverage validator distinguishes positive negative and unknown", {
  x <- data.table(
    coverage_cell_id = c("cell_a", "cell_b", "cell_c"),
    analysis_spatial_unit_id = c("unit_a", "unit_b", "unit_c"),
    survey_window_start = as.Date(c("2025-03-01", "2025-03-01", "2025-03-01")),
    survey_window_end = as.Date(c("2025-03-07", "2025-03-07", "2025-03-07")),
    monitoring_state = dfo_monitoring_states(),
    source_record_id = c("record_a", "record_b", ""),
    survey_method = c("method_a", "method_a", ""),
    survey_effort_value = c(2, 2, NA),
    survey_effort_unit = c("survey_hours", "survey_hours", ""),
    survey_completed = c(TRUE, TRUE, NA),
    spawn_search_performed = c(TRUE, TRUE, NA),
    spawn_detected = c(TRUE, FALSE, NA),
    coverage_fraction = c(0.8, 0.9, NA),
    detection_limit_description = c("visible spawn", "no spawn at method threshold", ""),
    quality_status = c("complete", "complete", "unknown"),
    source_release = "synthetic_fixture_v1"
  )
  got <- validate_dfo_survey_effort(x)
  expect_setequal(got$summary$monitoring_state, dfo_monitoring_states())
  expect_equal(sum(got$summary$coverage_cells), 3L)
})

test_that("DFO coverage validator rejects fabricated negatives and broken grain", {
  base <- data.table(
    coverage_cell_id = "cell_a", analysis_spatial_unit_id = "unit_a",
    survey_window_start = as.Date("2025-03-01"),
    survey_window_end = as.Date("2025-03-07"),
    monitoring_state = "surveyed_negative", source_record_id = "record_a",
    survey_method = "method_a", survey_effort_value = 2,
    survey_effort_unit = "survey_hours", survey_completed = TRUE,
    spawn_search_performed = TRUE, spawn_detected = FALSE,
    coverage_fraction = 0.9,
    detection_limit_description = "no spawn at method threshold",
    quality_status = "complete", source_release = "synthetic_fixture_v1"
  )
  missing_effort <- copy(base)
  missing_effort[, survey_effort_value := NA_real_]
  expect_error(validate_dfo_survey_effort(missing_effort), "DFO_SURVEYED_EFFORT")
  contradictory <- copy(base)
  contradictory[, spawn_detected := TRUE]
  expect_error(validate_dfo_survey_effort(contradictory), "DFO_STATE_CONSISTENCY")
  fabricated <- copy(base)
  fabricated[, `:=`(monitoring_state = "unmonitored_unknown",
                    source_record_id = "invented_negative")]
  expect_error(validate_dfo_survey_effort(fabricated), "DFO_UNMONITORED_IDENTITY")
  imputed_unknown <- copy(base)
  imputed_unknown[, `:=`(monitoring_state = "unmonitored_unknown",
                         source_record_id = "", survey_completed = FALSE,
                         spawn_search_performed = FALSE, spawn_detected = FALSE)]
  expect_error(validate_dfo_survey_effort(imputed_unknown), "DFO_UNMONITORED_IDENTITY")
  duplicate <- rbind(base, transform(copy(base), coverage_cell_id = "cell_b"))
  expect_error(validate_dfo_survey_effort(duplicate), "DFO_COVERAGE_GRAIN")
})
