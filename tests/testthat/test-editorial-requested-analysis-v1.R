testthat::test_that("editorial direct contrast cancels the shared baseline", {
  weights <- editorial_contrast_weights_v1()
  active_minus_pre <- weights$active_minus_pre14
  testthat::expect_equal(
    unname(active_minus_pre[c("es_near_baseline", "es_reference_baseline")]),
    c(0, 0)
  )
  testthat::expect_equal(sum(active_minus_pre), 0)
  testthat::expect_equal(
    active_minus_pre[["es_near_spawn_start"]], 4 / 15
  )
  testthat::expect_equal(
    active_minus_pre[["es_reference_spawn_start"]], -4 / 15
  )
  testthat::expect_equal(
    active_minus_pre[["es_near_early_pre"]], -0.5
  )
  testthat::expect_equal(
    active_minus_pre[["es_reference_early_pre"]], 0.5
  )
})

testthat::test_that("compound Wald variance includes covariance terms", {
  beta <- stats::setNames(c(0.2, -0.1), c("a", "b"))
  covariance <- matrix(
    c(0.04, 0.015, 0.015, 0.09), 2, 2,
    dimnames = list(names(beta), names(beta))
  )
  result <- editorial_wald_v1(beta, covariance, c(a = 1, b = -1))
  testthat::expect_equal(result[["estimate"]], 0.3)
  testthat::expect_equal(
    result[["standard_error"]], sqrt(0.04 + 0.09 - 2 * 0.015)
  )
})

testthat::test_that("prediction contrast algebra is baseline adjusted", {
  values <- c(
    baseline_near = 0.4, baseline_reference = 0.3,
    pre14_near = 0.5, pre14_reference = 0.35,
    active_near = 0.7, active_reference = 0.4
  )
  result <- editorial_prediction_contrasts_v1(values)
  testthat::expect_equal(result[["pre14_baseline_adjusted"]], 0.05)
  testthat::expect_equal(result[["active_baseline_adjusted"]], 0.20)
  testthat::expect_equal(result[["active_minus_pre14"]], 0.15)
})

testthat::test_that("prediction scenarios retain named exposure weights", {
  scenarios <- editorial_scenario_values_v1()
  testthat::expect_equal(scenarios$baseline_near[["es_near_baseline"]], 1)
  testthat::expect_equal(
    scenarios$active_near[["es_near_spawn_start"]], 4 / 15
  )
  testthat::expect_equal(
    scenarios$active_reference[["es_reference_early_egg"]], 11 / 15
  )
  testthat::expect_equal(sum(scenarios$pre14_near), 1)
})

testthat::test_that("privacy gate rejects protected identifier columns", {
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path), add = TRUE)
  utils::write.csv(
    data.frame(analysis_event_token = "private"), path, row.names = FALSE
  )
  testthat::expect_error(
    editorial_privacy_column_gate_v1(path),
    "EDITORIAL_PRIVACY_COLUMN_GATE"
  )
})
