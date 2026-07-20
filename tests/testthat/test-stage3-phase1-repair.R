testthat::test_that("repaired denominator registry reconciles all frozen Stage 2 taxa", {
  testthat::skip_if_not_installed("data.table")
  registry <- data.table::fread(repo_file("metadata", "canonical_species_registry.csv"))
  support <- data.table::fread(repo_file("outputs", "stage2_design_lock", "species_support_summary.csv"))
  taxonomy <- data.table::fread(repo_file("outputs", "stage2_design_lock", "species_taxonomy_reconciliation.csv"))
  crosswalk <- data.table::fread(repo_file("metadata", "source_taxonomy_crosswalk.csv"))
  ambiguity <- data.table::fread(repo_file("metadata", "ambiguous_taxon_rules.csv"))
  audit <- data.table::fread(repo_file("outputs", "stage3_phase1_repair", "registry_reconciliation_audit.csv"))

  included <- registry[phase1_denominator_included == TRUE]
  testthat::expect_equal(nrow(registry), 58L)
  testthat::expect_equal(nrow(included), 58L)
  testthat::expect_setequal(included$analysis_taxon_id, support$analysis_taxon_id)
  testthat::expect_setequal(included$analysis_taxon_id, taxonomy$analysis_taxon_id)
  testthat::expect_true(all(taxonomy$exact_species_concept_reconciled))
  testthat::expect_true(all(taxonomy$recommended_taxonomy_disposition ==
    "approve_exact_v2025_species_concept"))

  identity <- crosswalk[approval_status == "approved" & mapping_treatment == "candidate_identity"]
  testthat::expect_equal(nrow(identity), 58L)
  testthat::expect_false(anyDuplicated(identity$analysis_taxon_id) > 0L)
  testthat::expect_true(all(identity$final_mapping_decision %in% c(
    "approved_current_species_identity", "approve_exact_v2025_species_concept")))
  testthat::expect_equal(nrow(audit), 58L)
  testthat::expect_true(all(audit$denominator_included))
  testthat::expect_true(all(audit$exact_species_concept_reconciled))
  testthat::expect_true(all(audit$source_mapping_treatment == "candidate_identity"))
  testthat::expect_true(all(audit$source_mapping_decision %in% c(
    "approved_current_species_identity", "approve_exact_v2025_species_concept")))
  testthat::expect_true(all(ambiguity$affected_analysis_taxon_id %in% included$analysis_taxon_id))
})

testthat::test_that("model cardinality cannot be substituted for taxon cardinality", {
  testthat::skip_if_not_installed("data.table")
  registry <- data.table::fread(repo_file("metadata", "canonical_species_registry.csv"))
  models <- data.table::fread(repo_file("metadata", "model_registry.csv"))
  taxon_cardinality <- nrow(registry[phase1_denominator_included == TRUE])
  model_cardinality <- nrow(models)
  testthat::expect_equal(taxon_cardinality, 58L)
  testthat::expect_equal(model_cardinality, 45L)
  testthat::expect_false(identical(taxon_cardinality, model_cardinality))
})

testthat::test_that("repaired Phase 1 factorization and logical cardinality pass", {
  testthat::skip_if_not_installed("data.table")
  testthat::skip_if_not_installed("jsonlite")
  summary <- jsonlite::fromJSON(repo_file("outputs", "stage3_phase1_repair", "denominator_summary.json"))
  states <- data.table::fread(repo_file("outputs", "stage3_phase1_repair", "count_state_provenance.csv"))
  gates <- data.table::fread(repo_file("outputs", "stage3_phase1_repair", "phase1_gate_summary.csv"))

  testthat::expect_true(all(gates$status == "PASS"))
  testthat::expect_identical(summary$denominator_representation, "factorized_sparse")
  testthat::expect_true(summary$species_specific_zeros_generated_at_extraction)
  testthat::expect_equal(summary$registered_analysis_taxa, 58L)
  testthat::expect_equal(summary$denominator_event_taxon_rows,
    summary$independent_eligible_checklist_events * summary$registered_analysis_taxa)
  if (summary$independent_eligible_checklist_events == 1433786L) {
    testthat::expect_equal(summary$denominator_event_taxon_rows, 83159588L)
  }
  testthat::expect_equal(sum(states$rows), summary$denominator_event_taxon_rows)
  testthat::expect_identical(summary$zero_provenance_gate,
    "PASS_ELIGIBLE_COMPLETE_VERIFIED_EVENT_OMISSION_ONLY")
  testthat::expect_equal(summary$holdout_records_selected, 0L)
  testthat::expect_equal(summary$free_text_fields_selected, 0L)
  testthat::expect_equal(summary$herring_fields_selected, 0L)
  testthat::expect_equal(summary$shoreline_fields_selected, 0L)
  testthat::expect_false(summary$geometry_analysis_or_sensitivity_run)
  testthat::expect_false(summary$bird_response_summary_or_model_run)
})

testthat::test_that("registry, frozen inputs, repair audit, spec, and execution hashes match", {
  testthat::skip_if_not_installed("digest")
  pairs <- list(
    c("metadata/canonical_species_registry.csv", "metadata/canonical_species_registry.csv.sha256"),
    c("metadata/source_taxonomy_crosswalk.csv", "metadata/source_taxonomy_crosswalk.csv.sha256"),
    c("metadata/ambiguous_taxon_rules.csv", "metadata/ambiguous_taxon_rules.csv.sha256"),
    c("outputs/stage2_design_lock/species_support_summary.csv", "outputs/stage2_design_lock/species_support_summary.csv.sha256"),
    c("outputs/stage2_design_lock/species_taxonomy_reconciliation.csv", "outputs/stage2_design_lock/species_taxonomy_reconciliation.csv.sha256"),
    c("outputs/stage3_phase1_repair/registry_reconciliation_audit.csv", "outputs/stage3_phase1_repair/registry_reconciliation_audit.csv.sha256"),
    c("metadata/stage3_phase1_denominator_repair_v2.yml", "metadata/stage3_phase1_denominator_repair_v2.sha256"),
    c("metadata/stage3_phase1_execution_v2.yml", "metadata/stage3_phase1_execution_v2.sha256")
  )
  for (pair in pairs) {
    artifact <- do.call(repo_file, as.list(strsplit(pair[1L], "/", fixed = TRUE)[[1L]]))
    sidecar <- do.call(repo_file, as.list(strsplit(pair[2L], "/", fixed = TRUE)[[1L]]))
    recorded <- strsplit(readLines(sidecar, warn = FALSE)[1L], "[[:space:]]+")[[1L]][1L]
    actual <- digest::digest(artifact, algo = "sha256", file = TRUE, serialize = FALSE)
    testthat::expect_identical(recorded, actual)
  }
})

testthat::test_that("45-taxon artifact is explicitly superseded and preserved", {
  testthat::skip_if_not_installed("data.table")
  history <- data.table::fread(repo_file("metadata", "stage3_phase1_artifact_history.csv"))
  old <- history[artifact_version == "stage3_phase1_execution_v1"]
  testthat::expect_equal(nrow(old), 1L)
  testthat::expect_identical(old$status, "superseded_blocking_registry_consistency_failure")
  testthat::expect_equal(old$registered_analysis_taxa, 45L)
  testthat::expect_identical(old$protected_primary_sha256,
    "c46c4a238ead07ee56b214594fa15e1478883398957ef850647464f17e06e9e3")
  testthat::expect_true(file.exists(repo_file("metadata", "stage3_phase1_execution_v1.yml")))
  testthat::expect_true(file.exists(repo_file("metadata", "stage3_phase1_execution_v1.sha256")))
})
