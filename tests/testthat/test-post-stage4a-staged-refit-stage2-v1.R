source(repo_file("R", "post_stage4a_distance_band_sensitivity_v2.R"))
source(repo_file("R", "post_stage4a_staged_refit_v1.R"))
source(repo_file("R", "post_stage4a_staged_refit_amendment_v1.R"))
source(repo_file("R", "post_stage4a_staged_refit_stage2_v1.R"))

test_that("Stage 2 gate adopts start date and stops before Stage 3", {
  withr::local_dir(project_root)
  record <- staged_refit_s2_gate_v1()
  expect_identical(
    record$decision,
    "ADOPT_START_DATE_STAGE1_AND_AUTHORIZE_STAGE2_DETECTABILITY_V1"
  )
  expect_identical(record$stage_gate$stage3_authorized_by_this_record, FALSE)
})

test_that("Stage 2 adds only time and annual detectability terms", {
  formula <- staged_refit_s2_formula_v1("model_response")
  labels <- attr(stats::terms(lme4::nobars(formula)), "term.labels")
  expect_true(all(staged_refit_s2_detectability_terms_v1() %in% labels))
  expect_true(all(post_stage4a_exposure_terms_v1() %in% labels))
  expect_false("log1p_prior_observer_checklists" %in% labels)
})

test_that("Stage 2 effort controls drop their own response only", {
  effort_terms <- c(
    "log_duration", "log_effort_distance", "observer_count"
  )
  for (response in effort_terms) {
    formula <- staged_refit_s2_effort_formula_v1(response)
    labels <- attr(stats::terms(lme4::nobars(formula)), "term.labels")
    expect_false(response %in% labels)
    expect_true(all(setdiff(effort_terms, response) %in% labels))
    expect_true(all(staged_refit_s2_detectability_terms_v1() %in% labels))
  }
})

test_that("Stage 2 change labels use a declared ten-percent hold band", {
  expect_identical(
    staged_refit_s2_classify_magnitude_v1(1, 0.8), "weakens"
  )
  expect_identical(
    staged_refit_s2_classify_magnitude_v1(1, 0.95), "holds"
  )
  expect_identical(
    staged_refit_s2_classify_magnitude_v1(1, 1.2), "strengthens"
  )
})

test_that("Stage 2 row binding preserves diagnostic provenance", {
  first <- data.frame(stage = "real", offset_days = NA_integer_)
  second <- data.frame(stage = "placebo", reporting_role = "diagnostic")
  got <- staged_refit_s2_bind_rows_v1(first, second)
  expect_equal(nrow(got), 2L)
  expect_true(all(
    c("stage", "offset_days", "reporting_role") %in% names(got)
  ))
})
