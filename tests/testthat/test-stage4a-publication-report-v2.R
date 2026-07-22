test_that("publication package has complete aggregate accounting and declared joins", {
  output <- repo_file("outputs", "stage4a_publication_v2")
  primary <- fread(file.path(output, "primary_guild_table_v2.csv"))
  species <- fread(file.path(output, "priority_a_species_table_v2.csv"))
  event <- fread(file.path(output, "event_time_table_v2.csv"))
  sensitivity <- fread(file.path(output, "matched_sensitivity_table_v2.csv"))
  concordance <- fread(file.path(output, "sensitivity_concordance_v2.csv"))
  family <- fread(file.path(output, "supplementary_family_table_v2.csv"))
  exclusion <- fread(file.path(output, "supplementary_exclusion_summary_v2.csv"))
  expect_equal(nrow(primary), 32L)
  expect_equal(nrow(species), 20L)
  expect_equal(nrow(event), 160L)
  expect_equal(nrow(sensitivity), 128L)
  expect_equal(nrow(concordance), 96L)
  expect_equal(nrow(family), 162L)
  expect_equal(sum(exclusion$rows), 6562L)
  expect_setequal(exclusion$rows, c(6085L, 38L, 439L))
  expect_equal(nrow(sensitivity[model_version_id == "M01_PRIMARY_v2"]), 32L)
  expect_equal(anyDuplicated(sensitivity[, .(
    model_version_id, region, unit_label, outcome)]), 0L)
  expect_equal(anyDuplicated(concordance[, .(
    model_version_id, region, unit_label, outcome)]), 0L)
  expect_true(all(concordance$matched_primary_model_id == "M01"))
})

test_that("publication package exposes every fit status and no simplified fallback", {
  output <- repo_file("outputs", "stage4a_publication_v2")
  sensitivity <- fread(file.path(output, "matched_sensitivity_table_v2.csv"))
  diagnostics <- fread(file.path(output, "model_diagnostic_summary_v2.csv"))
  expect_equal(sum(grepl("^completed", sensitivity$status)), 128L)
  expect_equal(sum(sensitivity$status == "completed_with_singular_warning"), 43L)
  expect_equal(sum(sensitivity$status == "failed_convergence"), 0L)
  expect_equal(sum(diagnostics$components), 128L)
  placebo <- sensitivity[model_version_id %in% c("M27_v2", "M28_v2") &
    grepl("^completed", status)]
  expect_equal(nrow(placebo), 64L)
  expect_equal(sum(placebo$q_value < 0.05, na.rm = TRUE), 0L)
  code <- paste(readLines(repo_file("R", "stage4a_publication_sensitivity_v2.R"),
                          warn = FALSE), collapse = "\n")
  expect_false(grepl("stats::glm\\(", code))
  expect_false(grepl("stats::lm\\(", code))
})

test_that("publication manifest and claim-boundary artifacts are valid", {
  output <- repo_file("outputs", "stage4a_publication_v2")
  manifest <- fread(file.path(output, "publication_artifact_hashes_v2.csv"))
  expect_equal(nrow(manifest), 21L)
  for (i in seq_len(nrow(manifest))) {
    file <- file.path(project_root, manifest$artifact_path[i])
    expect_true(file.exists(file), info = manifest$artifact_path[i])
    expect_identical(digest::digest(file, algo = "sha256", file = TRUE,
      serialize = FALSE), manifest$sha256[i], info = manifest$artifact_path[i])
    expect_equal(unname(file.info(file)$size), manifest$bytes[i])
  }
  report <- paste(readLines(repo_file("reports", "stage4a_publication_analysis_v2.html"),
                            warn = FALSE), collapse = "\n")
  required <- c("6,562 finite v1 pooling rows", "112 historical families",
    "0 had BH q below 0.05", "does not establish causal identification",
    "No component failed convergence", "43 retain an explicit singular-fit warning",
    "M26 v1 is retired", "Missing herring components are not zero",
    "2026+ row count was zero", "protected rows")
  for (phrase in required) expect_match(report, phrase, fixed = TRUE)
  expect_false(grepl("population abundance, biomass, occupancy, migration, movement, or causal effects</p></div><p>These models identify", report, fixed = TRUE))
})

test_that("publication package rebuild is byte-identical", {
  output <- repo_file("outputs", "stage4a_publication_v2")
  build_stage4a_publication_report_v2(project_root)
  first <- fread(file.path(output, "publication_artifact_hashes_v2.csv"))
  build_stage4a_publication_report_v2(project_root)
  second <- fread(file.path(output, "publication_artifact_hashes_v2.csv"))
  expect_identical(second, first)
})
