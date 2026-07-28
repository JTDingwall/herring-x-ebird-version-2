source(repo_file("R", "post_stage4a_distance_band_sensitivity_v2.R"))
source(repo_file("R", "post_stage4a_staged_refit_v1.R"))
source(repo_file("R", "post_stage4a_staged_refit_amendment_v1.R"))

test_that("amendment gate records the results-known strategy change", {
  withr::local_dir(project_root)
  amendment <- staged_refit_amendment_gate_v1()
  expect_identical(
    amendment$decision,
    "REPLACE_SPECIES_NEGATIVE_CONTROLS_WITH_OUTCOME_AND_TIMING_CONTROLS"
  )
  expect_identical(
    as.numeric(amendment$added_placebo_exposure$offsets_days),
    c(-180, -90, 90, 180)
  )
})

test_that("effort outcome formulas remove only the response effort term", {
  effort_terms <- c(
    "log_duration", "log_effort_distance", "observer_count"
  )
  for (response in effort_terms) {
    formula <- staged_refit_amendment_effort_formula_v1(response)
    labels <- attr(stats::terms(lme4::nobars(formula)), "term.labels")
    expect_false(response %in% labels)
    expect_true(all(setdiff(effort_terms, response) %in% labels))
    expect_true(all(post_stage4a_exposure_terms_v1() %in% labels))
  }
})

test_that("fake anchor offset follows real-start-plus-offset sign", {
  lookup <- data.frame(
    herring_source_token = c("h0", "h1"),
    event_year = c(2020L, 2020L),
    anchor_shift_days = c(0L, 2L),
    used_end_date_fallback = c(FALSE, FALSE),
    stringsAsFactors = FALSE
  )
  links <- data.frame(
    analysis_event_token = c("e0", "e1"),
    herring_source_token = c("h0", "h1"),
    region = c("SoG", "SoG"),
    checklist_year = c(2020L, 2020L),
    event_year = c(2020L, 2020L),
    event_day = c(180L, 178L),
    distance_km = c(1, 2),
    stringsAsFactors = FALSE
  )
  events <- data.frame(
    analysis_event_token = c("e0", "e1"),
    event_block_token = c("b0", "b1"),
    region = c("SoG", "SoG"),
    checklist_year = c(2020L, 2020L),
    concurrent_links = c(0L, 0L),
    stringsAsFactors = FALSE
  )
  got <- staged_refit_amendment_placebo_events_v1(
    events, links, lookup, 180L
  )
  expect_identical(got$events$concurrent_links, c(1L, 1L))
  expect_identical(got$events$es_near_spawn_start, c(1L, 1L))
})

test_that("pooled terrestrial reporting keeps ambiguity distinct", {
  expect_identical(
    staged_refit_amendment_pool_detection_v1(
      c(1L, 0L, NA_integer_, NA_integer_),
      c(0L, 0L, 1L, NA_integer_)
    ),
    c(1L, 0L, 1L, NA_integer_)
  )
})

test_that("widened links reconcile archived overlap one-to-one", {
  archived <- data.frame(
    analysis_event_token = c("e0", "e1"),
    herring_source_token = c("h0", "h1"),
    event_day = c(-90L, 120L),
    distance_km = c(1, 2),
    stringsAsFactors = FALSE
  )
  widened <- rbind(
    archived,
    data.frame(
      analysis_event_token = "e2",
      herring_source_token = "h2",
      event_day = -200L,
      distance_km = 3,
      stringsAsFactors = FALSE
    )
  )
  got <- staged_refit_amendment_reconcile_wide_links_v1(
    archived, widened
  )
  expect_equal(got$archived_rows, 2L)
  expect_equal(got$widened_rows, 3L)
  expect_identical(
    got$overlap_one_to_one_reconciliation, "PASS"
  )
})

test_that("public amendment outputs retain no identifier-like headers", {
  path <- tempfile(fileext = ".csv")
  utils::write.csv(
    data.frame(
      audit_event_label = "long_span_event_36day_v1",
      recorded_span_days = 72L,
      link_count = 45L
    ),
    path,
    row.names = FALSE
  )
  expect_silent(staged_refit_privacy_column_gate_v1(path))
})
