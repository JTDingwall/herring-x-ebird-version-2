test_that("v2 invalidation accounts for legacy and exact tracked scopes", {
  manifest <- fread(repo_file("metadata", "stage4a_pooling_v1_invalidation_manifest.csv"))
  expect_setequal(manifest$invalid_column,
                  c("partial_pool_estimate", "partial_pool_standard_error"))
  expect_true(all(manifest$authoritative_finite_row_count == 6562L))
  expect_true(all(manifest$authoritative_family_count == 112L))
  expect_true(all(manifest$superseded_undercount_row_count == 4890L))
  expect_true(all(manifest$superseded_undercount_family_count == 84L))
  expect_true(all(manifest$scope_authority == "HUMAN_ACCEPTED_6562_ROWS_112_FAMILIES"))
  source_path <- repo_file("outputs", "stage4a_results", "effect_estimates.csv")
  expect_true(all(manifest$source_sha256 == digest::digest(
    source_path, algo = "sha256", file = TRUE, serialize = FALSE)))
  source_names <- names(fread(source_path, nrows = 0L))
  expect_setequal(strsplit(manifest$unaffected_columns[1L], "|", fixed = TRUE)[[1L]],
                  setdiff(source_names,
                          c("partial_pool_estimate", "partial_pool_standard_error")))

  effects <- stage4a_pooling_v2_read_effects(
    repo_file("outputs", "stage4a_results", "effect_estimates.csv"),
    character_columns = c("region", "outcome", "contrast"),
    numeric_columns = c("partial_pool_estimate", "partial_pool_standard_error"),
    region_file = repo_file("metadata", "stage4a_region_registry_v2.csv")
  )
  computed <- effects[is.finite(partial_pool_estimate) |
                        is.finite(partial_pool_standard_error)]
  expect_equal(nrow(computed), 6562L)
  expect_equal(computed[region != "NA", .N], 4890L)
  expect_equal(computed[, uniqueN(paste(region, outcome, contrast))], 112L)
  expect_equal(computed[region != "NA",
                        uniqueN(paste(region, outcome, contrast))], 84L)
})

test_that("v2 families vary only along stable unit identity", {
  families <- fread(repo_file("metadata", "stage4a_pooling_family_registry_v2.csv"))
  audit <- fread(repo_file("metadata", "stage4a_pooling_family_compatibility_audit_v2.csv"))
  invariant_counts <- paste0(stage4a_pooling_v2_family_fields(), "_unique_n")
  expect_equal(nrow(families), 162L)
  expect_true(all(families$allowed_pooling_axis == "stable_unit_id"))
  expect_true(all(audit$compatibility_status == "PASS"))
  expect_true(all(as.matrix(audit[, ..invariant_counts]) == 1L))
  expect_true(all(families$component_count >= 2L))
  expect_true(all(families$estimability_status == "ELIGIBLE_MINIMUM_COMPONENT_COUNT"))
})

test_that("component identities are unique and duplicate representations are resolved", {
  evidence <- fread(repo_file("metadata", "stage4a_component_evidence_registry_v2.csv"))
  rows <- fread(repo_file("metadata", "stage4a_pooling_row_disposition_v2.csv"))
  duplicates <- fread(repo_file("metadata", "stage4a_m11_m12_duplicate_resolution_v2.csv"))
  expect_equal(nrow(rows), 6562L)
  expect_equal(rows[legacy_undercount_scope == TRUE, .N], 4890L)
  expect_equal(rows[included_in_future_estimator == TRUE, .N], nrow(evidence))
  expect_equal(rows[included_in_future_estimator == FALSE, .N], nrow(duplicates))
  expect_equal(anyDuplicated(evidence[, .(pooling_family_id_v2, component_evidence_id)]), 0L)
  expect_true(all(duplicates$selected_representation %in% c("M01", "M02")))
  expect_true(all(duplicates$excluded_representation %in% c("M11", "M12")))
  expect_true(all(duplicates$reason_code ==
                    "EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION"))
  expect_setequal(unique(rows$disposition_reason_code),
                  c("INCLUDED_PRIMARY_REPRESENTATION",
                    "EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION"))
})

test_that("typed reader preserves registered NA and fails closed on identity defects", {
  fixture <- tempfile(fileext = ".csv")
  writeLines(c(
    "model_id,region,unit_label,unit_class,outcome,contrast,partial_pool_estimate,partial_pool_standard_error",
    "M01,NA,guild_a,guild,detection,active_near,0.2,0.1",
    "M01,SoG,guild_b,guild,detection,active_near,NA,"
  ), fixture, useBytes = TRUE)
  on.exit(unlink(fixture), add = TRUE)
  read_fixture <- function(path = fixture) stage4a_pooling_v2_read_effects(
    path,
    character_columns = c("model_id", "region", "unit_label", "unit_class",
                          "outcome", "contrast"),
    numeric_columns = c("partial_pool_estimate", "partial_pool_standard_error"),
    region_file = repo_file("metadata", "stage4a_region_registry_v2.csv")
  )
  got <- read_fixture()
  expect_identical(got$region, c("NA", "SoG"))
  expect_false(is.na(got$region[1L]))
  expect_true(is.na(got$partial_pool_estimate[2L]))
  expect_true(is.na(got$partial_pool_standard_error[2L]))
  reordered <- tempfile(fileext = ".csv")
  writeLines(c(readLines(fixture, n = 1L), rev(readLines(fixture)[-1L])), reordered)
  on.exit(unlink(reordered), add = TRUE)
  expect_equal(read_fixture(reordered)[order(model_id, region)],
               got[order(model_id, region)])

  missing <- tempfile(fileext = ".csv")
  writeLines(sub("M01,NA", "M01,", readLines(fixture), fixed = TRUE), missing)
  on.exit(unlink(missing), add = TRUE)
  expect_error(read_fixture(missing), "POOLING_V2_IDENTITY_MISSING")
  bad_region <- tempfile(fileext = ".csv")
  writeLines(sub("M01,NA", "M01,XX", readLines(fixture), fixed = TRUE), bad_region)
  on.exit(unlink(bad_region), add = TRUE)
  expect_error(read_fixture(bad_region), "POOLING_V2_UNREGISTERED_REGION")
})

test_that("M11/M12 precedence follows frozen component lineage only", {
  lineage <- fread(repo_file("metadata", "stage4a_component_lineage_v2.csv"))
  duplicate <- fread(repo_file("metadata", "stage4a_m11_m12_duplicate_resolution_v2.csv"))
  expect_true(all(lineage$lineage_relationship == "exact_copied_hurdle_component"))
  expect_equal(nrow(duplicate), uniqueN(duplicate$duplicate_group_id))
  expected <- lineage[, .(selected_representation, excluded_representation,
                          unit_class, response_state)]
  observed <- unique(duplicate[, .(selected_representation, excluded_representation,
                                   unit_class, response_state)])
  expect_setequal(do.call(paste, expected), do.call(paste, observed))
  production <- paste(readLines(repo_file("R", "stage4a_production.R"), warn = FALSE),
                      collapse = "\n")
  expect_true(grepl("components\\$source_model_id <- components\\$model_id", production))
  expect_true(grepl("components\\$model_id <- ifelse", production))
})

test_that("canonical IDs are deterministic under row reordering and fail closed", {
  families <- fread(repo_file("metadata", "stage4a_pooling_family_registry_v2.csv"))
  fields <- stage4a_pooling_v2_family_fields()
  sample_rows <- families[c(1L, 7L, nrow(families))]
  calculate <- function(tab) vapply(seq_len(nrow(tab)), function(i) {
    stage4a_pooling_v2_id("pf2_", as.list(tab[i, fields, with = FALSE]), fields)
  }, character(1L))
  original <- setNames(calculate(sample_rows), sample_rows$pooling_family_id_v2)
  reordered <- sample_rows[c(3L, 1L, 2L)]
  after <- setNames(calculate(reordered), reordered$pooling_family_id_v2)
  expect_identical(original[sort(names(original))], after[sort(names(after))])
  expect_identical(unname(original), sample_rows$pooling_family_id_v2)
  evidence <- fread(repo_file("metadata", "stage4a_component_evidence_registry_v2.csv"))
  evidence_fields <- stage4a_pooling_v2_evidence_fields()
  evidence_sample <- families[evidence[c(2L, 11L, nrow(evidence))],
                              on = "pooling_family_id_v2"]
  calculate_evidence <- function(tab) vapply(seq_len(nrow(tab)), function(i) {
    stage4a_pooling_v2_id("ce2_", as.list(tab[i, evidence_fields, with = FALSE]),
                          evidence_fields)
  }, character(1L))
  evidence_original <- setNames(calculate_evidence(evidence_sample),
                                evidence_sample$component_evidence_id)
  evidence_reordered <- evidence_sample[c(3L, 1L, 2L)]
  evidence_after <- setNames(calculate_evidence(evidence_reordered),
                             evidence_reordered$component_evidence_id)
  expect_identical(evidence_original[sort(names(evidence_original))],
                   evidence_after[sort(names(evidence_after))])
  expect_identical(unname(evidence_original), evidence_sample$component_evidence_id)
  broken <- as.list(sample_rows[1L, fields, with = FALSE])
  broken[[fields[1L]]] <- ""
  expect_error(stage4a_pooling_v2_id("pf2_", broken, fields),
               "POOLING_V2_IDENTITY_MISSING")
})

test_that("v2 schemas and authorized numeric repair output coexist", {
  schema <- fread(repo_file("metadata", "stage4a_pooling_artifact_schema_v2.csv"))
  required_artifacts <- c(
    "repaired_aggregate_output_v2", "pooling_family_estimates_v2",
    "pooling_family_registry_v2",
    "component_evidence_registry_v2", "v1_to_v2_family_crosswalk",
    "row_level_inclusion_exclusion_audit", "m11_m12_duplicate_resolution_audit",
    "family_compatibility_audit_v2", "invalidation_supersession_manifest",
    "deterministic_execution_record", "output_hash_manifest"
  )
  expect_setequal(unique(schema$artifact), required_artifacts)
  expect_true(file.exists(repo_file("outputs", "stage4a_pooling_repair_v2",
                                    "effect_estimates_v2.csv")))
  spec <- yaml::read_yaml(repo_file("metadata", "stage4a_pooling_repair_spec_v2.yml"))
  expect_identical(spec$status, "frozen_pre_execution_scope_accepted")
  expect_identical(spec$scope$execution_gate, "accepted")
  expect_false(spec$immutability$v1_files_modified)
  expect_false(spec$immutability$protected_data_required)
  expect_identical(spec$estimator_contract$pooled_p_value, "not_produced")
  expect_identical(spec$estimator_contract$pooled_q_value, "not_produced")
  reasons <- fread(repo_file("metadata", "stage4a_pooling_reason_codes_v2.csv"))
  expect_setequal(reasons$reason_code, names(stage4a_pooling_v2_reason_codes()))
})

test_that("specification builder has no response-model or protected-data dependency", {
  code <- paste(readLines(repo_file("scripts", "build_stage4a_pooling_repair_spec_v2.R"),
                          warn = FALSE), collapse = "\n")
  expect_false(grepl("run_stage4a_production|run_stage4a_core_analysis|protected.builder|EBD|SED|2026",
                     code, ignore.case = TRUE))
  expect_true(grepl("no repaired values produced", code, ignore.case = TRUE))
})
