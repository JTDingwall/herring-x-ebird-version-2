test_that("partial-pooling audit detects cross-model and cross-unit families", {
  x <- data.frame(
    model_id = c("M01", "M02", "M02"), region = "SoG",
    unit_class = c("guild", "species", "species"), outcome = "detection",
    contrast = "active_near", estimate = c(0.1, 0.2, 0.3),
    standard_error = c(0.1, 0.1, 0.1),
    partial_pool_estimate = c(0.11, 0.21, 0.29),
    partial_pool_standard_error = c(0.09, 0.09, 0.09)
  )
  audit <- audit_stage4a_partial_pooling_families(x)
  expect_equal(nrow(audit), 1L)
  expect_equal(audit$n_model_ids, 2L)
  expect_equal(audit$n_unit_classes, 2L)
  expect_false(audit$family_is_model_and_unit_specific)
})

test_that("tracked Stage 4A pooling columns expose the historical family defect", {
  effects <- utils::read.csv(
    repo_file("outputs", "stage4a_results", "effect_estimates.csv"),
    stringsAsFactors = FALSE
  )
  audit <- audit_stage4a_partial_pooling_families(effects)
  expect_equal(nrow(audit), 84L)
  expect_true(all(!audit$family_is_model_and_unit_specific))
  expect_equal(sum(audit$n_rows), 4890L)
})

test_that("synthetic holdout sentinel is filtered before allow-listed release", {
  sentinel <- "FORBIDDEN_2026_RESPONSE_SENTINEL"
  x <- data.frame(
    event_date = as.Date(c("2025-12-31", "2026-01-01")),
    region = c("SoG", "SoG"), release_year = c(2025L, 2026L),
    focal_response = c("development_value", sentinel),
    stringsAsFactors = FALSE
  )
  out <- stage4a_synthetic_holdout_metadata_release(
    x, "event_date", c("region", "release_year")
  )
  expect_equal(nrow(out), 1L)
  expect_equal(out$release_year, 2025L)
  expect_false(any(grepl(sentinel, capture.output(str(out)), fixed = TRUE)))
  expect_equal(attr(out, "holdout_audit")$excluded_future_rows, 1L)
  cache <- tempfile(fileext = ".rds")
  release <- tempfile(fileext = ".csv")
  on.exit(unlink(c(cache, release)), add = TRUE)
  saveRDS(out, cache)
  utils::write.csv(out, release, row.names = FALSE)
  expect_false(any(grepl(sentinel, capture.output(str(readRDS(cache))), fixed = TRUE)))
  expect_false(any(grepl(sentinel, readLines(release, warn = FALSE), fixed = TRUE)))
  expect_equal(sum(out$release_year), 2025L)
  expect_error(
    stage4a_synthetic_holdout_metadata_release(
      x, "event_date", c("region", "focal_response")
    ),
    "response or restricted-identity"
  )
})
