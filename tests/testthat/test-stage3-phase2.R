testthat::test_that("Phase 1 human approval and Phase 2 records are hash-identical", {
  testthat::skip_if_not_installed("digest")
  pairs <- list(
    c("metadata/stage3_phase1_human_scientific_approval_v2.yml", "metadata/stage3_phase1_human_scientific_approval_v2.sha256"),
    c("metadata/stage3_phase2_sampling_support_spec_v1.yml", "metadata/stage3_phase2_sampling_support_spec_v1.sha256"),
    c("metadata/stage3_phase2_execution_v1.yml", "metadata/stage3_phase2_execution_v1.sha256"),
    c("docs/12_STAGE3_PHASE2_SAMPLING_SUPPORT_AUDIT.md", "docs/12_STAGE3_PHASE2_SAMPLING_SUPPORT_AUDIT.sha256"),
    c("outputs/stage3_phase2_sampling_support/aggregate_artifact_hashes.csv", "outputs/stage3_phase2_sampling_support/aggregate_artifact_hashes.csv.sha256")
  )
  for (pair in pairs) {
    artifact <- do.call(repo_file, as.list(strsplit(pair[1L], "/", fixed = TRUE)[[1L]]))
    sidecar <- do.call(repo_file, as.list(strsplit(pair[2L], "/", fixed = TRUE)[[1L]]))
    recorded <- strsplit(readLines(sidecar, warn = FALSE)[1L], "[[:space:]]+")[[1L]][1L]
    actual <- digest::digest(artifact, algo = "sha256", file = TRUE, serialize = FALSE)
    testthat::expect_identical(recorded, actual)
  }
})

testthat::test_that("Phase 2 reuses the approved factor and preserves the response boundary", {
  testthat::skip_if_not_installed("jsonlite")
  testthat::skip_if_not_installed("yaml")
  summary <- jsonlite::fromJSON(repo_file("outputs", "stage3_phase2_sampling_support", "phase2_execution_summary.json"))
  execution <- yaml::read_yaml(repo_file("metadata", "stage3_phase2_execution_v1.yml"))
  approval <- yaml::read_yaml(repo_file("metadata", "stage3_phase1_human_scientific_approval_v2.yml"))
  plan <- yaml::read_yaml(repo_file("metadata", "stage3_entry_plan.yml"))

  testthat::expect_identical(approval$approved_commit, "1741b02cb539f7721ac8d3e85415b302c15e2a3d")
  testthat::expect_identical(approval$scientific_decision,
    "APPROVE_REPAIRED_STAGE3_PHASE1_DENOMINATOR_AND_ZERO_PROVENANCE_GATE")
  testthat::expect_equal(summary$phase1_factor_events_reused, 1433786L)
  testthat::expect_equal(summary$candidate_primary_events, 1433786L)
  testthat::expect_true(summary$high_spatial_precision_events < summary$candidate_primary_events)
  testthat::expect_true(summary$candidate_primary_events < summary$registered_broad_events)
  testthat::expect_equal(summary$bird_response_fields_selected, 0L)
  testthat::expect_equal(summary$sparse_bird_tables_read, 0L)
  testthat::expect_equal(summary$sed_comments_selected, 0L)
  testthat::expect_equal(summary$shoreline_fields_selected, 0L)
  testthat::expect_equal(summary$records_2026_plus_selected, 0L)
  testthat::expect_false(summary$bird_response_summary_or_model_run)
  testthat::expect_false(summary$phase_3_started)
  testthat::expect_false(execution$phase_3_started)
  testthat::expect_identical(plan$phases[[3L]]$status, "completed_human_approved")
  testthat::expect_identical(plan$phases[[4L]]$status, "completed_human_approved")
  testthat::expect_identical(plan$phases[[5L]]$status,
    "executed_pending_human_validation_review")
  testthat::expect_identical(plan$next_gate, "human_stage3_phase3_validation_review")
})

testthat::test_that("Phase 2 aggregate cardinalities and recommendations reconcile", {
  testthat::skip_if_not_installed("data.table")
  retention <- data.table::fread(repo_file("outputs", "stage3_phase2_sampling_support", "frame_period_retention.csv"))
  region <- data.table::fread(repo_file("outputs", "stage3_phase2_sampling_support", "region_period_support.csv"))
  recs <- data.table::fread(repo_file("outputs", "stage3_phase2_sampling_support", "sampling_support_recommendations.csv"))

  testthat::expect_equal(nrow(retention), 12L)
  full <- retention[period_id == "complete_1988_2025"]
  testthat::expect_equal(full[effort_frame == "candidate_primary", independent_eligible_events], 1433786L)
  testthat::expect_equal(full[effort_frame == "high_spatial_precision", independent_eligible_events], 1158032L)
  testthat::expect_equal(full[effort_frame == "registered_broad", independent_eligible_events], 1579856L)
  testthat::expect_equal(full[effort_frame == "candidate_primary", source_point_linked_events], 239934L)
  testthat::expect_equal(full[effort_frame == "registered_broad", source_point_linked_events], 261494L)
  testthat::expect_true(all(retention$independent_eligible_events >= retention$source_point_linked_events))
  testthat::expect_setequal(unique(recs$recommendation), c(
    "retain as primary", "retain as targeted sensitivity",
    "descriptive/hierarchical only", "unsupported"
  ))
  primary_pass <- region[effort_frame == "candidate_primary" & period_support_pass == TRUE]
  testthat::expect_setequal(primary_pass$region, c("SoG", "WCVI"))
  testthat::expect_true(all(primary_pass[region == "SoG", start_year] >= 2005L))
  testthat::expect_identical(primary_pass[region == "WCVI", period_id], "start_2015")
  testthat::expect_equal(nrow(region[effort_frame == "registered_broad" & recommendation == "broaden"]), 0L)
})

testthat::test_that("Phase 2 privacy suppression and tracked schemas are safe", {
  testthat::skip_if_not_installed("data.table")
  region <- data.table::fread(repo_file("outputs", "stage3_phase2_sampling_support", "region_period_support.csv"))
  strata <- data.table::fread(repo_file("outputs", "stage3_phase2_sampling_support", "event_time_distance_support.csv"))
  testthat::expect_true(all(is.na(region[suppressed_below_20 == TRUE, independent_linked_events])))
  testthat::expect_true(all(is.na(strata[suppressed_below_20 == TRUE, independent_events])))
  prohibited_columns <- c("sampling_event_identifier", "observer_id", "locality_id",
    "latitude", "longitude", "exact_coordinate")
  testthat::expect_length(intersect(tolower(names(region)), prohibited_columns), 0L)
  testthat::expect_length(intersect(tolower(names(strata)), prohibited_columns), 0L)
  implementation <- paste(readLines(repo_file("scripts", "Stage3Phase2SupportAudit.cs"), warn = FALSE), collapse = "\n")
  testthat::expect_false(grepl("reported_count_states\\.tsv|ambiguity_masks\\.tsv", implementation, ignore.case = TRUE))
  testthat::expect_false(grepl("OBSERVATION COUNT|TAXON CONCEPT ID|CHECKLIST COMMENTS", implementation, fixed = FALSE))
})

testthat::test_that("Phase 2 aggregate hash manifest matches every listed artifact", {
  testthat::skip_if_not_installed("data.table")
  testthat::skip_if_not_installed("digest")
  hashes <- data.table::fread(repo_file("outputs", "stage3_phase2_sampling_support", "aggregate_artifact_hashes.csv"))
  testthat::expect_true(all(hashes$status == "PASS" & hashes$reproducible))
  for (i in seq_len(nrow(hashes))) {
    path <- repo_file("outputs", "stage3_phase2_sampling_support", hashes$artifact[i])
    testthat::expect_identical(digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE), hashes$sha256[i])
  }
})
