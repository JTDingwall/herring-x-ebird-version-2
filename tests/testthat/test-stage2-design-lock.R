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
})

testthat::test_that("Stage 2 support artifacts are complete and support-only", {
  required <- c(
    "species_taxonomy_reconciliation.csv", "species_support_summary.csv", "species_support_by_design_cell.csv",
    "event_complex_audit.csv", "event_complex_crosswalk.csv", "event_geometry_audit.csv", "event_geometry_crosswalk.csv",
    "region_period_effort_support.csv", "count_family_simulation_summary.csv", "cooccurrence_support_summary.csv",
    "response_column_access_audit.csv", "decision_recommendations.csv", "stage_gate.json"
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
  testthat::expect_equal(nrow(cases), 100L)
  forbidden_names <- c("sampling_event_identifier", "observer_id", "locality_id", "latitude", "longitude", "checklist_comments", "species_comments")
  testthat::expect_false(any(tolower(names(event)) %in% forbidden_names))
  testthat::expect_false(any(tolower(names(geometry)) %in% forbidden_names))
  prohibited <- access[record_type == "prohibited_statistic_check"]
  testthat::expect_true(all(!prohibited$computed))
  testthat::expect_true(all(!prohibited$persisted))
  testthat::expect_true(all(prohibited$check_status == "PASS_NOT_COMPUTED"))
})

testthat::test_that("Stage 2 gate is ready only for human scientific approval", {
  gate <- jsonlite::read_json(repo_file("outputs", "stage2_design_lock", "stage_gate.json"), simplifyVector = TRUE)
  testthat::expect_identical(gate$classification, "PASS_READY_FOR_HUMAN_SCIENTIFIC_APPROVAL")
  testthat::expect_identical(gate$registered_models_fitted, 0L)
  testthat::expect_identical(gate$prohibited_statistics_computed, 0L)
  testthat::expect_true(gate$candidate_grid_verified_before_response_value_access)
  testthat::expect_false(gate$comments_read)
  testthat::expect_true(gate$requires_human_scientific_approval)
})
