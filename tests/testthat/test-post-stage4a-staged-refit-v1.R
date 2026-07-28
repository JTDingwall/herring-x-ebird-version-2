source(repo_file("R", "post_stage4a_distance_band_sensitivity_v2.R"))
source(repo_file("R", "post_stage4a_staged_refit_v1.R"))

test_that("Stage 1 reanchors a many-to-one source join without expansion", {
  lookup <- data.frame(
    herring_source_token = c("h0", "h1"),
    event_year = c(2020L, 2021L),
    anchor_shift_days = c(0L, 3L),
    used_end_date_fallback = c(FALSE, TRUE),
    stringsAsFactors = FALSE
  )
  links <- data.frame(
    analysis_event_token = c("e0", "e1", "e2"),
    herring_source_token = c("h0", "h1", "h1"),
    event_year = c(2020L, 2021L, 2021L),
    event_day = c(-1L, 0L, 4L),
    distance_km = c(1, 2, 3),
    stringsAsFactors = FALSE
  )
  got <- staged_refit_reanchor_links_v1(links, lookup)
  expect_equal(nrow(got), nrow(links))
  expect_identical(got$event_day, c(-1L, 3L, 7L))
  expect_identical(got$anchor_fallback__, c(FALSE, TRUE, TRUE))
})

test_that("Stage 1 anchor join rejects duplicate and unmatched source keys", {
  lookup <- data.frame(
    herring_source_token = c("h0", "h0"),
    event_year = 2020L,
    anchor_shift_days = 0L,
    used_end_date_fallback = FALSE,
    stringsAsFactors = FALSE
  )
  links <- data.frame(
    analysis_event_token = "e0",
    herring_source_token = "h0",
    event_year = 2020L,
    event_day = 0L,
    distance_km = 1,
    stringsAsFactors = FALSE
  )
  expect_error(
    staged_refit_reanchor_links_v1(links, lookup),
    "duplicate source lookup key",
    fixed = TRUE
  )
  lookup <- lookup[1, , drop = FALSE]
  links$herring_source_token <- "absent"
  expect_error(
    staged_refit_reanchor_links_v1(links, lookup),
    "unmatched source link",
    fixed = TRUE
  )
})

test_that("Stage 1 preserves reversed source intervals for explicit audit", {
  lookup <- data.frame(
    herring_source_token = "h0",
    event_year = 2020L,
    anchor_shift_days = -2L,
    used_end_date_fallback = FALSE,
    stringsAsFactors = FALSE
  )
  links <- data.frame(
    analysis_event_token = "e0",
    herring_source_token = "h0",
    event_year = 2020L,
    event_day = 1L,
    distance_km = 1,
    stringsAsFactors = FALSE
  )
  got <- staged_refit_reanchor_links_v1(links, lookup)
  expect_identical(got$event_day, -1L)
  expect_identical(got$anchor_shift_days__, -2L)
})

test_that("Stage 1 keeps frozen periods and exact editorial weights", {
  period <- post_stage4a_period_spec_v1()
  expect_identical(
    period$period,
    c(
      "baseline", "early_pre", "immediate_pre", "spawn_start",
      "early_egg", "late_egg"
    )
  )
  weights <- staged_refit_s1_contrast_weights_v1()
  x <- weights$active_minus_pre14
  expect_equal(x[["es_near_spawn_start"]], 4 / 15)
  expect_equal(x[["es_near_early_egg"]], 11 / 15)
  expect_equal(x[["es_near_early_pre"]], -0.5)
  expect_equal(x[["es_near_immediate_pre"]], -0.5)
  expect_equal(x[["es_near_baseline"]], 0)
  expect_equal(x[["es_reference_baseline"]], 0)
})

test_that("Stage 1 Wald calculation uses the full fixed covariance", {
  weights <- staged_refit_s1_contrast_weights_v1()$active_minus_pre14
  names_now <- unique(names(weights))
  beta <- stats::setNames(seq_along(names_now) / 10, names_now)
  covariance <- diag(0.05, length(names_now))
  covariance[1, 2] <- covariance[2, 1] <- 0.01
  dimnames(covariance) <- list(names_now, names_now)
  vector <- .post_stage4a_contrast_vector_v1(names_now, weights)
  got <- staged_refit_wald_v1(beta, covariance, weights)
  expect_equal(
    unname(got[["estimate"]]),
    unname(sum(vector * beta))
  )
  expect_equal(
    unname(got[["standard_error"]]),
    unname(sqrt(drop(t(vector) %*% covariance %*% vector)))
  )
})

test_that("Stage 1 guild timing joins the frozen exact parent one-to-one", {
  parent <- utils::read.csv(
    repo_file(
      "outputs", "referee_reads_followup_v1", "item10_guild_means.csv"
    ),
    stringsAsFactors = FALSE
  )
  parent$outcome <- ifelse(
    parent$outcome == "detection",
    "checklist_reporting",
    "conditional_positive_numeric_count"
  )
  synthetic <- data.frame(
    stage = "s1_anchor",
    row_type = "guild_mean",
    outcome = parent$outcome,
    guild = parent$guild,
    species = parent$species,
    estimate = parent$exact_mean_link_contrast,
    standard_error = parent$exact_standard_error,
    conf_low = parent$exact_conf_low,
    conf_high = parent$exact_conf_high,
    ratio_spawn_start_vs_early_egg =
      parent$exact_ratio_spawn_start_vs_early_egg,
    q_between = NA_real_,
    df_between = 6L,
    p_guild_differences = ifelse(
      parent$outcome == "checklist_reporting",
      0.0204858376038193,
      5.89578097637058e-23
    ),
    q_residual = NA_real_,
    df_residual = NA_integer_,
    p_residual_heterogeneity = NA_real_,
    residual_i2_percent = NA_real_,
    variance_method = "full_fixed_effect_covariance",
    stringsAsFactors = FALSE
  )
  got <- staged_refit_augment_guild_parent_v1(
    synthetic,
    means_path = repo_file(
      "outputs", "referee_reads_followup_v1", "item10_guild_means.csv"
    ),
    tests_path = repo_file(
      "outputs", "referee_reads_followup_v1",
      "item10_meta_regression_tests.csv"
    )
  )
  expect_false(any(got$changed_direction))
  expect_false(any(got$changed_interval_significance))
  expect_false(any(got$changed_omnibus_significance))
})

test_that("Stage 1 code retains mixed models, warnings, and no fallback", {
  code <- paste(
    readLines(
      repo_file("R", "post_stage4a_staged_refit_v1.R"),
      warn = FALSE
    ),
    collapse = "\n"
  )
  expect_match(code, "lme4::glmer", fixed = TRUE)
  expect_match(code, "lme4::lmer", fixed = TRUE)
  expect_match(code, "nAGQ = 0L", fixed = TRUE)
  expect_match(code, "REML = TRUE", fixed = TRUE)
  expect_match(code, "failed_numerical_fit_no_fallback", fixed = TRUE)
  expect_match(code, "full_fixed_effect_covariance_used", fixed = TRUE)
  expect_false(grepl("stats::glm\\(", code))
  expect_false(grepl("stats::lm\\(", code))
})

test_that("Stage 1 aggregate privacy gate rejects identifying headers", {
  safe <- tempfile(fileext = ".csv")
  unsafe <- tempfile(fileext = ".csv")
  utils::write.csv(
    data.frame(metric = "rows", value = 20L),
    safe,
    row.names = FALSE
  )
  utils::write.csv(
    data.frame(analysis_event_token = "restricted"),
    unsafe,
    row.names = FALSE
  )
  expect_silent(staged_refit_privacy_column_gate_v1(safe))
  expect_error(
    staged_refit_privacy_column_gate_v1(unsafe),
    "STAGED_REFIT_PRIVACY_COLUMN_GATE",
    fixed = TRUE
  )
})
