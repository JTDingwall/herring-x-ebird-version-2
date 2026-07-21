testthat::test_that("Phase 2 approval and Phase 3 specifications are hash-identical", {
  testthat::skip_if_not_installed("digest")
  pairs <- list(
    c("metadata/stage3_phase2_human_scientific_approval_v1.yml", "metadata/stage3_phase2_human_scientific_approval_v1.sha256"),
    c("metadata/stage3_phase3_blocked_validation_spec_v1.yml", "metadata/stage3_phase3_blocked_validation_spec_v1.sha256"),
    c("metadata/stage3_estimand_safeguards_v1.yml", "metadata/stage3_estimand_safeguards_v1.sha256"),
    c("metadata/stage3_phase3_execution_v1.yml", "metadata/stage3_phase3_execution_v1.sha256"),
    c("metadata/stage3_phase3_human_scientific_approval_v1.yml", "metadata/stage3_phase3_human_scientific_approval_v1.sha256"),
    c("docs/13_STAGE3_PHASE3_BLOCKED_VALIDATION_METHODS.md", "docs/13_STAGE3_PHASE3_BLOCKED_VALIDATION_METHODS.sha256"),
    c("outputs/stage3_phase3_validation/aggregate_artifact_hashes.csv", "outputs/stage3_phase3_validation/aggregate_artifact_hashes.csv.sha256")
  )
  for (pair in pairs) {
    artifact <- do.call(repo_file, as.list(strsplit(pair[1L], "/", fixed = TRUE)[[1L]]))
    sidecar <- do.call(repo_file, as.list(strsplit(pair[2L], "/", fixed = TRUE)[[1L]]))
    recorded <- strsplit(readLines(sidecar, warn = FALSE)[1L], "[[:space:]]+")[[1L]][1L]
    testthat::expect_identical(recorded,
      digest::digest(artifact, algo = "sha256", file = TRUE, serialize = FALSE))
  }
})

testthat::test_that("Phase 3 event-blocked gate preserves grain and access boundaries", {
  testthat::skip_if_not_installed("jsonlite")
  testthat::skip_if_not_installed("yaml")
  summary <- jsonlite::fromJSON(repo_file("outputs", "stage3_phase3_validation", "phase3_execution_summary.json"))
  execution <- yaml::read_yaml(repo_file("metadata", "stage3_phase3_execution_v1.yml"))
  plan <- yaml::read_yaml(repo_file("metadata", "stage3_entry_plan.yml"))
  safeguards <- yaml::read_yaml(repo_file("metadata", "stage3_estimand_safeguards_v1.yml"))
  approval <- yaml::read_yaml(repo_file("metadata", "stage3_phase3_human_scientific_approval_v1.yml"))

  testthat::expect_equal(summary$primary_linked_independent_checklists, 239934L)
  testthat::expect_true(summary$concurrent_metadata_links > summary$primary_linked_independent_checklists)
  testthat::expect_equal(summary$protected_event_blocks, 308L)
  testthat::expect_false(summary$preferred_five_fold_support_pass)
  testthat::expect_equal(summary$chosen_event_blocked_folds, 4L)
  testthat::expect_true(summary$chosen_folds_primary_and_candidate_primary_scopes_pass)
  testthat::expect_equal(summary$event_block_leakage, 0L)
  testthat::expect_equal(summary$herring_source_event_leakage, 0L)
  testthat::expect_equal(summary$independent_checklist_leakage, 0L)
  testthat::expect_equal(summary$shared_group_leakage, 0L)
  testthat::expect_equal(summary$concurrent_link_fold_disagreements, 0L)
  testthat::expect_equal(summary$ebd_scans, 0L)
  testthat::expect_equal(summary$sparse_bird_tables_read, 0L)
  testthat::expect_equal(summary$bird_response_fields_read, 0L)
  testthat::expect_equal(summary$comments_read, 0L)
  testthat::expect_equal(summary$shoreline_fields_read, 0L)
  testthat::expect_equal(summary$records_2026_plus_read, 0L)
  testthat::expect_false(summary$denominator_expanded)
  testthat::expect_false(summary$response_models_fit)
  testthat::expect_false(summary$phase_4_started)
  testthat::expect_false(execution$phase_4_started)
  testthat::expect_true(safeguards$sampling_unit$concurrent_links_may_not_multiply_independent_rows)
  testthat::expect_identical(plan$phases[[4L]]$status, "completed_human_approved")
  testthat::expect_identical(plan$phases[[5L]]$status, "completed_human_approved")
  testthat::expect_identical(plan$phases[[6L]]$status, "not_authorized")
  testthat::expect_identical(approval$approved_commit,
    "daae8a2958d7e0f20e5bc91d05dc368efdafa515")
  testthat::expect_identical(approval$scientific_decision,
    "APPROVE_STAGE3_PHASE3_VALIDATION")
  testthat::expect_equal(approval$validation_design$deterministic_event_blocked_folds, 4L)
  testthat::expect_false(approval$validation_design$five_folds_forced)
  testthat::expect_identical(approval$validation_design$primary_view, "event_blocked")
  testthat::expect_false(approval$validation_design$observer_disjoint_view$new_herring_event_generalization_claim_authorized)
  testthat::expect_identical(approval$heldout_prediction_rule$observer_random_effect,
    "marginalize_or_set_to_population_level_expectation")
  testthat::expect_identical(approval$heldout_prediction_rule$generalized_location_random_effect,
    "marginalize_or_set_to_population_level_expectation")
  testthat::expect_false(approval$heldout_prediction_rule$learned_conditional_random_effects_allowed)
  testthat::expect_false(approval$heldout_prediction_rule$blups_allowed)
  testthat::expect_identical(unlist(approval$prospective_confirmation$locked_years), 2026:2028)
  testthat::expect_false(approval$phase_transition$phase_4_authorized)
  testthat::expect_false(approval$response_boundary$bird_response_summaries_authorized)
})

testthat::test_that("event and observer validation views satisfy their leakage targets", {
  testthat::skip_if_not_installed("data.table")
  balance <- data.table::fread(repo_file("outputs", "stage3_phase3_validation", "fold_balance.csv"), na.strings = "")
  leakage <- data.table::fread(repo_file("outputs", "stage3_phase3_validation", "leakage_and_overlap_audit.csv"), na.strings = "")
  feasibility <- data.table::fread(repo_file("outputs", "stage3_phase3_validation", "fold_count_feasibility.csv"), na.strings = "")

  testthat::expect_equal(nrow(balance), 32L)
  testthat::expect_setequal(unique(balance$fold), 1:4)
  testthat::expect_true(all(balance[validation_view == "event_blocked" & region %in% c("SoG", "WCVI"), registered_minimum_support_pass]))
  testthat::expect_true(all(leakage[validation_view == "event_blocked",
    event_block_overlap == 0L & herring_source_event_overlap == 0L &
    independent_checklist_overlap == 0L & shared_group_overlap == 0L &
    concurrent_link_fold_disagreements == 0L]))
  testthat::expect_true(all(leakage[validation_view == "observer_robustness",
    observer_cluster_overlap == 0L & independent_checklist_overlap == 0L &
    shared_group_overlap == 0L]))
  testthat::expect_true(all(feasibility[candidate_folds == 5L & region %in% c("SoG", "WCVI"), all_folds_pass]))
  testthat::expect_false(feasibility[candidate_folds == 5L & region == "CC", all_folds_pass])
  testthat::expect_true(feasibility[candidate_folds == 4L & region == "CC", all_folds_pass])
  testthat::expect_false(feasibility[candidate_folds == 4L & region == "NA", all_folds_pass])
})

testthat::test_that("WCVI decision requires observer-robustness sensitivity", {
  testthat::skip_if_not_installed("data.table")
  wcvi <- data.table::fread(repo_file("outputs", "stage3_phase3_validation", "wcvi_observer_concentration_decision.csv"), na.strings = "")
  testthat::expect_equal(nrow(wcvi), 1L)
  testthat::expect_true(wcvi$event_blocked_all_folds_pass)
  testthat::expect_equal(wcvi$event_blocked_folds, 4L)
  testthat::expect_equal(wcvi$dominant_observer_share_pooled, 0.356)
  testthat::expect_equal(wcvi$effective_observer_replication_pooled, 7.4)
  testthat::expect_equal(wcvi$checklists_after_dominant_holdout, 5529L)
  testthat::expect_true(wcvi$dominant_holdout_support_pass)
  testthat::expect_identical(wcvi$decision,
    "candidate_primary_with_observer_robustness_sensitivity_required")
  testthat::skip_if_not_installed("yaml")
  approval <- yaml::read_yaml(repo_file("metadata", "stage3_phase3_human_scientific_approval_v1.yml"))
  requirements <- approval$regional_decisions$WCVI$required_reporting
  testthat::expect_true(all(unlist(requirements)))
  testthat::expect_false(approval$regional_decisions$WCVI$observer_warning_automatic_demotion)
  testthat::expect_identical(approval$regional_decisions$SoG$role, "primary")
  testthat::expect_identical(approval$regional_decisions$CC$role,
    "hierarchical_and_descriptive_only")
  testthat::expect_false(approval$regional_decisions[["NA"]]$unsupported_cell_blocks_SoG_or_WCVI)
  testthat::expect_false(approval$regional_decisions[["NA"]]$unsupported_cell_may_upgrade_NA)
})

testthat::test_that("Phase 3 aggregates suppress small cells and release no protected schema", {
  testthat::skip_if_not_installed("data.table")
  balance <- data.table::fread(repo_file("outputs", "stage3_phase3_validation", "fold_balance.csv"), na.strings = "")
  strata <- data.table::fread(repo_file("outputs", "stage3_phase3_validation", "fold_stratum_balance.csv"), na.strings = "")
  testthat::expect_true(all(is.na(balance[suppressed_below_20 == TRUE, independent_checklists])))
  testthat::expect_true(all(is.na(strata[suppressed_below_20 == TRUE, independent_checklists])))
  prohibited <- c("analysis_event_token", "observer_cluster_token", "location_cluster_token",
    "herring_source_token", "sampling_event_identifier", "locality_id", "latitude", "longitude")
  for (file in c("fold_balance.csv", "fold_count_feasibility.csv",
                 "fold_stratum_balance.csv", "leakage_and_overlap_audit.csv",
                 "observer_robustness_summary.csv", "wcvi_observer_concentration_decision.csv")) {
    tab <- data.table::fread(repo_file("outputs", "stage3_phase3_validation", file), na.strings = "")
    testthat::expect_length(intersect(tolower(names(tab)), prohibited), 0L)
  }
  code <- paste(readLines(repo_file("scripts", "Stage3Phase3BlockedValidation.cs"), warn = FALSE), collapse = "\n")
  testthat::expect_false(grepl("reported_count_states|ambiguity_masks|OBSERVATION COUNT|TAXON CONCEPT ID", code))
})

testthat::test_that("Phase 3 aggregate hash manifest matches every listed artifact", {
  testthat::skip_if_not_installed("data.table")
  testthat::skip_if_not_installed("digest")
  hashes <- data.table::fread(repo_file("outputs", "stage3_phase3_validation", "aggregate_artifact_hashes.csv"), na.strings = "")
  testthat::expect_true(all(hashes$status == "PASS" & hashes$reproducible))
  for (i in seq_len(nrow(hashes))) {
    path <- repo_file("outputs", "stage3_phase3_validation", hashes$artifact[i])
    testthat::expect_identical(digest::digest(path, algo = "sha256", file = TRUE,
      serialize = FALSE), hashes$sha256[i])
  }
})
