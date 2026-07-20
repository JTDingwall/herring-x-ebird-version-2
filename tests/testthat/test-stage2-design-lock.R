testthat::test_that("Stage 2 candidate grid is frozen before support access", {
  testthat::skip_if_not_installed("data.table")
  testthat::skip_if_not_installed("digest")
  grid_path <- repo_file("metadata", "stage2_candidate_design_grid.csv")
  hash_path <- repo_file("metadata", "stage2_candidate_design_grid.sha256")
  grid <- data.table::fread(grid_path)
  recorded <- strsplit(readLines(hash_path, warn = FALSE)[1L], "[[:space:]]+")[[1L]][1L]
  actual <- digest::digest(grid_path, algo = "sha256", file = TRUE, serialize = FALSE)
  testthat::expect_identical(recorded, actual)
  testthat::expect_equal(nrow(grid), 105L)
  testthat::expect_equal(data.table::uniqueN(grid, by = c("dimension", "candidate_id")), 105L)
  testthat::expect_setequal(unique(grid$dimension), c("temporal_window", "event_date_representation", "distance", "event_complex", "geometry",
                                                        "region_period", "protocol_effort", "species_guild_eligibility", "count_state", "cooccurrence_eligibility"))
  amendment_path <- repo_file("metadata", "stage2_scientific_gate_amendment_v1.yml")
  amendment_recorded <- strsplit(readLines(repo_file("metadata", "stage2_scientific_gate_amendment_v1.sha256"), warn = FALSE)[1L], "[[:space:]]+")[[1L]][1L]
  amendment_actual <- digest::digest(amendment_path, algo = "sha256", file = TRUE, serialize = FALSE)
  testthat::expect_identical(amendment_recorded, amendment_actual)
  amendment <- yaml::read_yaml(amendment_path)
  testthat::expect_true(amendment$parent_candidate_grid$preserved_unchanged)
  approval_path <- repo_file("metadata", "stage2_human_scientific_approval_v1.yml")
  approval_recorded <- strsplit(readLines(repo_file("metadata", "stage2_human_scientific_approval_v1.sha256"), warn = FALSE)[1L], "[[:space:]]+")[[1L]][1L]
  approval_actual <- digest::digest(approval_path, algo = "sha256", file = TRUE, serialize = FALSE)
  testthat::expect_identical(approval_recorded, approval_actual)
  approval <- yaml::read_yaml(approval_path)
  testthat::expect_identical(approval$scientific_decision, "APPROVED_SOURCE_POINT_PRIMARY")
  testthat::expect_false(approval$response_boundary$stage3_response_models_authorized)
  testthat::expect_true(approval$parent_design$preserved_unchanged)
  testthat::expect_identical(amendment$parent_candidate_grid$canonical_lf_sha256, recorded)
  testthat::expect_identical(amendment$parent_candidate_grid$original_windows_crlf_sha256,
                            "f7e5e9df7a96e1fff82a66734371fc427d70d8d6bbb2b4725409aa94475e7f91")
})

testthat::test_that("Stage 2 registries prevent duplicate guild totals and retain all models", {
  guild <- data.table::fread(repo_file("metadata", "species_primary_guild.csv"))
  traits <- data.table::fread(repo_file("metadata", "species_mechanism_traits.csv"))
  mult <- data.table::fread(repo_file("metadata", "hypothesis_model_multiplicity_registry.csv"))
  testthat::expect_equal(nrow(guild), 58L)
  testthat::expect_false(anyDuplicated(guild$analysis_taxon_id) > 0L)
  testthat::expect_false(any(grepl("[|;]", guild$primary_guild_id)))
  testthat::expect_true(all(!guild$duplicate_in_primary_totals))
  testthat::expect_equal(nrow(traits), 58L)
  testthat::expect_equal(nrow(mult), 45L)
  testthat::expect_true(all(mult$status == "registered_not_fitted"))
  testthat::expect_true(all(!mult$omnibus_holm_over_45))
  latent <- mult[model_id %in% c("M21", "M35")]
  testthat::expect_equal(nrow(latent), 2L)
  testthat::expect_true(all(latent$latent_pilot_choice_group == "community_latent_primary_choice"))
  testthat::expect_true(all(latent$independent_evidence_object_count == 1L))
  testthat::expect_true(all(!latent$selected_together_as_independent_primary_evidence))
})

testthat::test_that("Stage 2 support artifacts are complete and support-only", {
  required <- c(
    "species_taxonomy_reconciliation.csv", "species_support_summary.csv", "species_support_by_design_cell.csv",
    "event_complex_audit.csv", "event_complex_crosswalk.csv", "event_geometry_audit.csv", "event_geometry_crosswalk.csv",
    "region_period_effort_support.csv", "count_family_simulation_summary.csv", "cooccurrence_support_summary.csv",
    "response_column_access_audit.csv", "decision_recommendations.csv", "stage_gate.json",
    "ebd_sed_membership_audit.csv", "event_geometry_region_diagnostics.csv", "geometry_representation_eligibility.csv",
    "protocol_effort_amendment.csv", "region_year_support.csv", "region_period_recommendations.csv",
    "shared_checklist_aggregate_audit.csv"
  )
  paths <- repo_file("outputs", "stage2_design_lock", required)
  testthat::expect_true(all(file.exists(paths)))
  species <- data.table::fread(paths[2L])
  cells <- data.table::fread(paths[3L])
  taxonomy <- data.table::fread(paths[1L])
  testthat::expect_equal(nrow(species), 58L)
  testthat::expect_equal(data.table::uniqueN(species$analysis_taxon_id), 58L)
  testthat::expect_equal(nrow(taxonomy), 58L)
  testthat::expect_equal(nrow(cells), 58L * 105L)
  testthat::expect_true(all(species$support_label == "SUPPORT_ONLY_NOT_AN_EFFECT_ESTIMATE"))
  testthat::expect_true(all(cells$support_label == "SUPPORT_ONLY_NOT_AN_EFFECT_ESTIMATE"))
  testthat::expect_setequal(species$common_name[species$named_species_recommendation == "separate_falsification_panel"],
                            c("Gadwall", "Northern Shoveler"))
})

testthat::test_that("Stage 2 crosswalks and access audit satisfy privacy boundaries", {
  event <- data.table::fread(repo_file("outputs", "stage2_design_lock", "event_complex_crosswalk.csv"))
  geometry <- data.table::fread(repo_file("outputs", "stage2_design_lock", "event_geometry_crosswalk.csv"))
  cases <- data.table::fread(repo_file("outputs", "stage2_design_lock", "event_complex_map_review_cases.csv"))
  access <- data.table::fread(repo_file("outputs", "stage2_design_lock", "response_column_access_audit.csv"))
  testthat::expect_equal(nrow(event), 13332L)
  testthat::expect_equal(nrow(geometry), 13332L)
  testthat::expect_false(anyDuplicated(event$source_record_id) > 0L)
  testthat::expect_false(anyDuplicated(geometry$source_record_id) > 0L)
  complex_audit <- data.table::fread(repo_file("outputs", "stage2_design_lock", "event_complex_audit.csv"))
  testthat::expect_equal(nrow(cases), sum(complex_audit$review_packet_rows))
  testthat::expect_true(all(cases$review_required))
  forbidden_names <- c("sampling_event_identifier", "observer_id", "locality_id", "latitude", "longitude", "checklist_comments", "species_comments")
  testthat::expect_false(any(tolower(names(event)) %in% forbidden_names))
  testthat::expect_false(any(tolower(names(geometry)) %in% forbidden_names))
  prohibited <- access[record_type == "prohibited_statistic_check"]
  testthat::expect_true(all(!prohibited$computed))
  testthat::expect_true(all(!prohibited$persisted))
  testthat::expect_true(all(prohibited$check_status == "PASS_NOT_COMPUTED"))
})

testthat::test_that("Stage 2 repaired audits implement the scientific amendment", {
  membership <- data.table::fread(repo_file("outputs", "stage2_design_lock", "ebd_sed_membership_audit.csv"))
  testthat::expect_equal(membership$ebd_keys_unmatched_to_sed, 0L)
  testthat::expect_equal(membership$sed_keys_without_ebd, 17321L)
  testthat::expect_false(membership$primary_zero_fill_eligible)
  testthat::expect_identical(membership$scientific_treatment, "structurally_unknown_excluded_from_primary_zero_fill")

  complex_audit <- data.table::fread(repo_file("outputs", "stage2_design_lock", "event_complex_audit.csv"))
  source <- complex_audit[definition == "source_record"]
  original <- complex_audit[definition == "complex_2km_7d"]
  anti <- complex_audit[definition == "complex_2km_7d_antichain"]
  testthat::expect_identical(source$candidate_role, "safe_primary")
  testthat::expect_equal(original$complexes_over_21_days, 2L)
  testthat::expect_equal(original$temporal_span_days_max, 66)
  testthat::expect_equal(anti$complexes_over_21_days, 0L)
  testthat::expect_true(anti$temporal_span_days_max <= 21)
  testthat::expect_true(anti$spatial_diameter_km_max <= 25)

  geometry <- data.table::fread(repo_file("outputs", "stage2_design_lock", "event_geometry_audit.csv"))
  testthat::expect_true(all(geometry$primary_edge_type == 100L))
  testthat::expect_true(all(geometry$sensitivity_edge_type == 150L))
  testthat::expect_true(all(geometry$actual_alongshore_geometry_verified))
  testthat::expect_true(all(geometry$approved_primary_representation == "source_point"))
  testthat::expect_identical(geometry[geometry_definition == "source_point", candidate_role],
                            "coastwide_primary_human_approved")
  testthat::expect_true(all(geometry$geometry_gate == "PASS_SOURCE_POINT_PRIMARY_SHORELINE_SENSITIVITY_SCOPED"))
  eligible <- data.table::fread(repo_file("outputs", "stage2_design_lock", "geometry_representation_eligibility.csv"))
  common <- eligible[comparison_sample == "common_eligible_events"]
  testthat::expect_equal(data.table::uniqueN(common$eligible_events), 1L)

  recommendations <- data.table::fread(repo_file("outputs", "stage2_design_lock", "region_period_recommendations.csv"))
  primary <- recommendations[recommendation == "candidate_primary_period"]
  testthat::expect_setequal(primary$region, c("SoG", "WCVI"))
  testthat::expect_equal(primary[region == "SoG", candidate_start_year], 2005L)
  testthat::expect_equal(primary[region == "WCVI", candidate_start_year], 2015L)
  testthat::expect_true(all(recommendations[region %in% c("A27", "A2W"), !sustained_support_pass]))

  protocol <- data.table::fread(repo_file("outputs", "stage2_design_lock", "protocol_effort_amendment.csv"))
  testthat::expect_identical(protocol[definition == "standardized_primary", candidate_role], "candidate_primary")
  testthat::expect_identical(protocol[definition == "broad_sensitivity", candidate_role], "broad_sensitivity")
  shared <- data.table::fread(repo_file("outputs", "stage2_design_lock", "shared_checklist_aggregate_audit.csv"))
  testthat::expect_equal(shared$primary_analysis_checklists + shared$disagreement_groups_with_ebd +
                           shared$wholly_sed_only_analysis_groups,
                         shared$analysis_checklists)
  testthat::expect_equal(shared$disagreement_groups_with_ebd + shared$wholly_sed_only_disagreement_groups,
                         shared$disagreement_groups)
  testthat::expect_identical(shared$observer_effect_rule, "shared_group_composite_cluster_not_first_source_row")
})

testthat::test_that("Stage 2 prospective freeze is fixed and date-filtered", {
  testthat::skip_if_not_installed("yaml")
  spec_path <- repo_file("metadata", "prospective_confirmation_spec.yml")
  spec <- yaml::read_yaml(spec_path)
  recorded <- strsplit(readLines(repo_file("metadata", "prospective_confirmation_spec.sha256"), warn = FALSE)[1L], "[[:space:]]+")[[1L]][1L]
  actual <- digest::digest(spec_path, algo = "sha256", file = TRUE, serialize = FALSE)
  testthat::expect_identical(recorded, actual)
  testthat::expect_equal(spec$prospective_horizon$start_year, 2026L)
  testthat::expect_equal(spec$prospective_horizon$end_year, 2028L)
  testthat::expect_identical(spec$confirmation_decision_rule$evaluation_frequency,
                            "once_after_complete_2026_through_2028_horizon")
  testthat::expect_identical(spec$confirmation_decision_rule$interim_response_looks, "none")
  helper <- readLines(repo_file("scripts", "EbdStreamingTools.cs"), warn = FALSE)
  date_filter <- grep("year > 2025", helper, fixed = TRUE)
  response_persist <- grep("positions.Select(position => FieldAt", helper, fixed = TRUE)
  testthat::expect_true(length(date_filter) > 0L && length(response_persist) > 0L)
  testthat::expect_true(max(date_filter) < min(response_persist))
})

testthat::test_that("Stage 2 records human approval without authorizing response models", {
  gate <- jsonlite::read_json(repo_file("outputs", "stage2_design_lock", "stage_gate.json"), simplifyVector = TRUE)
  testthat::expect_identical(gate$classification, "PASS_STAGE2_HUMAN_SCIENTIFIC_APPROVAL_RECORDED")
  testthat::expect_identical(gate$human_scientific_decision, "APPROVED_SOURCE_POINT_PRIMARY")
  testthat::expect_identical(gate$registered_models_fitted, 0L)
  testthat::expect_identical(gate$prohibited_statistics_computed, 0L)
  testthat::expect_true(gate$original_candidate_grid_preserved_unchanged)
  testthat::expect_false(gate$comments_read)
  testthat::expect_false(gate$requires_human_scientific_approval)
  testthat::expect_false(gate$response_models_authorized)
  testthat::expect_false(gate$stage3_entry_implementation_authorized)
  testthat::expect_identical(gate$primary_design$event_geometry, "IMMUTABLE_SOURCE_POINT")
  testthat::expect_identical(gate$repair_status$shoreline_geometry,
                            "PASS_SOURCE_POINT_PRIMARY_SHORELINE_SENSITIVITY_SCOPED")
  testthat::expect_identical(gate$repair_status$shoreline_bundle_coverage,
                            "INCOMPLETE_NONBLOCKING_FOR_APPROVED_PRIMARY")
})
