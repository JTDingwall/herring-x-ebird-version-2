test_that("event-study period and zone boundaries are exact", {
  days <- c(
    -29L, -28L, -15L, -14L, -8L, -7L, -1L, 0L, 3L,
    4L, 14L, 15L, 28L, 29L
  )
  links <- data.frame(
    analysis_event_token = sprintf("event_%02d", seq_along(days)),
    event_day = days,
    distance_km = rep(c(4.999, 5), length.out = length(days)),
    stringsAsFactors = FALSE
  )
  got <- post_stage4a_classify_links_v1(links)
  expect_identical(
    got$period,
    c(
      NA_character_, "baseline", "baseline", "early_pre", "early_pre",
      "immediate_pre", "immediate_pre", "spawn_start", "spawn_start",
      "early_egg", "early_egg", "late_egg", "late_egg", NA_character_
    )
  )
  expect_identical(
    got$zone,
    rep(c("near", "reference"), length.out = length(days))
  )
  edge <- data.frame(
    analysis_event_token = c("near", "reference", "outer"),
    event_day = 0L,
    distance_km = c(0, 5, 20),
    stringsAsFactors = FALSE
  )
  edge_got <- post_stage4a_classify_links_v1(edge)
  expect_identical(edge_got$zone, c("near", "reference", "reference"))
})

test_that("joint exposure preserves concurrent event pairing and model rows", {
  events <- data.frame(
    analysis_event_token = c("a", "b"),
    event_block_token = c("block_a", "block_b"),
    region = "SoG",
    checklist_year = 2020L,
    concurrent_links = c(2L, 1L),
    stringsAsFactors = FALSE
  )
  links <- data.frame(
    analysis_event_token = c("a", "a", "b"),
    region = "SoG",
    checklist_year = 2020L,
    event_day = c(-7L, 4L, 20L),
    distance_km = c(2, 8, 1),
    stringsAsFactors = FALSE
  )
  got <- post_stage4a_add_joint_exposure_v1(events, links)
  expect_equal(nrow(got$events), 2L)
  expect_false(anyDuplicated(got$events$analysis_event_token) > 0L)
  expect_equal(got$events$es_near_immediate_pre[[1L]], 1L)
  expect_equal(got$events$es_reference_early_egg[[1L]], 1L)
  expect_equal(got$events$es_near_early_egg[[1L]], 0L)
  expect_equal(got$events$es_near_late_egg[[2L]], 1L)
  expect_equal(sum(got$events[post_stage4a_exposure_terms_v1()]), 3L)
})

test_that("joint exposure rejects changed link cardinality", {
  events <- data.frame(
    analysis_event_token = "a",
    event_block_token = "block_a",
    region = "SoG",
    checklist_year = 2020L,
    concurrent_links = 2L,
    stringsAsFactors = FALSE
  )
  links <- data.frame(
    analysis_event_token = "a",
    region = "SoG",
    checklist_year = 2020L,
    event_day = 0L,
    distance_km = 1,
    stringsAsFactors = FALSE
  )
  expect_error(
    post_stage4a_add_joint_exposure_v1(events, links),
    "concurrent-link totals changed",
    fixed = TRUE
  )
})

test_that("source-event region is descriptive but checklist year must agree", {
  events <- data.frame(
    analysis_event_token = "a",
    event_block_token = "block_a",
    region = "SoG",
    checklist_year = 2020L,
    concurrent_links = 1L,
    stringsAsFactors = FALSE
  )
  links <- data.frame(
    analysis_event_token = "a",
    region = NA_character_,
    checklist_year = 2020L,
    event_day = 0L,
    distance_km = 1,
    stringsAsFactors = FALSE
  )
  expect_equal(
    post_stage4a_add_joint_exposure_v1(events, links)$events$es_near_spawn_start,
    1L
  )
  links$checklist_year <- 2019L
  expect_error(
    post_stage4a_add_joint_exposure_v1(events, links),
    "checklist year disagreement",
    fixed = TRUE
  )
})

test_that("event-study contrasts implement the registered KISS estimands", {
  coefficient_names <- c("(Intercept)", post_stage4a_exposure_terms_v1())
  definitions <- post_stage4a_contrast_definitions_v1(coefficient_names)
  by_name <- stats::setNames(definitions, vapply(
    definitions, `[[`, character(1L), "contrast"
  ))
  active <- by_name[["did_active_0_14_day"]]$vector
  pre14 <- by_name[["did_pre_14_day"]]$vector
  pre7 <- by_name[["did_pre_7_day"]]$vector
  expect_equal(sum(active), 0, tolerance = 1e-12)
  expect_equal(active[["es_near_spawn_start"]], 4 / 15)
  expect_equal(active[["es_reference_spawn_start"]], -4 / 15)
  expect_equal(active[["es_near_early_egg"]], 11 / 15)
  expect_equal(active[["es_reference_early_egg"]], -11 / 15)
  expect_equal(active[["es_near_baseline"]], -1)
  expect_equal(active[["es_reference_baseline"]], 1)
  expect_equal(pre14[["es_near_early_pre"]], 0.5)
  expect_equal(pre14[["es_near_immediate_pre"]], 0.5)
  expect_equal(pre7, by_name[["did_immediate_pre"]]$vector)
})

test_that("production fitting has no simplified fallback or prospective access", {
  code <- paste(
    readLines(
      repo_file("R", "post_stage4a_sog_event_study_v1.R"),
      warn = FALSE
    ),
    collapse = "\n"
  )
  expect_match(code, "lme4::glmer", fixed = TRUE)
  expect_match(code, "lme4::lmer", fixed = TRUE)
  expect_match(code, "nAGQ = 0L", fixed = TRUE)
  expect_match(code, "REML = TRUE", fixed = TRUE)
  expect_match(code, "failed_numerical_fit_no_fallback", fixed = TRUE)
  expect_false(grepl("stats::glm\\(", code))
  expect_false(grepl("stats::lm\\(", code))
  expect_match(code, "checklist_year) > 2025L", fixed = TRUE)
  for (term in c(
      "event_block_token", "observer_cluster_token",
      "location_cluster_token")) {
    expect_match(code, paste0("(1 | ", term, ")"), fixed = TRUE)
  }
})

test_that("parallel worker gate is bounded and rejects invalid values", {
  variable <- "POST_STAGE4A_SOG_EVENT_STUDY_WORKERS"
  old <- Sys.getenv(variable, unset = NA_character_)
  on.exit({
    if (is.na(old)) {
      Sys.unsetenv(variable)
    } else {
      do.call(Sys.setenv, stats::setNames(list(old), variable))
    }
  }, add = TRUE)
  do.call(Sys.setenv, stats::setNames(list("4"), variable))
  expect_equal(post_stage4a_worker_count_v1(51L), 4L)
  expect_equal(post_stage4a_worker_count_v1(2L), 2L)
  do.call(Sys.setenv, stats::setNames(list("0"), variable))
  expect_error(
    post_stage4a_worker_count_v1(51L),
    "workers must be a positive integer",
    fixed = TRUE
  )
})

test_that("species roles promote requested taxa and demote comparators", {
  roles <- utils::read.csv(
    repo_file(
      "metadata",
      "post_stage4a_sog_event_study_species_roles_v1.csv"
    ),
    stringsAsFactors = FALSE
  )
  main <- roles$common_name[
    roles$presentation_role == "main_ecological_panel"
  ]
  expect_setequal(
    intersect(
      main,
      c(
        "Bald Eagle", "Hooded Merganser", "Mallard",
        "American Crow", "Common Raven"
      )
    ),
    c(
      "Bald Eagle", "Hooded Merganser", "Mallard",
      "American Crow", "Common Raven"
    )
  )
  comparators <- roles$common_name[
    roles$presentation_role == "supplementary_specificity_comparator"
  ]
  expect_setequal(comparators, c("Gadwall", "Northern Shoveler"))
})

test_that("active_minus_pre_14_day carries zero weight on both baseline terms", {
  names_for_contrast <- c("(Intercept)", post_stage4a_exposure_terms_v1())
  definitions <- post_stage4a_contrast_definitions_v1(names_for_contrast)
  pick <- function(id) {
    definitions[
      vapply(definitions, function(x) x$contrast == id, logical(1L))
    ][[1L]]
  }
  new_contrast <- pick("active_minus_pre_14_day")

  ## The baseline terms cancel algebraically: the active half contributes
  ## -1 to es_near_baseline and +1 to es_reference_baseline, and the negated
  ## pre half contributes +1 and -1.
  expect_lt(abs(new_contrast$weights[["es_near_baseline"]]), 1e-12)
  expect_lt(abs(new_contrast$weights[["es_reference_baseline"]]), 1e-12)
  expect_lt(abs(new_contrast$vector[["es_near_baseline"]]), 1e-12)
  expect_lt(abs(new_contrast$vector[["es_reference_baseline"]]), 1e-12)

  ## It is exactly the released active contrast minus the released pre
  ## contrast, so its point estimate is reproducible from the frozen release.
  expect_equal(
    unname(new_contrast$vector),
    unname(pick("did_active_0_14_day")$vector - pick("did_pre_14_day")$vector)
  )
  expect_lt(abs(sum(new_contrast$vector)), 1e-12)
  expect_true(new_contrast$primary_estimand)
  expect_identical(
    new_contrast$contrast_type,
    "duration_weighted_difference_in_differences"
  )

  ## Duration weights: 4 and 11 of the 15 active days, and half of each
  ## seven-day pre-onset window.
  expect_equal(new_contrast$vector[["es_near_spawn_start"]], 4 / 15)
  expect_equal(new_contrast$vector[["es_near_early_egg"]], 11 / 15)
  expect_equal(new_contrast$vector[["es_near_early_pre"]], -0.5)
  expect_equal(new_contrast$vector[["es_near_immediate_pre"]], -0.5)
})

test_that("the new contrast reproduces the frozen release point estimates", {
  release <- repo_file(
    "outputs", "post_stage4a_sog_event_study_v1", "effect_estimates_v1.csv"
  )
  skip_if_not(file.exists(release))
  effects <- utils::read.csv(release, stringsAsFactors = FALSE)
  key <- function(x) paste(x$analysis_taxon_id, x$outcome, sep = "|")
  active <- effects[effects$contrast == "did_active_0_14_day", , drop = FALSE]
  pre <- effects[effects$contrast == "did_pre_14_day", , drop = FALSE]
  pre <- pre[match(key(active), key(pre)), , drop = FALSE]
  derived <- exp(active$estimate - pre$estimate)

  spot <- function(species, outcome) {
    derived[active$unit_label == species & active$outcome == outcome]
  }
  expect_equal(spot("Surf Scoter", "positive_numeric_count_given_detection"),
               1.3038, tolerance = 1e-4)
  expect_equal(spot("Surf Scoter", "detection"), 1.0034, tolerance = 1e-4)
  expect_equal(spot("Harlequin Duck", "detection"), 1.1503, tolerance = 1e-4)
})

test_that("multiplicity keys the new contrast into its own family", {
  effects <- data.frame(
    analysis_role = "core_species",
    outcome = "detection",
    contrast = rep(c("did_active_0_14_day", "active_minus_pre_14_day"),
                   each = 10L),
    p_value = rep(seq(0.001, 0.5, length.out = 10L), times = 2L),
    stringsAsFactors = FALSE
  )
  adjusted <- post_stage4a_adjust_multiplicity_v1(effects)
  expect_identical(length(unique(adjusted$multiplicity_family)), 2L)
  expect_true(
    "core_species__detection__active_minus_pre_14_day" %in%
      adjusted$multiplicity_family
  )
  ## Each family is adjusted over its own ten tests, not twenty.
  first <- adjusted$q_value[adjusted$contrast == "did_active_0_14_day"]
  expect_equal(first, stats::p.adjust(effects$p_value[1:10], method = "BH"))
})

test_that("the frozen v1 release directory cannot be overwritten", {
  expect_error(
    .post_stage4a_guard_frozen_outputs_v1(
      "outputs/post_stage4a_sog_event_study_v1"
    ),
    "FROZEN_OUTPUT_GATE"
  )
  expect_true(
    .post_stage4a_guard_frozen_outputs_v1(
      "outputs/post_stage4a_sog_event_study_v1_1"
    )
  )
})

test_that("nAGQ above Laplace is refused for three crossed random effects", {
  expect_error(
    post_stage4a_fit_one_v1(
      data.frame(), "atx", "Bird", "core_species", "detection",
      tempfile(), "signature", NULL, nAGQ = 2L
    ),
    "NAGQ_GATE"
  )
  expect_error(
    post_stage4a_fit_one_v1(
      data.frame(), "atx", "Bird", "core_species", "detection",
      tempfile(), "signature", NULL, nAGQ = -1L
    ),
    "NAGQ_GATE"
  )
})
