stage4a_pooling_v2_format_number <- function(x) {
  out <- rep("", length(x))
  finite <- is.finite(x)
  # R's internal decimal formatter is stable across C runtimes; sprintf("%g")
  # can differ at the final digit between Windows UCRT and Linux glibc.
  out[finite] <- vapply(x[finite], function(value) {
    format(value, digits = 17L, trim = TRUE, scientific = NA, nsmall = 0L)
  }, character(1L))
  out[is.infinite(x) & x > 0] <- "Inf"
  out[is.infinite(x) & x < 0] <- "-Inf"
  out[is.nan(x)] <- "NaN"
  out
}

.stage4a_pooling_v2_write_text_lf <- function(x, path) {
  value <- enc2utf8(paste(x, collapse = "\n"))
  value <- gsub("\r\n?", "\n", value)
  if (!endsWith(value, "\n")) value <- paste0(value, "\n")
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  writeBin(charToRaw(value), con)
  invisible(path)
}

.stage4a_pooling_v2_file_hash <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

.stage4a_pooling_v2_write_csv <- function(x, path) {
  data.table::fwrite(x, path, quote = TRUE, na = "", eol = "\n", bom = FALSE)
}

.stage4a_pooling_v2_family_estimator <- function(x) {
  if (!"status" %in% names(x)) stop("POOLING_V2_ESTIMATOR: status is required", call. = FALSE)
  eligible <- x$status == "completed" & is.finite(x$estimate) &
    is.finite(x$standard_error) & x$standard_error > 0
  x[, numeric_input_reason_code := ifelse(
    status != "completed", "NON_ESTIMABLE_MODEL_STATUS",
    ifelse(is.na(estimate) | is.na(standard_error), "NON_ESTIMABLE_MISSING_INPUT",
    ifelse(!is.finite(estimate) | !is.finite(standard_error),
           "NON_ESTIMABLE_NONFINITE_INPUT",
           ifelse(standard_error <= 0, "NON_ESTIMABLE_NONPOSITIVE_STANDARD_ERROR",
                  "INCLUDED_PRIMARY_REPRESENTATION"))))]
  good <- x[eligible]
  if (nrow(good) < 2L) {
    x[, `:=`(partial_pool_estimate_v2 = NA_real_,
             partial_pool_standard_error_v2 = NA_real_,
             partial_pool_conf_low_v2 = NA_real_,
             partial_pool_conf_high_v2 = NA_real_)]
    x[numeric_input_reason_code == "INCLUDED_PRIMARY_REPRESENTATION",
      numeric_input_reason_code := "NON_ESTIMABLE_SINGLETON"]
    family <- data.table::data.table(
      component_count_registered = nrow(x), component_count_eligible = nrow(good),
      excluded_numeric_input_count = nrow(x) - nrow(good), tau2 = NA_real_,
      family_mean = NA_real_, family_standard_error = NA_real_,
      family_conf_low = NA_real_, family_conf_high = NA_real_,
      estimability_status = "NON_ESTIMABLE_SINGLETON",
      reason_code = "NON_ESTIMABLE_SINGLETON"
    )
    return(list(rows = x, family = family))
  }
  y <- good$estimate
  v <- good$standard_error ^ 2
  tau2 <- max(0, stats::var(y) - mean(v))
  weights <- 1 / (v + tau2)
  mu <- sum(weights * y) / sum(weights)
  family_se <- sqrt(1 / sum(weights))
  z <- 1.959963984540054
  if (tau2 == 0) {
    posterior_mean <- rep(mu, length(y))
    posterior_se <- rep(sqrt(1 / sum(1 / v)), length(y))
  } else {
    posterior_variance <- 1 / (1 / v + 1 / tau2)
    posterior_mean <- posterior_variance * (y / v + mu / tau2)
    posterior_se <- sqrt(posterior_variance)
  }
  good[, `:=`(
    partial_pool_estimate_v2 = posterior_mean,
    partial_pool_standard_error_v2 = posterior_se,
    partial_pool_conf_low_v2 = posterior_mean - z * posterior_se,
    partial_pool_conf_high_v2 = posterior_mean + z * posterior_se
  )]
  x[, `:=`(partial_pool_estimate_v2 = NA_real_,
           partial_pool_standard_error_v2 = NA_real_,
           partial_pool_conf_low_v2 = NA_real_,
           partial_pool_conf_high_v2 = NA_real_)]
  x[good, on = "component_evidence_id", `:=`(
    partial_pool_estimate_v2 = i.partial_pool_estimate_v2,
    partial_pool_standard_error_v2 = i.partial_pool_standard_error_v2,
    partial_pool_conf_low_v2 = i.partial_pool_conf_low_v2,
    partial_pool_conf_high_v2 = i.partial_pool_conf_high_v2
  )]
  family <- data.table::data.table(
    component_count_registered = nrow(x), component_count_eligible = nrow(good),
    excluded_numeric_input_count = nrow(x) - nrow(good), tau2 = tau2,
    family_mean = mu, family_standard_error = family_se,
    family_conf_low = mu - z * family_se,
    family_conf_high = mu + z * family_se,
    estimability_status = "ESTIMABLE",
    reason_code = "INCLUDED_PRIMARY_REPRESENTATION"
  )
  list(rows = x, family = family)
}

stage4a_pooling_v2_execute <- function(repo_root = ".", output_dir,
                                       pre_execution_spec_commit,
                                       execution_code_commit) {
  old <- Sys.getlocale("LC_NUMERIC")
  on.exit(try(Sys.setlocale("LC_NUMERIC", old), silent = TRUE), add = TRUE)
  Sys.setlocale("LC_NUMERIC", "C")
  root <- normalizePath(repo_root, winslash = "/", mustWork = TRUE)
  path <- function(...) file.path(root, ...)
  source_file <- path("outputs", "stage4a_results", "effect_estimates.csv")
  identity_columns <- c("model_id", "region", "unit_label", "unit_class", "outcome", "contrast")
  character_columns <- c(identity_columns, "status", "multiplicity_family")
  numeric_columns <- c("estimate", "standard_error", "conf_low", "conf_high",
                       "p_value", "n", "q_value", "partial_pool_estimate",
                       "partial_pool_standard_error")
  unaffected <- c(identity_columns, "estimate", "standard_error", "conf_low", "conf_high",
                  "p_value", "n", "status", "multiplicity_family", "q_value")
  expected_columns <- c(unaffected, "partial_pool_estimate", "partial_pool_standard_error")
  raw <- data.table::fread(source_file, colClasses = "character", na.strings = NULL,
                           strip.white = FALSE)
  if (!identical(names(raw), expected_columns)) {
    stop("POOLING_V2_SOURCE_SCHEMA: v1 effect columns or order changed", call. = FALSE)
  }
  typed <- stage4a_pooling_v2_read_effects(
    source_file, character_columns, numeric_columns,
    path("metadata", "stage4a_region_registry_v2.csv"), identity_columns
  )
  affected <- is.finite(typed$partial_pool_estimate) |
    is.finite(typed$partial_pool_standard_error)
  if (sum(affected) != 6562L) stop("POOLING_V2_SCOPE: execution requires 6,562 rows", call. = FALSE)
  identity <- typed[affected, ..identity_columns]
  species <- data.table::fread(path("metadata", "canonical_species_registry.csv"),
                               select = c("analysis_taxon_id", "common_name"))
  guilds <- data.table::fread(path("metadata", "canonical_guild_registry.csv"),
                              select = "guild_id")
  identity <- .stage4a_pooling_v2_unit_map(identity, species, guilds)
  identity[, canonical_model_id := ifelse(model_id %in% c("M11", "M12"),
    ifelse(unit_class == "guild", "M01", "M02"), model_id)]
  identity[, response_state := ifelse(outcome == "detection", "detection",
    "positive_numeric_count_given_detection")]
  evidence <- data.table::fread(path("metadata", "stage4a_component_evidence_registry_v2.csv"),
                                na.strings = NULL)
  join_fields <- c("canonical_model_id", "stable_unit_id", "region", "contrast",
                   "unit_class", "response_state")
  mapped <- evidence[identity, on = join_fields]
  if (nrow(mapped) != nrow(identity) || anyNA(mapped$component_evidence_id)) {
    stop("POOLING_V2_EVIDENCE_JOIN: expected many-to-one identity mapping failed", call. = FALSE)
  }
  if (anyDuplicated(evidence[, ..join_fields])) {
    stop("POOLING_V2_EVIDENCE_JOIN: evidence registry join key is not unique", call. = FALSE)
  }
  crosswalk <- data.table::fread(path("metadata", "stage4a_pooling_v1_to_v2_crosswalk.csv"),
                                 na.strings = NULL)
  crosswalk_key <- crosswalk[, .(model_id, component_evidence_id, v1_effect_row_id,
                                 v1_pooling_family_id, disposition_reason_code,
                                 included_in_future_estimator)]
  if (anyDuplicated(crosswalk_key[, .(model_id, component_evidence_id)])) {
    stop("POOLING_V2_CROSSWALK_JOIN: model/evidence key is not unique", call. = FALSE)
  }
  mapped <- crosswalk_key[mapped, on = c("model_id", "component_evidence_id")]
  if (anyNA(mapped$v1_effect_row_id)) stop("POOLING_V2_CROSSWALK_JOIN: unmatched affected row", call. = FALSE)
  source_rows <- which(affected)
  mapped[, `:=`(source_row = source_rows,
                estimate = typed$estimate[source_rows],
                standard_error = typed$standard_error[source_rows],
                status = typed$status[source_rows])]

  selected <- mapped[included_in_future_estimator == TRUE]
  splits <- split(seq_len(nrow(selected)), selected$pooling_family_id_v2)
  estimated_rows <- vector("list", length(splits))
  family_rows <- vector("list", length(splits))
  family_ids <- names(splits)
  for (j in seq_along(splits)) {
    result <- .stage4a_pooling_v2_family_estimator(data.table::copy(selected[splits[[j]]]))
    estimated_rows[[j]] <- result$rows
    family_rows[[j]] <- cbind(data.table::data.table(pooling_family_id_v2 = family_ids[j]),
                              result$family)
  }
  estimated <- data.table::rbindlist(estimated_rows)
  family_estimates <- data.table::rbindlist(family_rows)
  data.table::setorder(family_estimates, pooling_family_id_v2)
  if (nrow(family_estimates) != 162L) stop("POOLING_V2_FAMILY_COUNT: expected 162 v2 families", call. = FALSE)

  output <- data.table::copy(raw[affected, ..unaffected])
  output[, `:=`(
    pooling_family_id_v2 = mapped$pooling_family_id_v2,
    component_evidence_id = mapped$component_evidence_id,
    partial_pool_estimate_v2 = "",
    partial_pool_standard_error_v2 = "",
    partial_pool_conf_low_v2 = "",
    partial_pool_conf_high_v2 = "",
    pooling_reason_code_v2 = mapped$disposition_reason_code
  )]
  selected_values <- estimated[, .(model_id, component_evidence_id,
    partial_pool_estimate_v2, partial_pool_standard_error_v2,
    partial_pool_conf_low_v2, partial_pool_conf_high_v2,
    pooling_reason_code_v2 = numeric_input_reason_code)]
  if (anyDuplicated(selected_values[, .(model_id, component_evidence_id)])) {
    stop("POOLING_V2_OUTPUT_JOIN: estimated model/evidence keys are not unique", call. = FALSE)
  }
  output[selected_values, on = c("model_id", "component_evidence_id"), `:=`(
    partial_pool_estimate_v2 = stage4a_pooling_v2_format_number(i.partial_pool_estimate_v2),
    partial_pool_standard_error_v2 = stage4a_pooling_v2_format_number(i.partial_pool_standard_error_v2),
    partial_pool_conf_low_v2 = stage4a_pooling_v2_format_number(i.partial_pool_conf_low_v2),
    partial_pool_conf_high_v2 = stage4a_pooling_v2_format_number(i.partial_pool_conf_high_v2),
    pooling_reason_code_v2 = i.pooling_reason_code_v2
  )]
  if (!identical(as.data.frame(output[, ..unaffected]),
                 as.data.frame(raw[affected, ..unaffected]))) {
    stop("POOLING_V2_UNAFFECTED_MISMATCH: unaffected serialized fields changed", call. = FALSE)
  }

  row_audit <- mapped[, .(
    v1_effect_row_id, pooling_family_id_v2, component_evidence_id, model_id,
    canonical_model_id, included_in_future_estimator, disposition_reason_code,
    numeric_input_reason_code = ifelse(included_in_future_estimator,
      estimated$numeric_input_reason_code[match(component_evidence_id,
                                                estimated$component_evidence_id)],
      "EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION")
  )]
  if (nrow(row_audit) != 6562L) stop("POOLING_V2_ROW_ACCOUNTING: incomplete audit", call. = FALSE)
  data.table::setorder(row_audit, v1_effect_row_id)

  out <- normalizePath(output_dir, winslash = "/", mustWork = FALSE)
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  .stage4a_pooling_v2_write_csv(output, file.path(out, "effect_estimates_v2.csv"))
  .stage4a_pooling_v2_write_csv(family_estimates, file.path(out, "pooling_family_estimates_v2.csv"))
  .stage4a_pooling_v2_write_csv(row_audit, file.path(out, "row_inclusion_exclusion_audit_v2.csv"))
  copies <- c(
    pooling_family_registry_v2 = "stage4a_pooling_family_registry_v2.csv",
    component_evidence_registry_v2 = "stage4a_component_evidence_registry_v2.csv",
    v1_to_v2_family_crosswalk = "stage4a_pooling_v1_to_v2_crosswalk.csv",
    m11_m12_duplicate_resolution_audit = "stage4a_m11_m12_duplicate_resolution_v2.csv",
    family_compatibility_audit_v2 = "stage4a_pooling_family_compatibility_audit_v2.csv"
  )
  for (target in names(copies)) {
    ok <- file.copy(path("metadata", copies[[target]]), file.path(out, paste0(target, ".csv")),
                    overwrite = TRUE, copy.mode = FALSE, copy.date = FALSE)
    if (!ok) stop("POOLING_V2_COPY: failed to copy ", target, call. = FALSE)
  }
  source_hash <- .stage4a_pooling_v2_file_hash(source_file)
  invalidation <- data.table::fread(path("metadata", "stage4a_pooling_v1_invalidation_manifest.csv"),
                                    na.strings = NULL)
  invalidation[, `:=`(
    superseding_artifact = "outputs/stage4a_pooling_repair_v2/effect_estimates_v2.csv",
    superseding_columns = "partial_pool_estimate_v2|partial_pool_standard_error_v2",
    supersession_status = "SUPERSEDED_BY_VERSIONED_V2_FIELDS"
  )]
  .stage4a_pooling_v2_write_csv(invalidation,
    file.path(out, "invalidation_supersession_manifest_v2.csv"))

  code_files <- c("R/stage4a_pooling_repair_spec_v2.R",
                  "R/stage4a_pooling_repair_execute_v2.R",
                  "scripts/run_stage4a_pooling_repair_v2.R")
  execution_record <- list(
    execution_version = "stage4a_aggregate_pooling_repair_execution_v2",
    status = "COMPLETE_AGGREGATE_ONLY",
    pre_execution_spec_commit = pre_execution_spec_commit,
    execution_code_commit = execution_code_commit,
    record_time_basis = "execution_code_commit_time",
    input_artifacts = list(
      effect_estimates_v1 = list(path = "outputs/stage4a_results/effect_estimates.csv",
                                 sha256 = source_hash),
      authoritative_scope = list(rows = 6562L, v1_families = 112L),
      protected_inputs_used = FALSE
    ),
    code_hashes = stats::setNames(lapply(code_files, function(file) {
      .stage4a_pooling_v2_file_hash(path(file))
    }), code_files),
    results = list(
      v2_families = nrow(family_estimates),
      estimable_families = sum(family_estimates$estimability_status == "ESTIMABLE"),
      non_estimable_families = sum(family_estimates$estimability_status != "ESTIMABLE"),
      selected_evidence_rows = nrow(selected),
      estimated_evidence_rows = sum(is.finite(estimated$partial_pool_estimate_v2)),
      non_estimable_model_status_rows = sum(
        estimated$numeric_input_reason_code == "NON_ESTIMABLE_MODEL_STATUS"),
      duplicate_rows_excluded = sum(!mapped$included_in_future_estimator),
      unaffected_fields_exact = TRUE
    )
  )
  .stage4a_pooling_v2_write_text_lf(
    yaml::as.yaml(execution_record, line.sep = "\n"),
    file.path(out, "execution_record_v2.yml")
  )
  comparison <- c(
    "# Stage 4A aggregate pooling repair v2 comparison",
    "",
    "- Authoritative invalid v1 scope: 6,562 finite rows in 112 historical families.",
    paste0("- Compatible v2 families: ", nrow(family_estimates), "."),
    paste0("- Estimable v2 families: ", sum(family_estimates$estimability_status == "ESTIMABLE"), "."),
    paste0("- Non-estimable v2 families: ", sum(family_estimates$estimability_status != "ESTIMABLE"), "."),
    paste0("- Primary-representation rows with v2 posterior estimates: ",
           sum(is.finite(estimated$partial_pool_estimate_v2)), "."),
    paste0("- Noncompleted model rows retained as explicit NA: ",
           sum(estimated$numeric_input_reason_code == "NON_ESTIMABLE_MODEL_STATUS"),
           " (`NON_ESTIMABLE_MODEL_STATUS`)."),
    paste0("- Duplicate M11/M12 representations excluded: ", sum(!mapped$included_in_future_estimator), "."),
    "- Duplicate exclusion reason: `EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION`.",
    "- All unaffected individual estimates, standard errors, intervals, p-values, n, status, multiplicity families, and BH q-values match v1 exactly as serialized fields.",
    "- Protected inputs used: no. The repair consumed tracked aggregate inputs and frozen metadata only.",
    "- Interpretation: pooled and individual results remain checklist-conditional associations, not causal effects, population abundance, biomass, occupancy, or movement."
  )
  .stage4a_pooling_v2_write_text_lf(
    comparison, file.path(out, "pooling_repair_comparison_v2.md")
  )

  manifest_exclusions <- "output_hash_manifest_v2.csv"
  output_files <- sort(list.files(out, recursive = FALSE, full.names = TRUE))
  output_files <- output_files[basename(output_files) != manifest_exclusions]
  hashes <- data.table::data.table(
    artifact_path = paste0("outputs/stage4a_pooling_repair_v2/", basename(output_files)),
    sha256 = vapply(output_files, .stage4a_pooling_v2_file_hash, character(1L)),
    bytes = as.numeric(file.info(output_files)$size)
  )
  .stage4a_pooling_v2_write_csv(hashes, file.path(out, manifest_exclusions))
  invisible(list(output = output, family_estimates = family_estimates,
                 row_audit = row_audit, hashes = hashes))
}
