testthat::test_that("Stage 3 Phase 1 aggregate gates are complete and scoped", {
  testthat::skip_if_not_installed("data.table")
  testthat::skip_if_not_installed("jsonlite")
  testthat::skip_if_not_installed("yaml")

  gates <- data.table::fread(repo_file("outputs", "stage3_phase1", "phase1_gate_summary.csv"))
  summary <- jsonlite::fromJSON(repo_file("outputs", "stage3_phase1", "denominator_summary.json"))
  execution <- yaml::read_yaml(repo_file("metadata", "stage3_phase1_execution_v1.yml"))
  plan <- yaml::read_yaml(repo_file("metadata", "stage3_entry_plan.yml"))

  testthat::expect_identical(gates$check_id, sprintf("Q%02d", 1:9))
  testthat::expect_true(all(gates$status == "PASS"))
  testthat::expect_identical(summary$status, "PASS_STAGE3_PHASE1")
  testthat::expect_identical(summary$zero_provenance_gate,
                             "PASS_ELIGIBLE_COMPLETE_VERIFIED_EVENT_OMISSION_ONLY")
  testthat::expect_equal(summary$denominator_event_taxon_rows,
                         summary$independent_eligible_checklist_events *
                           summary$registered_analysis_taxa)
  testthat::expect_equal(summary$holdout_records_selected, 0)
  testthat::expect_equal(summary$free_text_fields_selected, 0)
  testthat::expect_equal(summary$herring_fields_selected, 0)
  testthat::expect_equal(summary$shoreline_fields_selected, 0)
  testthat::expect_false(summary$geometry_analysis_or_sensitivity_run)
  testthat::expect_false(summary$bird_response_summary_or_model_run)
  testthat::expect_identical(summary$reproducibility_check,
                             "PASS_BYTE_IDENTICAL_REPLAY")
  testthat::expect_identical(execution$phase, "phase_1")
  testthat::expect_false(execution$phase_2_started)
  testthat::expect_identical(plan$phases[[3L]]$status,
    "executed_pending_human_denominator_and_zero_provenance_review")
  testthat::expect_identical(plan$phases[[4L]]$status, "authorized_not_yet_executed")
})

testthat::test_that("Phase 1 specification and execution records match their hashes", {
  testthat::skip_if_not_installed("digest")
  for (stem in c("stage3_phase1_denominator_spec", "stage3_phase1_execution_v1")) {
    artifact <- repo_file("metadata", paste0(stem, ".yml"))
    sidecar <- repo_file("metadata", paste0(stem, ".sha256"))
    recorded <- strsplit(readLines(sidecar, warn = FALSE)[1L], "[[:space:]]+")[[1L]][1L]
    actual <- digest::digest(artifact, algo = "sha256", file = TRUE, serialize = FALSE)
    testthat::expect_identical(recorded, actual)
  }
})

testthat::test_that("Phase 1 count-state rows reconcile to the denominator", {
  testthat::skip_if_not_installed("data.table")
  testthat::skip_if_not_installed("jsonlite")
  states <- data.table::fread(repo_file("outputs", "stage3_phase1", "count_state_provenance.csv"))
  summary <- jsonlite::fromJSON(repo_file("outputs", "stage3_phase1", "denominator_summary.json"))
  testthat::expect_setequal(states$count_type,
    c("numeric", "X", "lower_bound", "missing", "ambiguity_affected", "zero_filled"))
  testthat::expect_equal(sum(states$rows), summary$denominator_event_taxon_rows)
  testthat::expect_equal(states[count_type == "zero_filled", rows], summary$zero_filled_rows)
})
