test_that("publication sensitivity v2 freezes matched model mappings before execution", {
  spec <- yaml::read_yaml(repo_file("metadata", "stage4a_publication_sensitivity_spec_v2.yml"))
  map <- fread(repo_file("metadata", "stage4a_publication_sensitivity_model_map_v2.csv"))
  expect_identical(spec$status, "PRE_EXECUTION_FROZEN_NO_PROTECTED_INPUT_READ")
  expect_identical(spec$parent_main_commit,
                   "aea6cd7fb1a8b29059e4af2a6709cbf3a3756906")
  expect_equal(unlist(spec$scope$years), c(2005L, 2025L))
  expect_false(spec$scope$protected_rows_may_be_committed)
  expect_identical(spec$scope$records_2026_plus, "prohibited")
  expect_setequal(map$model_version_id, c(
    "M01_PRIMARY_v2", "M27_v2", "M28_v2", "S4A12_WCVI_2KM_v2",
    "S4A11_WCVI_DOMINANT_OBSERVER_v2"
  ))
  expect_true(all(map$matched_primary_model_id == "M01"))
  expect_true(all(map$unit_selector == "all_8_frozen_primary_guilds"))
  expect_true(all(map$response_states ==
    "detection|positive_numeric_count_given_detection"))
  expect_true(all(map$fit_architecture ==
                  "sparse_M01_glmer_lmer_three_random_intercepts"))
  expect_identical(spec$matched_primary_contract$simplified_glm_fallback, "prohibited")
  expect_identical(spec$matched_primary_contract$engine$detection, "lme4_glmer_sparse")
  expect_identical(spec$matched_primary_contract$engine$positive_count,
                   "lme4_lmer_sparse")
  expect_false(spec$engine_amendment$formula_estimand_cohort_and_random_intercepts_changed)
  expect_false(spec$engine_amendment$response_direction_or_sign_used)
})

test_that("publication placebo contract moves the complete bundle without responses", {
  spec <- yaml::read_yaml(repo_file("metadata", "stage4a_publication_sensitivity_spec_v2.yml"))
  expected <- c("active_reference_class", "active_near", "contemporaneous_reference",
    "concurrent_links", "time_early_pre", "time_immediate_pre", "time_spawn_start", "time_early_egg",
    "time_late_egg", "time_post", "distance_ring_0_0p5", "distance_ring_0p5_1",
    "distance_ring_1_2", "distance_ring_2_3", "distance_ring_3_4",
    "distance_ring_4_5", "distance_ring_5_10", "distance_ring_10_20")
  expect_setequal(unlist(spec$placebo_contract$bundle_fields), expected)
  expect_setequal(unlist(spec$placebo_contract$strata), c("region", "checklist_year"))
  expect_identical(spec$placebo_contract$M27_v2$seed, 10007L)
  expect_identical(spec$placebo_contract$M28_v2$seed, 20011L)
  expect_identical(spec$placebo_contract$response_access_during_transformation,
                   "prohibited")
})

test_that("M26 is retired and release schemas exclude protected identities", {
  spec <- yaml::read_yaml(repo_file("metadata", "stage4a_publication_sensitivity_spec_v2.yml"))
  disposition <- fread(repo_file("metadata", "stage4a_publication_model_disposition_v2.csv"),
                       na.strings = NULL)
  schema <- fread(repo_file("metadata", "stage4a_publication_sensitivity_output_schema_v2.csv"))
  expect_identical(spec$M26$v1_status, "RETIRED_FROM_INFERENTIAL_PUBLICATION_SET")
  expect_identical(spec$M26$replacement, "none")
  expect_identical(disposition[historical_model_id == "M26", publication_disposition],
                   "retired_from_inferential_publication_set")
  forbidden <- c("analysis_event_token", "event_block_token", "observer_cluster_token",
                 "location_cluster_token", "latitude", "longitude", "checklist_id")
  expect_false(any(schema$field %in% forbidden))
  expect_true(all(schema$privacy_rule != "protected_row"))
})
