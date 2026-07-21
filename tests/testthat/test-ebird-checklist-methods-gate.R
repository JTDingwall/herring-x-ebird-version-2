testthat::test_that("eBird checklist methods addendum preserves the Stage 2 freeze", {
  testthat::skip_if_not_installed("data.table")
  testthat::skip_if_not_installed("yaml")
  gate <- data.table::fread(repo_file("metadata", "ebird_checklist_handling_gate.csv"))
  plan <- yaml::read_yaml(repo_file("metadata", "stage3_entry_plan.yml"))

  testthat::expect_equal(nrow(gate), 16L)
  testthat::expect_false(anyDuplicated(gate$item_id) > 0L)
  testthat::expect_setequal(gate$status, c("aligned", "verify", "approved"))
  testthat::expect_true(all(c("E05", "E06", "E07", "E10", "E13") %in% gate[severity == "block", item_id]))

  testthat::expect_identical(plan$stage_gate,
                            "PASS_STAGE3_COMPLETE_HUMAN_APPROVED_PHASE4_NOT_AUTHORIZED")
  testthat::expect_identical(plan$human_scientific_decision,
                            "APPROVE_STAGE3_PHASE3_VALIDATION")
  testthat::expect_false(plan$response_models_authorized)
  testthat::expect_true(plan$prospective_holdout_2026_plus_locked)
  testthat::expect_false(plan$stage2_grid_changed)
  testthat::expect_identical(
    plan$stage2_candidate_grid_sha256,
    "8b9ba99dbded84273cb7860d530e09b6b3d50b09603d082e6013742245127a81"
  )
  testthat::expect_false(plan$scope_control$add_new_primary_ecological_covariates)
  testthat::expect_false(plan$upstream_blockers$geometry$blocking)
  testthat::expect_identical(plan$upstream_blockers$geometry$status,
                            "RESOLVED_BY_SOURCE_POINT_ONLY_ANALYSIS")
  testthat::expect_false(plan$shoreline_geometry$registered_for_analysis)
  testthat::expect_true(all(vapply(plan$human_decisions[c(
    "independent_checklist_event", "primary_effort_set", "shared_count_reconciliation",
    "estimand_language"
  )], function(x) identical(x$status, "approved") && !isTRUE(x$blocking), logical(1))))
  testthat::expect_identical(plan$human_decisions$validation_unit$status,
                            "approved")
  testthat::expect_false(plan$human_decisions$validation_unit$blocking)
  testthat::expect_true(plan$stage3_entry_implementation_authorized)
  testthat::expect_false(plan$response_models_authorized)
  testthat::expect_identical(plan$phases[[3L]]$status,
                            "completed_human_approved")
  testthat::expect_identical(plan$phases[[4L]]$status,
                            "completed_human_approved")
  testthat::expect_identical(plan$phases[[5L]]$status,
                            "completed_human_approved")
  testthat::expect_identical(plan$phases[[6L]]$status, "not_authorized")
})

testthat::test_that("checklist gate encodes independent-event and estimand protections", {
  testthat::skip_if_not_installed("data.table")
  gate <- data.table::fread(repo_file("metadata", "ebird_checklist_handling_gate.csv"))

  shared <- gate[item_id == "E05"]
  spatial <- gate[item_id == "E10"]
  estimand <- gate[item_id == "E13"]
  validation <- gate[item_id == "E12"]

  testthat::expect_identical(shared$status, "approved")
  testthat::expect_identical(shared$severity, "block")
  testthat::expect_match(shared$verification_test, "group_identifier", ignore.case = TRUE)
  testthat::expect_identical(spatial$status, "approved")
  testthat::expect_match(spatial$required_action, "2 km", fixed = TRUE)
  testthat::expect_identical(estimand$status, "approved")
  testthat::expect_match(estimand$required_action, "prose", ignore.case = TRUE)
  testthat::expect_identical(validation$status, "approved")
  testthat::expect_identical(validation$severity, "block")
  testthat::expect_match(validation$reported_stage2_state, "Four deterministic event-blocked folds")
})
