source(repo_file("R", "post_stage4a_staged_refit_v1.R"))
source(repo_file("R", "post_stage4a_staged_refit_amendment_v1.R"))
source(repo_file("R", "post_stage4a_staged_refit_stage2_v1.R"))
source(repo_file(
  "R", "post_stage4a_stage2_block_slope_diagnostic_v1.R"
))
source(repo_file("R", "post_stage4a_blockaware_v1.R"))

test_that("the block-aware specification pins the approved method", {
  withr::local_dir(project_root)
  spec <- blockaware_spec_gate_v1()
  expect_identical(
    spec$model$replaced_random_effect$to,
    "correlated_intercept_and_one_random_slope"
  )
  expect_identical(spec$multiplicity$family_size, 49L)
  expect_identical(spec$bootstrap$decision, "not_run")
  expect_identical(
    spec$intervals$checklist_reporting$cluster_robust_cr0_cr1,
    "prohibited"
  )
  expect_identical(
    spec$model$profile_likelihood_intervals,
    "prohibited_this_run"
  )
})

test_that("the specification records the baseline tallies as 19 and 13", {
  withr::local_dir(project_root)
  spec <- blockaware_spec_gate_v1()
  baseline <- spec$reporting_requirements$baseline_tallies
  expect_identical(baseline$conditional_positive_numeric_count_fixed49, 19L)
  expect_identical(
    baseline$checklist_reporting_fixed49_positive_direction, 13L
  )
  expect_identical(
    baseline$checklist_reporting_fixed49_negative_direction, 2L
  )
  expect_setequal(
    unlist(baseline$negative_direction_species),
    c("Bufflehead", "Common Raven")
  )
})

test_that("Stage 2 fixed-49 recomputation reproduces 19 and 13 plus 2", {
  withr::local_dir(project_root)
  stage2 <- blockaware_stage2_baseline_v1()
  expect_equal(nrow(stage2), 98L)
  counts <- stage2[
    stage2$outcome == "conditional_positive_numeric_count",
  ]
  reporting <- stage2[stage2$outcome == "checklist_reporting", ]
  expect_equal(sum(counts$significant_bh_fixed49), 19L)
  expect_equal(
    sum(reporting$significant_bh_fixed49 & reporting$estimate > 0), 13L
  )
  expect_setequal(
    reporting$species[
      reporting$significant_bh_fixed49 & reporting$estimate < 0
    ],
    c("Bufflehead", "Common Raven")
  )
})

test_that("fixed-49 Benjamini-Hochberg substitutes one for missing p", {
  p <- c(0.001, 0.02, rep(NA_real_, 47L))
  q <- blockaware_bh_fixed49_v1(p)
  expect_equal(length(q), 49L)
  expect_equal(q[[1L]], p.adjust(c(0.001, 0.02, rep(1, 47L)), "BH")[[1L]])
  expect_true(all(q[3:49] == 1))
  expect_error(blockaware_bh_fixed49_v1(c(0.01, 0.02)), "family size changed")
})

test_that("the primary interval prefers Kenward-Roger then Satterthwaite", {
  base <- data.frame(
    outcome = "conditional_positive_numeric_count",
    estimate = 0.4,
    wald_standard_error = 0.1, wald_conf_low = 0.2, wald_conf_high = 0.6,
    wald_p_value = 0.00006, wald_status = "completed",
    satterthwaite_standard_error = 0.1, satterthwaite_df = 30,
    satterthwaite_conf_low = 0.19, satterthwaite_conf_high = 0.61,
    satterthwaite_p_value = 0.0003, satterthwaite_status = "completed",
    kenward_roger_standard_error = 0.12, kenward_roger_df = 21,
    kenward_roger_conf_low = 0.15, kenward_roger_conf_high = 0.65,
    kenward_roger_p_value = 0.004, kenward_roger_status = "completed",
    stringsAsFactors = FALSE
  )
  skipped <- base
  skipped$kenward_roger_status <- "skipped_dense_inverse_memory_infeasible"
  skipped$kenward_roger_p_value <- NA_real_
  reporting <- base
  reporting$outcome <- "checklist_reporting"
  reporting$kenward_roger_status <- "not_applicable_binomial_glmm"
  reporting$kenward_roger_p_value <- NA_real_
  reporting$satterthwaite_status <- "not_applicable_non_gaussian"
  reporting$satterthwaite_p_value <- NA_real_
  resolved <- blockaware_primary_interval_v1(rbind(base, skipped, reporting))
  expect_identical(
    resolved$primary_interval_method,
    c("kenward_roger", "satterthwaite_denominator_df", "wald")
  )
  expect_equal(resolved$primary_p_value, c(0.004, 0.0003, 0.00006))
  expect_equal(resolved$primary_denominator_df, c(21, 30, Inf))
  expect_true(grepl("weaker", resolved$inference_strength_label[[3L]]))
  expect_true(grepl("stronger", resolved$inference_strength_label[[1L]]))
})

test_that("Lb_ddf needs the vcovAdj attributes that as.matrix would strip", {
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("pbkrtest")
  # Regression guard. An earlier version densified vcovAdj before handing it
  # to Lb_ddf. That silently dropped the P, W and condi attributes, Lb_ddf
  # recursed to the evaluation depth limit, and every Kenward-Roger interval
  # in the family came back "failed" for a reason that looked like a scale
  # limit rather than a stripped argument. The engine class was never
  # involved: lme4 and lmerTest fits behave identically here.
  set.seed(20260729L)
  n <- 240L
  frame <- data.frame(
    block = factor(rep(seq_len(12L), each = 20L)),
    x = stats::rnorm(n)
  )
  frame$y <- stats::rnorm(n) + as.numeric(frame$block) * 0.05 + frame$x
  L <- c(0, 1)

  fits <- list(
    lme4 = lme4::lmer(y ~ x + (1 + x | block), data = frame, REML = TRUE),
    lmerTest = lmerTest::lmer(
      y ~ x + (1 + x | block), data = frame, REML = TRUE
    )
  )
  expect_true(inherits(fits$lmerTest, "lmerModLmerTest"))
  Lb_ddf <- getFromNamespace("Lb_ddf", "pbkrtest")

  # The stripped call is not exercised here: its failure mode is an expression
  # stack overflow, which escapes testthat's condition handling. Asserting the
  # attribute contract is the safe equivalent.
  degrees <- vapply(fits, function(fit) {
    adjusted <- pbkrtest::vcovAdj(fit)
    expect_true(all(c("P", "W", "condi") %in% names(attributes(adjusted))))
    expect_false(
      any(c("P", "W", "condi") %in% names(attributes(as.matrix(adjusted))))
    )
    Lb_ddf(L, stats::vcov(fit), adjusted)
  }, numeric(1L))

  expect_true(all(is.finite(degrees)))
  expect_true(all(degrees > 0))
  # Both engines must agree, since lmerTest::lmer only adds stored derivatives.
  expect_equal(degrees[["lme4"]], degrees[["lmerTest"]], tolerance = 1e-8)
})

test_that("the bootstrap record refuses one-way block resampling", {
  withr::local_dir(project_root)
  bootstrap <- blockaware_bootstrap_record_v1()
  expect_identical(bootstrap$decision, "not_run")
  expect_equal(bootstrap$requested_repetitions, 999)
  expect_equal(bootstrap$observer_clusters_crossing_more_than_one_block, 2495)
  expect_equal(bootstrap$location_clusters_crossing_more_than_one_block, 4631)
  expect_true(bootstrap$checklists_partition_cleanly_by_block)
})

test_that("Kenward-Roger memory projection grows as n squared", {
  expect_equal(
    blockaware_kenward_roger_projected_gb_v1(2e4) /
      blockaware_kenward_roger_projected_gb_v1(1e4),
    4
  )
  # Calibration anchor: a measured run at n = 8,109 peaked near 13.1 GB.
  expect_equal(
    blockaware_kenward_roger_projected_gb_v1(8109), 13.1,
    tolerance = 0.05
  )
  expect_gt(blockaware_kenward_roger_projected_gb_v1(112180), 1000)
})

test_that("the Kenward-Roger row cap inverts the memory projection", {
  for (budget in c(4, 8, 12, 20)) {
    cap <- blockaware_kenward_roger_row_cap_v1(budget)
    expect_lte(blockaware_kenward_roger_projected_gb_v1(cap), budget)
    expect_gt(blockaware_kenward_roger_projected_gb_v1(cap + 1), budget)
  }
  expect_equal(blockaware_kenward_roger_row_cap_v1(12), 7723)
})

test_that("Kenward-Roger runtime projection matches the measured points", {
  expect_equal(
    blockaware_kenward_roger_projected_seconds_v1(2023), 21.7,
    tolerance = 1e-6
  )
  expect_equal(
    blockaware_kenward_roger_projected_seconds_v1(8109), 808,
    tolerance = 0.05
  )
})

test_that("pbkrtest and lmerTest are outside the frozen renv library", {
  withr::local_dir(project_root)
  frozen <- blockaware_frozen_library_v1()
  skip_if_not(dir.exists(frozen))
  installed <- rownames(utils::installed.packages(lib.loc = frozen))
  expect_false("pbkrtest" %in% installed)
  expect_false("lmerTest" %in% installed)
})

test_that("mechanism attribution separates widening from point movement", {
  # Species 01 keeps the Stage 2 point estimate but gets a six-fold wider
  # interval, so only widening can remove it. Species 02 keeps the Stage 2
  # precision and stays significant. Species 03 keeps the Stage 2 precision
  # but its point estimate collapses, so only movement can remove it.
  one_outcome <- function(outcome) {
    d <- data.frame(
      analysis_taxon_id = sprintf("t%02d", 1:49),
      species = sprintf("Species %02d", 1:49),
      outcome = outcome,
      blockaware_estimate = c(0.5, 0.5, 0.02, rep(0, 46L)),
      blockaware_se = c(0.30, 0.05, 0.05, rep(1, 46L)),
      stage2_estimate = c(0.5, 0.5, 0.5, rep(0, 46L)),
      stage2_se = c(0.05, 0.05, 0.05, rep(1, 46L)),
      stringsAsFactors = FALSE
    )
    d$outcome <- outcome
    d
  }
  frame <- rbind(
    one_outcome("conditional_positive_numeric_count"),
    one_outcome("checklist_reporting")
  )

  estimates <- data.frame(
    analysis_taxon_id = frame$analysis_taxon_id,
    species = frame$species,
    outcome = frame$outcome,
    estimate = frame$blockaware_estimate,
    primary_standard_error = frame$blockaware_se,
    primary_denominator_df = Inf,
    primary_interval_method = "wald",
    status = "completed",
    stringsAsFactors = FALSE
  )
  estimates$primary_p_value <- blockaware_counterfactual_p_v1(
    estimates$estimate, estimates$primary_standard_error, Inf
  )
  estimates$primary_conf_low <- estimates$estimate -
    1.96 * estimates$primary_standard_error
  estimates$primary_conf_high <- estimates$estimate +
    1.96 * estimates$primary_standard_error
  estimates$ratio <- exp(estimates$estimate)
  estimates$satterthwaite_p_value <- estimates$primary_p_value
  estimates$wald_p_value <- estimates$primary_p_value
  estimates <- blockaware_add_multiplicity_v1(estimates)

  stage2 <- data.frame(
    analysis_taxon_id = frame$analysis_taxon_id,
    species = frame$species,
    outcome = frame$outcome,
    estimate = frame$stage2_estimate,
    standard_error = frame$stage2_se,
    status = "completed",
    stringsAsFactors = FALSE
  )
  stage2$ratio <- exp(stage2$estimate)
  stage2$conf_low <- stage2$estimate - 1.96 * stage2$standard_error
  stage2$conf_high <- stage2$estimate + 1.96 * stage2$standard_error
  stage2$p_value <- blockaware_counterfactual_p_v1(
    stage2$estimate, stage2$standard_error, Inf
  )
  stage2$q_value_bh_fixed49 <- NA_real_
  for (outcome in unique(stage2$outcome)) {
    index <- which(stage2$outcome == outcome)
    stage2$q_value_bh_fixed49[index] <-
      blockaware_bh_fixed49_v1(stage2$p_value[index])
  }
  stage2$significant_bh_fixed49 <- stage2$q_value_bh_fixed49 < 0.05

  comparison <- blockaware_vs_stage2_v1(estimates, stage2)
  expect_equal(nrow(comparison), 98L)
  counts <- comparison[
    comparison$outcome == "conditional_positive_numeric_count",
  ]
  first <- counts[counts$species == "Species 01", ]
  expect_identical(first$bh_change, "left_bh")
  expect_identical(first$mechanism, "interval_widening")
  expect_false(first$survives_bh_widening_only)
  expect_true(first$survives_bh_point_movement_only)
  expect_gt(first$interval_width_ratio, 5)

  second <- counts[counts$species == "Species 02", ]
  expect_identical(second$bh_change, "retained_bh")
  expect_identical(second$mechanism, "not_applicable")

  third <- counts[counts$species == "Species 03", ]
  expect_identical(third$bh_change, "left_bh")
  expect_identical(third$mechanism, "point_estimate_movement")
  expect_true(third$survives_bh_widening_only)
  expect_false(third$survives_bh_point_movement_only)

  changes <- blockaware_bh_changes_v1(comparison)
  expect_true(all(changes$bh_change %in% c("left_bh", "entered_bh")))
  expect_true("Species 01" %in% changes$species)
})
