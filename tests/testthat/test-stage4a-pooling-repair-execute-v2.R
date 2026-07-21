test_that("normal-normal estimator follows frozen positive-tau contract", {
  x <- data.table(
    component_evidence_id = c("a", "b", "c"),
    estimate = c(-1, 0, 2), standard_error = c(0.2, 0.3, 0.4)
  )
  got <- .stage4a_pooling_v2_family_estimator(copy(x))
  v <- x$standard_error ^ 2
  tau2 <- max(0, var(x$estimate) - mean(v))
  weights <- 1 / (v + tau2)
  mu <- sum(weights * x$estimate) / sum(weights)
  post_v <- 1 / (1 / v + 1 / tau2)
  expect_equal(got$family$tau2, tau2, tolerance = 1e-14)
  expect_equal(got$family$family_mean, mu, tolerance = 1e-14)
  expect_equal(got$rows$partial_pool_estimate_v2,
               post_v * (x$estimate / v + mu / tau2), tolerance = 1e-14)
  expect_equal(got$family$estimability_status, "ESTIMABLE")
})

test_that("zero-tau boundary and singleton handling are explicit", {
  common <- data.table(
    component_evidence_id = c("a", "b"), estimate = c(1, 1),
    standard_error = c(0.2, 0.4)
  )
  got <- .stage4a_pooling_v2_family_estimator(copy(common))
  v <- common$standard_error ^ 2
  expected_se <- sqrt(1 / sum(1 / v))
  expect_equal(got$family$tau2, 0)
  expect_equal(got$rows$partial_pool_estimate_v2, c(1, 1))
  expect_equal(got$rows$partial_pool_standard_error_v2,
               rep(expected_se, 2L), tolerance = 1e-14)

  singleton <- .stage4a_pooling_v2_family_estimator(common[1L])
  expect_equal(singleton$family$estimability_status, "NON_ESTIMABLE_SINGLETON")
  expect_true(is.na(singleton$rows$partial_pool_estimate_v2))
  expect_equal(singleton$rows$numeric_input_reason_code,
               "NON_ESTIMABLE_SINGLETON")
})

test_that("missing nonfinite and nonpositive inputs receive frozen reasons", {
  x <- data.table(
    component_evidence_id = letters[1:5],
    estimate = c(0, 1, NA, Inf, 2),
    standard_error = c(0.2, 0.3, 0.4, 0.5, 0)
  )
  got <- .stage4a_pooling_v2_family_estimator(copy(x))$rows
  expect_equal(got$numeric_input_reason_code[3L], "NON_ESTIMABLE_MISSING_INPUT")
  expect_equal(got$numeric_input_reason_code[4L], "NON_ESTIMABLE_NONFINITE_INPUT")
  expect_equal(got$numeric_input_reason_code[5L],
               "NON_ESTIMABLE_NONPOSITIVE_STANDARD_ERROR")
  expect_true(all(is.na(got$partial_pool_estimate_v2[3:5])))
})

test_that("17-digit numeric serialization is deterministic", {
  x <- c(0, 1 / 3, -2.5e-12, NA, Inf, -Inf, NaN)
  expect_identical(stage4a_pooling_v2_format_number(x),
                   stage4a_pooling_v2_format_number(rev(rev(x))))
  expect_identical(stage4a_pooling_v2_format_number(x)[1:3],
                   c("0", "0.33333333333333331", "-2.4999999999999998e-12"))
  expect_identical(stage4a_pooling_v2_format_number(x)[4:7],
                   c("", "Inf", "-Inf", "NaN"))
})
