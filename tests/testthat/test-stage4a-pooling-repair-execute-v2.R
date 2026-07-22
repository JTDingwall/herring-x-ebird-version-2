test_that("normal-normal estimator follows frozen positive-tau contract", {
  x <- data.table(
    component_evidence_id = c("a", "b", "c"),
    estimate = c(-1, 0, 2), standard_error = c(0.2, 0.3, 0.4), status = "completed"
  )
  got <- .stage4a_pooling_v2_family_estimator(copy(x))
  v <- x$standard_error ^ 2
  tau2 <- max(0, var(x$estimate) - mean(v))
  weights <- 1 / (v + tau2)
  mu <- sum(weights * x$estimate) / sum(weights)
  post_v <- 1 / (1 / v + 1 / tau2)
  expect_equal(got$family$tau2, tau2, tolerance = 1e-14)
  expect_equal(got$family$family_mean, mu, tolerance = 1e-14)
  expect_equal(got$rows$partial_pool_estimate_v2,
               post_v * (x$estimate / v + mu / tau2), tolerance = 1e-14)
  expect_equal(got$family$estimability_status, "ESTIMABLE")
})

test_that("zero-tau boundary and singleton handling are explicit", {
  common <- data.table(
    component_evidence_id = c("a", "b"), estimate = c(1, 1),
    standard_error = c(0.2, 0.4), status = "completed"
  )
  got <- .stage4a_pooling_v2_family_estimator(copy(common))
  v <- common$standard_error ^ 2
  expected_se <- sqrt(1 / sum(1 / v))
  expect_equal(got$family$tau2, 0)
  expect_equal(got$rows$partial_pool_estimate_v2, c(1, 1))
  expect_equal(got$rows$partial_pool_standard_error_v2,
               rep(expected_se, 2L), tolerance = 1e-14)

  singleton <- .stage4a_pooling_v2_family_estimator(common[1L])
  expect_equal(singleton$family$estimability_status, "NON_ESTIMABLE_SINGLETON")
  expect_true(is.na(singleton$rows$partial_pool_estimate_v2))
  expect_equal(singleton$rows$numeric_input_reason_code,
               "NON_ESTIMABLE_SINGLETON")
})

test_that("missing nonfinite and nonpositive inputs receive frozen reasons", {
  x <- data.table(
    component_evidence_id = letters[1:5],
    estimate = c(0, 1, NA, Inf, 2),
    standard_error = c(0.2, 0.3, 0.4, 0.5, 0), status = "completed"
  )
  got <- .stage4a_pooling_v2_family_estimator(copy(x))$rows
  expect_equal(got$numeric_input_reason_code[3L], "NON_ESTIMABLE_MISSING_INPUT")
  expect_equal(got$numeric_input_reason_code[4L], "NON_ESTIMABLE_NONFINITE_INPUT")
  expect_equal(got$numeric_input_reason_code[5L],
               "NON_ESTIMABLE_NONPOSITIVE_STANDARD_ERROR")
  expect_true(all(is.na(got$partial_pool_estimate_v2[3:5])))
})

test_that("noncompleted model rows remain explicit but cannot enter estimates", {
  x <- data.table(
    component_evidence_id = c("a", "b", "c"), estimate = c(0, 1, 100),
    standard_error = c(0.2, 0.3, 0.1),
    status = c("completed", "completed", "failed_geometry")
  )
  got <- .stage4a_pooling_v2_family_estimator(copy(x))
  expect_equal(got$family$component_count_registered, 3L)
  expect_equal(got$family$component_count_eligible, 2L)
  expect_equal(got$rows$numeric_input_reason_code[3L],
               "NON_ESTIMABLE_MODEL_STATUS")
  expect_true(is.na(got$rows$partial_pool_estimate_v2[3L]))
})

test_that("17-digit numeric serialization is deterministic", {
  x <- c(0, 1 / 3, -2.5e-12, NA, Inf, -Inf, NaN)
  expect_identical(stage4a_pooling_v2_format_number(x),
                   stage4a_pooling_v2_format_number(rev(rev(x))))
  expect_identical(stage4a_pooling_v2_format_number(x)[1:3],
                   c("0", "0.33333333333333331", "-2.4999999999999998e-12"))
  expect_identical(stage4a_pooling_v2_format_number(x)[4:7],
                   c("", "Inf", "-Inf", "NaN"))
})

test_that("versioned text serialization uses canonical LF bytes", {
  path <- tempfile("stage4a_pooling_lf_", fileext = ".txt")
  on.exit(unlink(path), add = TRUE)
  .stage4a_pooling_v2_write_text_lf(c("first", "second"), path)
  bytes <- readBin(path, what = "raw", n = file.info(path)$size)
  expect_identical(rawToChar(bytes), "first\nsecond\n")
  expect_false(any(bytes == as.raw(13L)))
})

test_that("production v2 output preserves every unaffected serialized field", {
  source_path <- repo_file("outputs", "stage4a_results", "effect_estimates.csv")
  v2_path <- repo_file("outputs", "stage4a_pooling_repair_v2", "effect_estimates_v2.csv")
  source_raw <- fread(source_path, colClasses = "character", na.strings = NULL,
                      strip.white = FALSE)
  typed <- stage4a_pooling_v2_read_effects(
    source_path,
    character_columns = c("model_id", "region", "unit_label", "unit_class",
                          "outcome", "contrast", "status", "multiplicity_family"),
    numeric_columns = c("estimate", "standard_error", "conf_low", "conf_high",
                        "p_value", "n", "q_value", "partial_pool_estimate",
                        "partial_pool_standard_error"),
    region_file = repo_file("metadata", "stage4a_region_registry_v2.csv"),
    required_identity_columns = c("model_id", "region", "unit_label", "unit_class",
                                  "outcome", "contrast")
  )
  affected <- is.finite(typed$partial_pool_estimate) |
    is.finite(typed$partial_pool_standard_error)
  v2 <- fread(v2_path, colClasses = "character", na.strings = NULL,
              strip.white = FALSE)
  unaffected <- setdiff(names(source_raw),
                        c("partial_pool_estimate", "partial_pool_standard_error"))
  expect_equal(nrow(v2), 6562L)
  expect_false(any(c("partial_pool_estimate", "partial_pool_standard_error") %in% names(v2)))
  expect_identical(as.data.frame(v2[, ..unaffected]),
                   as.data.frame(source_raw[affected, ..unaffected]))
  expect_equal(sum(nzchar(v2$partial_pool_estimate_v2)), 6085L)
  expect_equal(sum(!nzchar(v2$partial_pool_estimate_v2)), 477L)
  expect_equal(sum(v2$pooling_reason_code_v2 ==
                   "INCLUDED_PRIMARY_REPRESENTATION"), 6085L)
  expect_equal(sum(v2$pooling_reason_code_v2 ==
                   "NON_ESTIMABLE_MODEL_STATUS"), 38L)
  expect_equal(sum(v2$pooling_reason_code_v2 ==
                   "EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION"), 439L)
})

test_that("production execution artifacts are complete and hash-valid", {
  output_dir <- repo_file("outputs", "stage4a_pooling_repair_v2")
  family <- fread(file.path(output_dir, "pooling_family_estimates_v2.csv"))
  rows <- fread(file.path(output_dir, "row_inclusion_exclusion_audit_v2.csv"))
  manifest <- fread(file.path(output_dir, "output_hash_manifest_v2.csv"))
  record <- yaml::read_yaml(file.path(output_dir, "execution_record_v2.yml"))
  expect_equal(nrow(family), 162L)
  expect_equal(sum(family$estimability_status == "ESTIMABLE"), 162L)
  expect_equal(sum(family$estimability_status != "ESTIMABLE"), 0L)
  expect_equal(nrow(rows), 6562L)
  expect_equal(sum(rows$included_in_future_estimator), 6123L)
  expect_equal(sum(!rows$included_in_future_estimator), 439L)
  expect_identical(record$pre_execution_spec_commit,
                   "bee142b6878bb66d57910c5aee57e4097fb2adf9")
  expect_false(record$input_artifacts$protected_inputs_used)
  for (i in seq_len(nrow(manifest))) {
    file <- file.path(project_root, manifest$artifact_path[i])
    expect_true(file.exists(file), info = manifest$artifact_path[i])
    expect_identical(digest::digest(file, algo = "sha256", file = TRUE,
                                    serialize = FALSE), manifest$sha256[i])
    expect_equal(unname(file.info(file)$size), manifest$bytes[i])
  }
})

test_that("production aggregate repair reruns byte-identically per platform", {
  record <- yaml::read_yaml(repo_file("outputs", "stage4a_pooling_repair_v2",
                                      "execution_record_v2.yml"))
  temp <- c(tempfile("stage4a_pooling_v2_test_a_"),
            tempfile("stage4a_pooling_v2_test_b_"))
  vapply(temp, dir.create, logical(1L))
  on.exit(unlink(temp, recursive = TRUE), add = TRUE)
  for (directory in temp) stage4a_pooling_v2_execute(
      repo_root = project_root, output_dir = directory,
      pre_execution_spec_commit = record$pre_execution_spec_commit,
      execution_code_commit = record$execution_code_commit
    )
  expected_dir <- repo_file("outputs", "stage4a_pooling_repair_v2")
  files <- sort(list.files(expected_dir))
  expect_setequal(list.files(temp[1L]), files)
  expect_setequal(list.files(temp[2L]), files)
  rerun_hash <- lapply(temp, function(directory) vapply(
    file.path(directory, files), digest::digest, character(1L), algo = "sha256",
    file = TRUE, serialize = FALSE
  ))
  expect_identical(unname(rerun_hash[[1L]]), unname(rerun_hash[[2L]]))

  platform_stable <- setdiff(files,
    c("effect_estimates_v2.csv", "output_hash_manifest_v2.csv"))
  expected_hash <- vapply(file.path(expected_dir, platform_stable), digest::digest,
    character(1L), algo = "sha256", file = TRUE, serialize = FALSE)
  actual_hash <- vapply(file.path(temp[1L], platform_stable), digest::digest,
    character(1L), algo = "sha256", file = TRUE, serialize = FALSE)
  expect_identical(unname(actual_hash), unname(expected_hash))

  expected <- fread(file.path(expected_dir, "effect_estimates_v2.csv"),
                    colClasses = "character", na.strings = NULL)
  actual <- fread(file.path(temp[1L], "effect_estimates_v2.csv"),
                  colClasses = "character", na.strings = NULL)
  derived <- c("partial_pool_estimate_v2", "partial_pool_standard_error_v2",
               "partial_pool_conf_low_v2", "partial_pool_conf_high_v2")
  expect_identical(as.data.frame(actual[, setdiff(names(actual), derived), with = FALSE]),
                   as.data.frame(expected[, setdiff(names(expected), derived), with = FALSE]))
  for (field in derived) {
    observed <- as.numeric(actual[[field]])
    reference <- as.numeric(expected[[field]])
    relative_error <- abs(observed - reference) / pmax(1, abs(reference))
    expect_true(all(relative_error[is.finite(relative_error)] < 1e-13), info = field)
    expect_identical(is.na(observed), is.na(reference))
  }
})
