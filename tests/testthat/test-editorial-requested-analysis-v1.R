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

testthat::test_that("finite-versus-X mapping preserves distinct count states", {
  count_type <- c(
    "numeric", "X", "unquantified_X", "lower_bound",
    "ambiguity_affected", "zero_filled", NA_character_
  )
  testthat::expect_identical(
    editorial_is_unquantified_x_v1(count_type),
    c(FALSE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE)
  )
})

testthat::test_that("optimizer code zero is retained as a completed warning", {
  diagnostics <- data.frame(
    analysis_taxon_id = c("a", "b"),
    outcome = c("count", "count"),
    optimizer_code = c(0, 1),
    status = c("failed_convergence", "failed_convergence")
  )
  contrasts <- data.frame(
    analysis_taxon_id = c("a", "b"),
    outcome = c("count", "count"),
    status = c("failed_convergence", "failed_convergence")
  )
  result <- editorial_normalize_completed_optimizer_warnings_v1(
    diagnostics, contrasts
  )
  testthat::expect_identical(
    result$diagnostics$status,
    c("completed_with_convergence_warning", "failed_convergence")
  )
  testthat::expect_identical(
    result$contrasts$status,
    c("completed_with_convergence_warning", "failed_convergence")
  )
})

testthat::test_that("outcome-blind link transformations are deterministic", {
  terms <- post_stage4a_exposure_terms_v1()
  events <- data.frame(
    analysis_event_token = c("a", "b"),
    event_block_token = c("e1", "e2"),
    observer_cluster_token = c("o1", "o2"),
    location_cluster_token = c("l1", "l2"),
    protocol = c("stationary", "traveling"),
    concurrent_links = c(2L, 1L),
    high_precision_2km = c(TRUE, TRUE),
    stringsAsFactors = FALSE
  )
  for (term in terms) events[[term]] <- 0L
  events$es_near_baseline <- c(10L, 1L)
  events$es_reference_early_pre <- c(2L, 0L)
  links <- data.frame(
    analysis_event_token = c("a", "a", "b"),
    distance_km = c(4, 1, 6),
    herring_source_token = c("z", "y", "x"),
    term = c(
      "es_near_baseline", "es_reference_early_pre",
      "es_reference_early_pre"
    ),
    period = c("baseline", "early_pre", "early_pre"),
    zone = c("near", "reference", "reference"),
    stringsAsFactors = FALSE
  )
  binary <- editorial_sensitivity_transform_v1(
    "binary_any_link", events, links
  )$events
  capped <- editorial_sensitivity_transform_v1(
    "cap_8", events, links
  )$events
  nearest <- editorial_sensitivity_transform_v1(
    "nearest_event", events, links
  )$events
  testthat::expect_equal(binary$es_near_baseline, c(1L, 1L))
  testthat::expect_equal(capped$es_near_baseline, c(8L, 1L))
  testthat::expect_equal(nearest$es_near_baseline, c(0L, 0L))
  testthat::expect_equal(nearest$es_reference_early_pre, c(1L, 1L))
  testthat::expect_equal(
    rowSums(nearest[terms]), c(1, 1)
  )
})
