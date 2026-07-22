test_that("whole-bundle placebos preserve registered invariants and ignore responses", {
  n <- 80L
  x <- data.frame(
    analysis_event_token = sprintf("fixture_event_%03d", seq_len(n)),
    location_cluster_token = sprintf("fixture_location_%02d", rep(1:20, each = 4L)),
    region = rep(c("SoG", "WCVI"), each = n / 2L),
    checklist_year = rep(c(2020L, 2021L), each = n / 2L),
    active_reference_class = rep(c("active", "reference", "other", "other"), n / 4L),
    concurrent_links = 2L, response_trap = rep(c(0L, 1L), n / 2L),
    stringsAsFactors = FALSE
  )
  x$active_near <- as.integer(x$active_reference_class == "active")
  x$contemporaneous_reference <- as.integer(x$active_reference_class == "reference")
  time_fields <- c("time_early_pre", "time_immediate_pre", "time_spawn_start",
                   "time_early_egg", "time_late_egg", "time_post")
  distance_fields <- c("distance_ring_0_0p5", "distance_ring_0p5_1",
    "distance_ring_1_2", "distance_ring_2_3", "distance_ring_3_4",
    "distance_ring_4_5", "distance_ring_5_10", "distance_ring_10_20")
  for (field in time_fields) x[[field]] <- 0L
  for (field in distance_fields) x[[field]] <- 0L
  x$time_spawn_start <- 1L
  x$distance_ring_0_0p5 <- 1L
  x$distance_ring_5_10 <- 1L
  for (model in c("M27_v2", "M28_v2")) {
    got <- stage4a_sensitivity_transform_bundle_v2(x, model)
    expect_identical(got$events$response_trap, x$response_trap)
    expect_false(any(got$source_row == seq_len(nrow(x))))
    expect_true(all(got$audit$response_fields_read == 0L))
    expect_true(all(got$audit$bundle_integrity_pass))
    expect_true(all(got$audit$regional_temporal_support_pass))
    set.seed(991L)
    shuffled <- x[sample(nrow(x)), , drop = FALSE]
    replay <- stage4a_sensitivity_transform_bundle_v2(shuffled, model)
    fields <- c("analysis_event_token", stage4a_sensitivity_bundle_fields_v2())
    left <- got$events[order(got$events$analysis_event_token), fields, drop = FALSE]
    right <- replay$events[order(replay$events$analysis_event_token), fields, drop = FALSE]
    expect_identical(left, right)
    expect_identical(got$audit, replay$audit)
  }
})

test_that("matched sensitivity code has no simplified model fallback", {
  code <- paste(readLines(repo_file("R", "stage4a_publication_sensitivity_v2.R"),
                          warn = FALSE), collapse = "\n")
  expect_match(code, "mgcv::bam", fixed = TRUE)
  expect_match(code, "method = \"fREML\"", fixed = TRUE)
  expect_match(code, "discrete = TRUE", fixed = TRUE)
  expect_false(grepl("stats::glm\\(", code))
  expect_false(grepl("stats::lm\\(", code))
  expect_match(code, "failed_numerical_fit_no_fallback", fixed = TRUE)
})
