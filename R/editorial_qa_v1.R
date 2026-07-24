editorial_qa_checkpoint_results_v1 <- function(paths) {
  objects <- lapply(paths, readRDS)
  lapply(objects, function(x) x$result)
}

editorial_qa_max_difference_v1 <- function(
    expected, observed, keys, columns) {
  expected_key <- do.call(
    paste, c(expected[keys], sep = "|")
  )
  observed_key <- do.call(
    paste, c(observed[keys], sep = "|")
  )
  if (anyDuplicated(expected_key) || anyDuplicated(observed_key) ||
      !setequal(expected_key, observed_key)) {
    return(Inf)
  }
  index <- match(observed_key, expected_key)
  differences <- vapply(columns, function(column) {
    x <- as.numeric(expected[[column]][index])
    y <- as.numeric(observed[[column]])
    both_na <- is.na(x) & is.na(y)
    mismatch_na <- xor(is.na(x), is.na(y))
    if (any(mismatch_na)) return(Inf)
    values <- abs(x[!both_na] - y[!both_na])
    if (length(values)) max(values) else 0
  }, numeric(1L))
  max(differences)
}

run_editorial_qa_v1 <- function(
    output_dir = "outputs/editorial_requested_analysis_v1",
    checkpoint_dir = "data/derived/editorial_requested_analysis_v1/checkpoints") {
  checks <- list()
  add_check <- function(name, pass, observed, expected, tolerance = NA_real_) {
    checks[[length(checks) + 1L]] <<- data.frame(
      check = name, status = if (isTRUE(pass)) "PASS" else "FAIL",
      observed = as.character(observed), expected = as.character(expected),
      tolerance = tolerance, stringsAsFactors = FALSE
    )
    if (!isTRUE(pass)) {
      stop("EDITORIAL_QA_GATE: ", name, " failed", call. = FALSE)
    }
  }

  primary <- utils::read.csv(
    file.path(output_dir, "active_minus_pre_contrasts.csv"),
    stringsAsFactors = FALSE, check.names = FALSE
  )
  finite_x <- utils::read.csv(
    file.path(output_dir, "finite_vs_x_results.csv"),
    stringsAsFactors = FALSE, check.names = FALSE
  )
  diagnostics <- utils::read.csv(
    file.path(output_dir, "model_diagnostics.csv"),
    stringsAsFactors = FALSE, check.names = FALSE
  )
  predictions <- utils::read.csv(
    file.path(output_dir, "absolute_predictions.csv"),
    stringsAsFactors = FALSE, check.names = FALSE
  )
  add_check("primary_contrast_row_count", nrow(primary) == 196L,
            nrow(primary), 196L)
  add_check("finite_x_contrast_row_count", nrow(finite_x) == 98L,
            nrow(finite_x), 98L)
  add_check("diagnostic_row_count", nrow(diagnostics) == 147L,
            nrow(diagnostics), 147L)
  add_check("absolute_prediction_row_count", nrow(predictions) == 2256L,
            nrow(predictions), 2256L)

  contrast_key <- c(
    "analysis_taxon_id", "outcome", "comparison"
  )
  primary_key <- do.call(paste, c(primary[contrast_key], sep = "|"))
  finite_key <- do.call(paste, c(finite_x[contrast_key], sep = "|"))
  prediction_key <- paste(
    predictions$analysis_taxon_id, predictions$outcome,
    predictions$prediction_configuration, predictions$quantity, sep = "|"
  )
  add_check("primary_contrast_key_unique", !anyDuplicated(primary_key),
            anyDuplicated(primary_key), 0L)
  add_check("finite_x_contrast_key_unique", !anyDuplicated(finite_key),
            anyDuplicated(finite_key), 0L)
  add_check("prediction_key_unique", !anyDuplicated(prediction_key),
            anyDuplicated(prediction_key), 0L)

  all_contrasts <- rbind(primary, finite_x)
  finite <- is.finite(all_contrasts$estimate)
  ratio_difference <- max(abs(
    all_contrasts$ratio[finite] - exp(all_contrasts$estimate[finite])
  ))
  low_difference <- max(abs(
    all_contrasts$ratio_conf_low[finite] -
      exp(all_contrasts$conf_low[finite])
  ))
  high_difference <- max(abs(
    all_contrasts$ratio_conf_high[finite] -
      exp(all_contrasts$conf_high[finite])
  ))
  add_check("ratio_matches_exponentiated_estimate", ratio_difference < 1e-12,
            ratio_difference, "<1e-12", 1e-12)
  add_check("ratio_ci_low_matches_exponentiated_ci", low_difference < 1e-12,
            low_difference, "<1e-12", 1e-12)
  add_check("ratio_ci_high_matches_exponentiated_ci", high_difference < 1e-12,
            high_difference, "<1e-12", 1e-12)
  add_check(
    "p_and_q_in_unit_interval",
    all(
      all_contrasts$p_value[is.finite(all_contrasts$p_value)] >= 0 &
        all_contrasts$p_value[is.finite(all_contrasts$p_value)] <= 1
    ) && all(
      all_contrasts$q_value[is.finite(all_contrasts$q_value)] >= 0 &
        all_contrasts$q_value[is.finite(all_contrasts$q_value)] <= 1
    ),
    "all finite", "[0,1]"
  )
  add_check(
    "full_covariance_flag",
    all(all_contrasts$full_covariance_used %in% TRUE),
    sum(all_contrasts$full_covariance_used %in% TRUE),
    nrow(all_contrasts)
  )

  checkpoint_paths <- list.files(
    checkpoint_dir, pattern = "_rds$", full.names = TRUE
  )
  add_check("core_checkpoint_count", length(checkpoint_paths) == 147L,
            length(checkpoint_paths), 147L)
  checkpoint_results <- editorial_qa_checkpoint_results_v1(checkpoint_paths)
  checkpoint_contrasts <- do.call(
    rbind, lapply(checkpoint_results, `[[`, "contrasts")
  )
  checkpoint_contrasts <- editorial_adjust_bh_v1(checkpoint_contrasts)
  expected_primary <- checkpoint_contrasts[
    checkpoint_contrasts$outcome != "finite_numeric_vs_x", , drop = FALSE
  ]
  expected_finite <- checkpoint_contrasts[
    checkpoint_contrasts$outcome == "finite_numeric_vs_x", , drop = FALSE
  ]
  numerical_columns <- c(
    "active_estimate", "active_standard_error", "pre_estimate",
    "pre_standard_error", "active_pre_covariance", "estimate",
    "standard_error", "conf_low", "conf_high", "ratio",
    "ratio_conf_low", "ratio_conf_high", "p_value", "q_value"
  )
  primary_difference <- editorial_qa_max_difference_v1(
    expected_primary, primary, contrast_key, numerical_columns
  )
  finite_difference <- editorial_qa_max_difference_v1(
    expected_finite, finite_x, contrast_key, numerical_columns
  )
  add_check(
    "primary_contrasts_match_checkpoints",
    primary_difference < 1e-12, primary_difference, "<1e-12", 1e-12
  )
  add_check(
    "finite_x_contrasts_match_checkpoints",
    finite_difference < 1e-8, finite_difference,
    "<1e-8 absolute CSV serialization tolerance", 1e-8
  )

  prediction_parts <- lapply(checkpoint_results, `[[`, "predictions")
  prediction_parts <- prediction_parts[
    vapply(prediction_parts, nrow, integer(1L)) > 0L
  ]
  checkpoint_predictions <- do.call(rbind, prediction_parts)
  prediction_difference <- editorial_qa_max_difference_v1(
    checkpoint_predictions, predictions,
    c(
      "analysis_taxon_id", "outcome",
      "prediction_configuration", "quantity"
    ),
    c("estimate", "conf_low", "conf_high")
  )
  add_check(
    "absolute_predictions_match_checkpoints",
    prediction_difference < 1e-12, prediction_difference,
    "<1e-12", 1e-12
  )

  execution <- yaml::read_yaml(file.path(output_dir, "execution_record.yml"))
  add_check(
    "holdout_records_read", identical(execution$records_2026_plus_read, 0L),
    execution$records_2026_plus_read, 0L
  )
  add_check(
    "historical_outputs_modified",
    identical(execution$historical_stage4a_outputs_modified, FALSE) &&
      identical(execution$frozen_event_study_outputs_modified, FALSE),
    paste(
      execution$historical_stage4a_outputs_modified,
      execution$frozen_event_study_outputs_modified
    ), "FALSE FALSE"
  )
  editorial_privacy_column_gate_v1(list.files(
    output_dir, full.names = TRUE
  ))
  add_check("privacy_column_gate", TRUE, "PASS", "PASS")

  output <- do.call(rbind, checks)
  editorial_write_csv_v1(
    output, file.path(output_dir, "qa_summary.csv")
  )
  message("EDITORIAL_FINAL_NUMERICAL_QA_GATE=PASS checks=", nrow(output))
  invisible(output)
}
