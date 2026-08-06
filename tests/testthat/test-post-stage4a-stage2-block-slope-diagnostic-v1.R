source(repo_file("R", "post_stage4a_staged_refit_v1.R"))
source(repo_file("R", "post_stage4a_staged_refit_amendment_v1.R"))
source(repo_file("R", "post_stage4a_staged_refit_stage2_v1.R"))
source(repo_file(
  "R", "post_stage4a_stage2_block_slope_diagnostic_v1.R"
))

test_that("block-slope authorization is narrow", {
  withr::local_dir(project_root)
  record <- stage2_block_slope_gate_v1()
  expect_identical(
    record$authorized_scope$outcome,
    "conditional_positive_numeric_count"
  )
  expect_true(
    "full_event_block_bootstrap" %in% record$not_authorized
  )
  expect_true(
    "stage3_dose_execution" %in% record$not_authorized
  )
})

test_that("random-slope direction is normalized to the target contrast", {
  direction <- stage2_block_slope_direction_v1()
  expect_equal(
    sum(direction$contrast * direction$direction),
    1,
    tolerance = 1e-12
  )
  expect_equal(
    direction$squared_norm,
    sum(direction$contrast^2),
    tolerance = 1e-12
  )
})

test_that("block-slope formula retains Stage 2 fixed terms", {
  formula <- stage2_block_slope_formula_v1()
  fixed_labels <- attr(
    stats::terms(suppressWarnings(lme4::nobars(formula))), "term.labels"
  )
  expect_true(all(post_stage4a_exposure_terms_v1() %in% fixed_labels))
  expect_true(all(
    staged_refit_s2_detectability_terms_v1() %in% fixed_labels
  ))
  random_terms <- vapply(
    suppressWarnings(lme4::findbars(formula)),
    function(term) paste(deparse(term), collapse = " "),
    character(1L)
  )
  expect_true(
    any(grepl(
      "block_active_minus_pre14.*event_block_token",
      random_terms
    ))
  )
})

test_that("top-ten selection is deterministic and result-frozen", {
  withr::local_dir(project_root)
  selected <- stage2_block_slope_select_top_ten_v1()
  expect_equal(nrow(selected), 10L)
  expect_identical(selected$effect_rank, seq_len(10L))
  expect_true(all(diff(selected$estimate) <= 0))
  expect_identical(
    selected$species,
    c(
      "Long-tailed Duck", "Surf Scoter", "Short-billed Gull",
      "Bonaparte's Gull", "Iceland Gull", "Harlequin Duck",
      "Glaucous-winged Gull", "Greater Scaup",
      "Common Goldeneye", "California Gull"
    )
  )
})

test_that("inverse Herfindahl uses exposed-checklist block shares", {
  terms <- post_stage4a_exposure_terms_v1()
  fixture <- data.frame(
    event_block_token = c(rep("a", 4), rep("b", 2), "c"),
    stringsAsFactors = FALSE
  )
  for (term in terms) fixture[[term]] <- 0L
  fixture[[terms[[1L]]]] <- c(rep(1L, 6), 0L)
  distribution <- stage2_block_slope_exposure_distribution_v1(fixture)
  expect_equal(distribution$exposed_checklists, 6)
  expect_equal(distribution$event_blocks_total, 3)
  expect_equal(distribution$event_blocks_with_exposed_checklists, 2)
  expect_equal(distribution$event_blocks_without_exposed_checklists, 1)
  expect_equal(
    distribution$effective_clusters_inverse_herfindahl,
    1 / ((4 / 6)^2 + (2 / 6)^2)
  )
  expect_true(distribution$suppressed_minimum_under_20)
  expect_true(is.na(distribution$minimum_per_block))
})
