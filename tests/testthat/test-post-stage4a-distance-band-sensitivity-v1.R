source(repo_file("R", "post_stage4a_distance_band_sensitivity_v1.R"))

test_that("distance bands use exact ordered 2 km boundaries", {
  links <- data.frame(
    analysis_event_token = letters[1:11],
    event_day = 0L,
    distance_km = c(0, 1.999, 2, 3.999, 4, 5.999, 6, 7.999, 8, 10, 20),
    stringsAsFactors = FALSE
  )
  got <- post_stage4a_classify_distance_band_links_v1(links)
  expect_identical(
    got$band,
    c(
      "band_0_2", "band_0_2", "band_2_4", "band_2_4",
      "band_4_6", "band_4_6", "band_6_8", "band_6_8",
      "band_8_10", "band_8_10", "band_10_20"
    )
  )
})

test_that("within-band contrasts use the same band's baseline", {
  coefficient_names <- c(
    "(Intercept)", post_stage4a_distance_band_terms_v1()
  )
  definitions <- post_stage4a_distance_band_contrasts_v1(
    coefficient_names
  )
  target <- definitions[[
    which(vapply(
      definitions,
      function(x) {
        identical(x$band, "band_4_6") &&
          identical(x$period, "spawn_start")
      },
      logical(1L)
    ))
  ]]
  expect_equal(target$vector[["db_band_4_6_spawn_start"]], 1)
  expect_equal(target$vector[["db_band_4_6_baseline"]], -1)
  expect_equal(sum(target$vector), 0)
})

test_that("distance-band model retains mixed effects and no fallback", {
  code <- paste(
    readLines(
      repo_file("R", "post_stage4a_distance_band_sensitivity_v1.R"),
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
  expect_match(code, "glaucous_winged_gull_fit = FALSE", fixed = TRUE)
})
