#!/usr/bin/env Rscript

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
source(file.path("R", "stage4a_core.R"), local = FALSE)
source(file.path("R", "stage4a_production.R"), local = FALSE)
source(file.path("R", "post_stage4a_sog_event_study_v1.R"), local = FALSE)
source(
  file.path("R", "post_stage4a_gwgu_distance_band_sensitivity_v1.R"),
  local = FALSE
)

required_packages <- c("digest", "yaml")
missing <- required_packages[!vapply(
  required_packages, requireNamespace, logical(1L), quietly = TRUE
)]
if (length(missing)) {
  stop("Missing packages: ", paste(missing, collapse = ", "),
       call. = FALSE)
}

code_files <- c(
  "R/post_stage4a_gwgu_distance_band_sensitivity_v1.R",
  "scripts/postprocess_gwgu_distance_band_sensitivity_v1.R"
)
dirty <- system2(
  "git",
  c("status", "--porcelain", "--untracked-files=all", "--", code_files),
  stdout = TRUE,
  stderr = TRUE
)
if (length(dirty) && any(nzchar(dirty))) {
  stop(
    "Post-processing is blocked until the figure and test code are committed",
    call. = FALSE
  )
}
render_commit <- system2("git", c("rev-parse", "HEAD"), stdout = TRUE)
if (length(render_commit) != 1L ||
    !grepl("^[0-9a-f]{40}$", render_commit)) {
  stop("Unable to resolve committed post-processing code", call. = FALSE)
}

output_dir <- "outputs/post_stage4a_gwgu_distance_band_sensitivity_v1"
effects_path <- file.path(
  output_dir, "glaucous_winged_gull_distance_band_effects_v1.csv"
)
fixed_path <- file.path(output_dir, "fixed_effects_v1.csv")
covariance_path <- file.path(output_dir, "exposure_covariance_v1.csv")
record_path <- file.path(output_dir, "execution_record_v1.yml")
stopifnot(
  file.exists(effects_path),
  file.exists(fixed_path),
  file.exists(covariance_path),
  file.exists(record_path)
)

effects <- utils::read.csv(
  effects_path, stringsAsFactors = FALSE, check.names = FALSE
)
fixed <- utils::read.csv(
  fixed_path, stringsAsFactors = FALSE, check.names = FALSE
)
covariance_long <- utils::read.csv(
  covariance_path, stringsAsFactors = FALSE, check.names = FALSE
)
outcomes <- c(
  "detection", "positive_numeric_count_given_detection"
)
if (!setequal(unique(effects$outcome), outcomes) ||
    !setequal(unique(fixed$outcome), outcomes) ||
    !setequal(unique(covariance_long$outcome), outcomes)) {
  stop("POSTPROCESS_OUTCOME_GATE: expected two Glaucous-winged Gull outcomes",
       call. = FALSE)
}

terms <- post_stage4a_gwgu_distance_band_terms_v1()
definitions <- post_stage4a_gwgu_distance_band_contrasts_v1(
  c("(Intercept)", terms)
)
definition_matrix <- do.call(rbind, lapply(definitions, function(x) {
  if (is.null(x$vector)) {
    stop("POSTPROCESS_CONTRAST_GATE: missing contrast vector",
         call. = FALSE)
  }
  x$vector[terms]
}))
rownames(definition_matrix) <- vapply(
  definitions, `[[`, character(1L), "contrast"
)
definition_index <- data.frame(
  contrast = rownames(definition_matrix),
  band = vapply(definitions, `[[`, character(1L), "band"),
  period = vapply(definitions, `[[`, character(1L), "period"),
  stringsAsFactors = FALSE
)
bands <- post_stage4a_gwgu_distance_band_spec_v1()
bands <- bands$band[bands$plotted]
periods <- c(
  "early_pre", "immediate_pre", "spawn_start",
  "early_egg", "late_egg", "active_0_14"
)

wald_test <- function(beta, covariance, contrast_matrix) {
  theta <- drop(contrast_matrix %*% beta)
  theta_covariance <- contrast_matrix %*% covariance %*%
    t(contrast_matrix)
  rank <- qr(theta_covariance)$rank
  if (rank != nrow(contrast_matrix)) {
    return(c(statistic = NA_real_, df = rank, p_value = NA_real_))
  }
  solved <- solve(theta_covariance, theta)
  statistic <- drop(crossprod(theta, solved))
  c(
    statistic = statistic,
    df = nrow(contrast_matrix),
    p_value = stats::pchisq(
      statistic, df = nrow(contrast_matrix), lower.tail = FALSE
    )
  )
}

test_rows <- list()
row_index <- 1L
for (outcome in outcomes) {
  fixed_now <- fixed[fixed$outcome == outcome, , drop = FALSE]
  if (anyDuplicated(fixed_now$coefficient)) {
    stop("POSTPROCESS_FIXED_KEY_GATE: duplicate coefficient",
         call. = FALSE)
  }
  beta <- stats::setNames(fixed_now$estimate, fixed_now$coefficient)[terms]
  if (anyNA(beta) || any(!is.finite(beta))) {
    stop("POSTPROCESS_FIXED_VALUE_GATE: missing exposure coefficient",
         call. = FALSE)
  }
  covariance_now <- covariance_long[
    covariance_long$outcome == outcome, , drop = FALSE
  ]
  covariance_key <- paste(
    covariance_now$row_coefficient,
    covariance_now$column_coefficient,
    sep = "\r"
  )
  if (anyDuplicated(covariance_key) ||
      nrow(covariance_now) != length(terms)^2) {
    stop("POSTPROCESS_COVARIANCE_KEY_GATE: covariance is incomplete",
         call. = FALSE)
  }
  covariance <- matrix(
    NA_real_, nrow = length(terms), ncol = length(terms),
    dimnames = list(terms, terms)
  )
  covariance[cbind(
    match(covariance_now$row_coefficient, terms),
    match(covariance_now$column_coefficient, terms)
  )] <- covariance_now$covariance
  if (anyNA(covariance) ||
      max(abs(covariance - t(covariance))) > 1e-10) {
    stop("POSTPROCESS_COVARIANCE_VALUE_GATE: covariance is invalid",
         call. = FALSE)
  }

  all_period_constraints <- list()
  for (period in periods) {
    selected <- definition_index$period == period
    order_now <- match(
      bands, definition_index$band[selected]
    )
    if (anyNA(order_now) || sum(selected) != length(bands)) {
      stop("POSTPROCESS_PERIOD_GEOMETRY_GATE: incomplete band profile",
           call. = FALSE)
    }
    profile <- definition_matrix[selected, , drop = FALSE][
      order_now, , drop = FALSE
    ]
    constraints <- profile[-1L, , drop = FALSE] -
      matrix(
        profile[1L, ],
        nrow = nrow(profile) - 1L,
        ncol = ncol(profile),
        byrow = TRUE
      )
    test <- wald_test(beta, covariance, constraints)
    test_rows[[row_index]] <- data.frame(
      outcome = outcome,
      test_scope = "period_specific_distance_heterogeneity",
      period = period,
      statistic = unname(test[["statistic"]]),
      degrees_of_freedom = unname(test[["df"]]),
      p_value = unname(test[["p_value"]]),
      bands_compared = paste(bands, collapse = "|"),
      status = if (is.finite(test[["p_value"]])) "completed" else
        "failed_covariance_geometry",
      stringsAsFactors = FALSE
    )
    row_index <- row_index + 1L
    if (period != "active_0_14") {
      all_period_constraints[[period]] <- constraints
    }
  }
  global_constraints <- do.call(rbind, all_period_constraints)
  global <- wald_test(beta, covariance, global_constraints)
  test_rows[[row_index]] <- data.frame(
    outcome = outcome,
    test_scope = "global_five_period_distance_by_timing_heterogeneity",
    period = "all_five_disjoint_nonbaseline_periods",
    statistic = unname(global[["statistic"]]),
    degrees_of_freedom = unname(global[["df"]]),
    p_value = unname(global[["p_value"]]),
    bands_compared = paste(bands, collapse = "|"),
    status = if (is.finite(global[["p_value"]])) "completed" else
      "failed_covariance_geometry",
    stringsAsFactors = FALSE
  )
  row_index <- row_index + 1L
}
tests <- do.call(rbind, test_rows)
if (nrow(tests) != 14L || any(tests$status != "completed")) {
  stop("POSTPROCESS_TEST_GATE: expected fourteen completed tests",
       call. = FALSE)
}
.post_stage4a_write_csv_v1(
  tests, file.path(output_dir, "distance_heterogeneity_tests_v1.csv")
)

post_stage4a_plot_gwgu_distance_bands_v1(
  effects,
  file.path(output_dir, "glaucous_winged_gull_distance_band_panel_v1.png")
)
record <- yaml::read_yaml(record_path)
record$aggregate_postprocessing_commit <- render_commit
record$aggregate_postprocessed_at_utc <- format(
  as.POSIXct(Sys.time(), tz = "UTC"),
  "%Y-%m-%dT%H:%M:%SZ"
)
record$distance_heterogeneity_tests <- nrow(tests)
record$model_refit_during_postprocessing <- FALSE
yaml::write_yaml(record, record_path)

output_files <- file.path(
  output_dir,
  c(
    "glaucous_winged_gull_distance_band_effects_v1.csv",
    "model_diagnostics_v1.csv",
    "model_term_support_v1.csv",
    "joint_exposure_support_v1.csv",
    "fixed_effects_v1.csv",
    "exposure_covariance_v1.csv",
    "distance_heterogeneity_tests_v1.csv",
    "glaucous_winged_gull_distance_band_panel_v1.png",
    "execution_record_v1.yml"
  )
)
manifest <- data.frame(
  file = gsub("\\\\", "/", output_files),
  sha256 = vapply(
    output_files, .post_stage4a_sha256_v1, character(1L)
  ),
  stringsAsFactors = FALSE
)
.post_stage4a_write_csv_v1(
  manifest, file.path(output_dir, "output_hash_manifest_v1.csv")
)
message("GWGU_DISTANCE_BAND_POSTPROCESS_V1=PASS")
