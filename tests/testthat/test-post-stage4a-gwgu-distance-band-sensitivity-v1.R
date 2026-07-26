source(repo_file("R", "post_stage4a_gwgu_distance_band_sensitivity_v1.R"))

test_that("gull v1 uses thirteen exact ordered 2 km distance bands", {
  boundaries <- c(0, 1.999, seq(2, 26, by = 2))
  links <- data.frame(
    analysis_event_token = seq_along(boundaries),
    event_day = 0L,
    distance_km = boundaries,
    link_provenance__ = "new_20_26",
    stringsAsFactors = FALSE
  )
  got <- post_stage4a_gwgu_classify_distance_band_links_v1(links)
  expect_equal(nrow(post_stage4a_gwgu_distance_band_spec_v1()), 13L)
  expect_equal(length(post_stage4a_gwgu_distance_band_terms_v1()), 78L)
  expect_identical(got$band[[1L]], "band_0_2")
  expect_identical(got$band[[3L]], "band_2_4")
  expect_identical(tail(got$band, 1L), "band_24_26")
})

test_that("the rounded archived 20 km boundary preserves provenance", {
  links <- data.frame(
    analysis_event_token = c("archived", "new"),
    event_day = 0L,
    distance_km = 20,
    link_provenance__ = c("archived_0_20", "new_20_26"),
    stringsAsFactors = FALSE
  )
  got <- post_stage4a_gwgu_classify_distance_band_links_v1(links)
  expect_identical(got$band, c("band_18_20", "band_20_22"))
})

test_that("gull v1 within-band contrasts use the same band's baseline", {
  coefficient_names <- c(
    "(Intercept)", post_stage4a_gwgu_distance_band_terms_v1()
  )
  definitions <- post_stage4a_gwgu_distance_band_contrasts_v1(
    coefficient_names
  )
  target <- definitions[[
    which(vapply(
      definitions,
      function(x) {
        identical(x$band, "band_24_26") &&
          identical(x$period, "spawn_start")
      },
      logical(1L)
    ))
  ]]
  expect_equal(target$vector[["db_band_24_26_spawn_start"]], 1)
  expect_equal(target$vector[["db_band_24_26_baseline"]], -1)
  expect_equal(sum(target$vector), 0)
})

test_that("gull v1 retains archived concurrent-link cardinality", {
  code <- paste(
    readLines(
      repo_file("R", "post_stage4a_gwgu_distance_band_sensitivity_v1.R"),
      warn = FALSE
    ),
    collapse = "\n"
  )
  expect_match(code, "observed_archived", fixed = TRUE)
  expect_match(code, "concurrent_links_0_26", fixed = TRUE)
  expect_match(code, "archived_0_20km_link_reconciliation_gate", fixed = TRUE)
})

test_that("gull distance-band v1 retains mixed effects and no fallback", {
  code <- paste(
    readLines(
      repo_file("R", "post_stage4a_gwgu_distance_band_sensitivity_v1.R"),
      warn = FALSE
    ),
    collapse = "\n"
  )
  expect_match(code, "lme4::glmer", fixed = TRUE)
  expect_match(code, "lme4::lmer", fixed = TRUE)
  expect_match(code, "nAGQ = 0L", fixed = TRUE)
  expect_match(code, "REML = TRUE", fixed = TRUE)
  expect_match(code, "no fallback", fixed = TRUE)
  expect_false(grepl("stats::glm\\(", code))
  expect_false(grepl("stats::lm\\(", code))
  expect_match(code, "checklist_year) > 2025L", fixed = TRUE)
  expect_match(code, "glaucous_winged_gull_fit = TRUE", fixed = TRUE)
  expect_match(code, "bald_eagle_fit = FALSE", fixed = TRUE)
})
