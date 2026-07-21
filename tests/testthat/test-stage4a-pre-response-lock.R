testthat::test_that("Stage 4A disposition preserves all 45 registered models", {
  registry <- utils::read.csv(repo_file("metadata", "model_registry.csv"),
    stringsAsFactors = FALSE)
  disposition <- utils::read.csv(repo_file("metadata", "stage4a_model_disposition_v1.csv"),
    stringsAsFactors = FALSE)
  testthat::expect_equal(nrow(registry), 45L)
  testthat::expect_equal(nrow(disposition), 45L)
  testthat::expect_identical(registry$model_id, disposition$model_id)
  testthat::expect_setequal(disposition$model_id[grepl("^activated_",
    disposition$stage4a_disposition)],
    c("M01","M02","M05","M08","M11","M12","M26","M27","M28","M29","M32","M40"))
  testthat::expect_identical(disposition$stage4a_disposition[disposition$model_id == "M31"],
    "prospective_locked")
  testthat::expect_true(all(disposition$stage4a_disposition[!disposition$model_id %in%
    c("M01","M02","M05","M08","M11","M12","M26","M27","M28","M29","M31","M32","M40")] ==
    "deferred_pre_response"))
  testthat::expect_identical(digest::digest(repo_file("metadata", "model_registry.csv"),
    algo="sha256", file=TRUE, serialize=FALSE),
    "e9f28b1772ca8e5816abfe8e59c0286b495305725f2cfc9e08beb97cd211d311")
})

testthat::test_that("Stage 4A lock artifacts are hash-identical", {
  testthat::skip_if_not_installed("digest")
  pairs <- list(
    c("metadata/stage4a_human_scientific_authorization_v1.yml","metadata/stage4a_human_scientific_authorization_v1.sha256"),
    c("metadata/stage4a_model_disposition_v1.csv","metadata/stage4a_model_disposition_v1.csv.sha256"),
    c("metadata/stage4a_model_specification_matrix_v1.csv","metadata/stage4a_model_specification_matrix_v1.csv.sha256"),
    c("metadata/stage4a_core_spec_v1.yml","metadata/stage4a_core_spec_v1.sha256"),
    c("metadata/stage4a_pre_response_scope_lock_v1.yml","metadata/stage4a_pre_response_scope_lock_v1.sha256"),
    c("metadata/stage4a_pre_response_scope_lock_v2.yml","metadata/stage4a_pre_response_scope_lock_v2.sha256"),
    c("metadata/stage4a_pre_response_scope_lock_v3.yml","metadata/stage4a_pre_response_scope_lock_v3.sha256"),
    c("docs/14_STAGE4A_CORE_METHODS.md","docs/14_STAGE4A_CORE_METHODS.sha256"),
    c("docs/15_STAGE4A_RESULTS_TEMPLATE.md","docs/15_STAGE4A_RESULTS_TEMPLATE.sha256"))
  for(pair in pairs) {
    sidecar <- do.call(repo_file,as.list(strsplit(pair[2],"/",fixed=TRUE)[[1]]))
    artifact <- do.call(repo_file,as.list(strsplit(pair[1],"/",fixed=TRUE)[[1]]))
    recorded <- strsplit(readLines(sidecar,warn=FALSE)[1],"[[:space:]]+")[[1]][1]
    actual <- digest::digest(artifact,
      algo="sha256",file=TRUE,serialize=FALSE)
    testthat::expect_identical(recorded,actual)
  }
})

testthat::test_that("Stage 4A specification freezes factorized scope and region rules", {
  testthat::skip_if_not_installed("yaml")
  spec <- yaml::read_yaml(repo_file("metadata", "stage4a_core_spec_v1.yml"))
  testthat::expect_equal(spec$taxon_registry$expected_rows, 58L)
  testthat::expect_true(spec$population$factorized_denominator)
  testthat::expect_identical(spec$population$full_logical_grid_materialization, "prohibited")
  testthat::expect_equal(spec$population$latest_year, 2025L)
  testthat::expect_equal(spec$population$primary_regions$SoG, 2005L)
  testthat::expect_equal(spec$population$primary_regions$WCVI, 2015L)
  testthat::expect_equal(spec$population$high_precision_sensitivity_km_maximum, 2L)
  testthat::expect_identical(spec$population$broad_10km_frame, "prohibited")
  testthat::expect_equal(spec$validation$folds, 4L)
  testthat::expect_identical(spec$validation$new_event_generalization_claim_source,
    "event_blocked_only")
  testthat::expect_identical(spec$validation$heldout_prediction_random_effects,
    "population_expectation")
  testthat::expect_identical(spec$validation$conditional_blups, "prohibited")
  testthat::expect_equal(spec$species_selector$expected_primary_taxa, 49L)
})

testthat::test_that("Stage 4A response builder has a narrow field allowlist", {
  code <- paste(readLines(repo_file("scripts", "Stage4AProtectedBuilder.cs"),
    warn = FALSE), collapse = "\n")
  testthat::expect_true(grepl("reported_count_states", code, fixed=TRUE))
  testthat::expect_true(grepl("ambiguity_masks", code, fixed=TRUE))
  testthat::expect_true(grepl("OBSERVATION DATE", code, fixed=TRUE))
  testthat::expect_false(grepl("LATITUDE|LONGITUDE|COMMENTS|BREEDING CODE|AGE.SEX|2026|2027|2028",
    code, ignore.case = TRUE))
  testthat::expect_false(grepl("83[ ,]?159[ ,]?588", code))
  testthat::expect_true(grepl("ConcurrentLinks", code, fixed=TRUE))
})

testthat::test_that("Stage 4A factorization keeps X, ambiguity and zero distinct", {
  source(repo_file("R", "stage4a_core.R"), local = TRUE)
  testthat::expect_silent(stage4a_fixture())
  events <- data.frame(analysis_event_token=c("a","b","c"), stringsAsFactors=FALSE)
  states <- data.frame(analysis_event_token="a", analysis_taxon_id="t", detection=1L,
    numeric_count=NA_real_, lower_bound_count=NA_real_, count_type="unquantified_X",
    ambiguity_flag=FALSE, stringsAsFactors=FALSE)
  masks <- data.frame(analysis_event_token="b", analysis_taxon_id="t",
    stringsAsFactors=FALSE)
  out <- stage4a_materialize_taxon(events,states,masks,"t")
  testthat::expect_identical(out$count_type, c("unquantified_X","structural_unknown","deterministic_zero"))
  testthat::expect_identical(out$detection, c(1L,NA_integer_,0L))
})

testthat::test_that("Stage 4A production code protects prediction and multiplicity rules", {
  code <- paste(readLines(repo_file("R", "stage4a_production.R"), warn=FALSE), collapse="\n")
  testthat::expect_true(grepl("exclude = random_terms", paste(readLines(
    repo_file("R", "stage4a_core.R"), warn=FALSE),collapse="\n"), fixed=TRUE))
  testthat::expect_true(grepl("event_fold", code, fixed=TRUE))
  testthat::expect_true(grepl("observer_fold", code, fixed=TRUE) ||
    grepl("observer_disjoint", code, fixed=TRUE))
  testthat::expect_true(grepl("dominant_observer", code, fixed=TRUE))
  core_code <- paste(readLines(repo_file("R", "stage4a_core.R"), warn=FALSE), collapse="\n")
  testthat::expect_true(grepl('method = "BH"', core_code, fixed=TRUE))
  testthat::expect_false(grepl("HERRING_EBIRD_V2_EBD|HERRING_EBIRD_V2_HERRING|LATITUDE|LONGITUDE|comments\\.tsv",
    code, ignore.case=TRUE))
})

testthat::test_that("Stage 4A pre-response report is empty of observed results", {
  x <- paste(readLines(repo_file("docs", "15_STAGE4A_RESULTS_TEMPLATE.md"), warn=FALSE),
    collapse="\n")
  testthat::expect_true(grepl("LOCKED_NO_OBSERVED_RESULTS", x, fixed=TRUE))
  testthat::expect_true(grepl("contains no observed", x, fixed=TRUE))
})
