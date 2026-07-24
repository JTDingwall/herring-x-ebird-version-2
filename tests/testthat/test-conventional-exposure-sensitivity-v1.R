testthat::test_that("conventional exposure design was selected before fitting", {
  design <- utils::read.csv(
    repo_file(
      "outputs", "conventional_exposure_sensitivity_v1",
      "design_selection.csv"
    ),
    stringsAsFactors = FALSE
  )

  testthat::expect_equal(sum(design$selected), 1L)
  testthat::expect_identical(
    design$candidate[design$selected],
    "nearest_event"
  )
  testthat::expect_true(all(design$models_fitted_during_selection == 0L))
  testthat::expect_false(any(
    design$selection_used_effect_estimates
  ))
  testthat::expect_equal(
    design$count_species_supported[design$selected],
    41L
  )
})

testthat::test_that("conventional sensitivity release is complete and safe", {
  output <- repo_file("outputs", "conventional_exposure_sensitivity_v1")
  results <- utils::read.csv(
    file.path(output, "conventional_exposure_sensitivity_results.csv"),
    stringsAsFactors = FALSE
  )
  status <- utils::read.csv(
    file.path(output, "component_status.csv"),
    stringsAsFactors = FALSE
  )

  testthat::expect_equal(nrow(results), 98L)
  testthat::expect_equal(
    nrow(results[results$outcome == "checklist_reporting", ]),
    49L
  )
  testthat::expect_equal(
    nrow(results[
      results$outcome == "conditional_positive_numeric_count", ]),
    49L
  )
  testthat::expect_true(all(results$comparison == "active_minus_pre14"))
  testthat::expect_equal(nrow(status), 245L)
  testthat::expect_equal(
    nrow(status[status$analysis == "nearest_event_sensitivity", ]),
    98L
  )

  expected_flagged <- c(
    "Surfbird", "Rhinoceros Auklet", "Glaucous Gull",
    "Red-throated Loon", "Western Gull", "Common Goldeneye",
    "Marbled Murrelet", "Western Grebe"
  )
  testthat::expect_setequal(
    unique(status$species[status$previously_identified_failure_species]),
    expected_flagged
  )
  failed <- grepl("^failed", status$status)
  testthat::expect_true(any(failed))
  testthat::expect_true(all(
    status$failed_component_is_not_null_result[failed]
  ))
  testthat::expect_true(all(
    nzchar(status$failure_reason[failed])
  ))
  completed <- grepl("^completed", results$sensitivity_status)
  testthat::expect_true(all(is.finite(
    results$sensitivity_estimate[completed]
  )))

  forbidden <- c(
    "checklist_id", "sampling_event_identifier", "observer_id",
    "locality", "latitude", "longitude", "source_event_id",
    "herring_source_token", "analysis_event_token"
  )
  testthat::expect_length(
    intersect(tolower(c(names(results), names(status))), forbidden),
    0L
  )
})

testthat::test_that("conventional execution record excludes prospective data", {
  record <- yaml::read_yaml(repo_file(
    "outputs", "conventional_exposure_sensitivity_v1",
    "sensitivity_execution_record.yml"
  ))

  testthat::expect_identical(record$records_2026_plus_read, 0L)
  testthat::expect_identical(record$protected_rows_released, 0L)
  testthat::expect_identical(record$privacy_column_gate, "PASS")
  testthat::expect_identical(
    unlist(record$sensitivity_ids, use.names = FALSE),
    "nearest_event"
  )
})

testthat::test_that("conventional release manifest reproduces", {
  output <- repo_file("outputs", "conventional_exposure_sensitivity_v1")
  manifest <- utils::read.csv(
    file.path(output, "output_hash_manifest.csv"),
    stringsAsFactors = FALSE
  )

  testthat::expect_equal(nrow(manifest), 10L)
  paths <- file.path(output, manifest$file)
  testthat::expect_true(all(file.exists(paths)))
  observed <- vapply(
    paths,
    digest::digest,
    character(1L),
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  )
  testthat::expect_identical(unname(observed), manifest$sha256)
  testthat::expect_equal(unname(file.info(paths)$size), manifest$bytes)
})
