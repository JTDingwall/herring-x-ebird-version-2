root <- normalizePath(getOption("mer.root", "."), winslash = "/", mustWork = TRUE)
source_root <- normalizePath(
  getOption("mer.source_root", root), winslash = "/", mustWork = TRUE
)
out_dir <- file.path(root, "figures_out")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

read_csv <- function(path) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

write_csv <- function(x, filename) {
  utils::write.csv(
    x, file.path(out_dir, filename), row.names = FALSE,
    na = "", fileEncoding = "UTF-8"
  )
}

assert_unique <- function(x, columns, label) {
  key <- do.call(paste, c(x[columns], sep = "\r"))
  if (anyDuplicated(key)) {
    stop(label, ": duplicate ", paste(columns, collapse = " + "), call. = FALSE)
  }
}

checkpoint_dir <- file.path(
  source_root, "data", "derived",
  "post_stage4a_staged_refit_stage2_v1", "checkpoints", "real_family"
)
checkpoint_paths <- list.files(
  checkpoint_dir, pattern = "_rds$", full.names = TRUE
)
if (length(checkpoint_paths) != 98L) {
  stop("PROFILE_CHECKPOINT_GATE: expected 98 checkpoints; found ",
       length(checkpoint_paths), call. = FALSE)
}

contrast_env <- new.env(parent = baseenv())
sys.source(
  file.path(source_root, "R", "post_stage4a_sog_event_study_v1.R"),
  envir = contrast_env
)

registry <- read_csv(
  file.path(source_root, "metadata", "canonical_species_registry.csv")
)
assert_unique(registry, "analysis_taxon_id", "canonical species registry")

profile_contrasts <- c(
  "did_early_pre", "did_immediate_pre", "did_pre_14_day",
  "did_spawn_start", "did_early_egg", "did_late_egg",
  "did_active_0_14_day"
)
period_text <- c(
  did_early_pre = "Early pre (-14 to -8 d)",
  did_immediate_pre = "Immediate pre (-7 to -1 d)",
  did_pre_14_day = "Pre-onset (-14 to -1 d)",
  did_spawn_start = "Spawn start (0 to 3 d)",
  did_early_egg = "Early egg (4 to 14 d)",
  did_late_egg = "Late egg (15 to 28 d)",
  did_active_0_14_day = "Active composite (0 to 14 d)"
)

rows <- vector("list", length(checkpoint_paths) * length(profile_contrasts))
active_check <- vector("list", length(checkpoint_paths))
row_index <- 0L

for (i in seq_along(checkpoint_paths)) {
  payload <- readRDS(checkpoint_paths[[i]])
  result <- payload$result
  diagnostic <- result$diagnostic
  if (!is.data.frame(diagnostic) || nrow(diagnostic) != 1L) {
    stop("PROFILE_DIAGNOSTIC_GATE: malformed checkpoint: ",
         basename(checkpoint_paths[[i]]), call. = FALSE)
  }
  taxon_id <- as.character(diagnostic$analysis_taxon_id[[1L]])
  outcome <- as.character(diagnostic$outcome[[1L]])
  status <- as.character(diagnostic$status[[1L]])
  n <- as.numeric(diagnostic$n[[1L]])
  registry_index <- match(taxon_id, registry$analysis_taxon_id)
  if (is.na(registry_index)) {
    stop("PROFILE_REGISTRY_JOIN_GATE: unmatched taxon ", taxon_id,
         call. = FALSE)
  }
  species <- registry$common_name[[registry_index]]
  if (!identical(species, as.character(diagnostic$species[[1L]]))) {
    stop("PROFILE_REGISTRY_JOIN_GATE: species label mismatch for ", taxon_id,
         call. = FALSE)
  }

  completed <- grepl("^completed", status)
  beta <- result$beta
  covariance <- result$covariance
  definitions <- NULL
  if (completed) {
    if (!is.numeric(beta) || is.null(names(beta)) ||
        !is.matrix(covariance) ||
        any(dim(covariance) != length(beta))) {
      stop("PROFILE_SUMMARY_GATE: missing coefficient/covariance summary for ",
           taxon_id, " / ", outcome, call. = FALSE)
    }
    covariance <- covariance[names(beta), names(beta), drop = FALSE]
    definitions <- contrast_env$post_stage4a_contrast_definitions_v1(
      names(beta)
    )
  }

  one_contrast <- function(name) {
    if (!completed) {
      return(c(
        estimate = NA_real_, standard_error = NA_real_,
        conf_low = NA_real_, conf_high = NA_real_, p_value = NA_real_
      ))
    }
    names_found <- vapply(
      definitions, function(x) x$contrast, character(1L)
    )
    index <- match(name, names_found)
    if (is.na(index) || is.null(definitions[[index]]$vector)) {
      stop("PROFILE_CONTRAST_GATE: absent contrast ", name, " for ",
           taxon_id, " / ", outcome, call. = FALSE)
    }
    vector <- definitions[[index]]$vector
    estimate <- sum(vector * beta)
    variance <- drop(t(vector) %*% covariance %*% vector)
    if (!is.finite(variance) || variance <= 0) {
      stop("PROFILE_VARIANCE_GATE: invalid variance for ", name, " / ",
           taxon_id, " / ", outcome, call. = FALSE)
    }
    standard_error <- sqrt(variance)
    c(
      estimate = estimate,
      standard_error = standard_error,
      conf_low = estimate - stats::qnorm(0.975) * standard_error,
      conf_high = estimate + stats::qnorm(0.975) * standard_error,
      p_value = 2 * stats::pnorm(-abs(estimate / standard_error))
    )
  }

  values <- lapply(profile_contrasts, one_contrast)
  names(values) <- profile_contrasts
  for (contrast in profile_contrasts) {
    row_index <- row_index + 1L
    value <- values[[contrast]]
    rows[[row_index]] <- data.frame(
      analysis_version = "post_stage4a_staged_refit_v1_s2_detectability",
      analysis_taxon_id = taxon_id,
      species = species,
      outcome = outcome,
      contrast = contrast,
      period_label = unname(period_text[[contrast]]),
      estimate = value[["estimate"]],
      standard_error = value[["standard_error"]],
      conf_low = value[["conf_low"]],
      conf_high = value[["conf_high"]],
      ratio = exp(value[["estimate"]]),
      ratio_conf_low = exp(value[["conf_low"]]),
      ratio_conf_high = exp(value[["conf_high"]]),
      p_value = value[["p_value"]],
      q_value = NA_real_,
      n = n,
      status = status,
      stringsAsFactors = FALSE
    )
  }

  if (completed) {
    active <- values[["did_active_0_14_day"]]
    pre <- values[["did_pre_14_day"]]
    definitions_names <- vapply(
      definitions, function(x) x$contrast, character(1L)
    )
    active_vector <- definitions[[
      match("did_active_0_14_day", definitions_names)
    ]]$vector
    pre_vector <- definitions[[
      match("did_pre_14_day", definitions_names)
    ]]$vector
    difference_vector <- active_vector - pre_vector
    estimate <- sum(difference_vector * beta)
    variance <- drop(
      t(difference_vector) %*% covariance %*% difference_vector
    )
    standard_error <- sqrt(variance)
    active_check[[i]] <- data.frame(
      analysis_taxon_id = taxon_id,
      outcome = outcome,
      estimate_rebuilt = estimate,
      standard_error_rebuilt = standard_error,
      ratio_rebuilt = exp(estimate),
      ratio_conf_low_rebuilt =
        exp(estimate - stats::qnorm(0.975) * standard_error),
      ratio_conf_high_rebuilt =
        exp(estimate + stats::qnorm(0.975) * standard_error),
      stringsAsFactors = FALSE
    )
  } else {
    active_check[[i]] <- data.frame(
      analysis_taxon_id = taxon_id,
      outcome = outcome,
      estimate_rebuilt = NA_real_,
      standard_error_rebuilt = NA_real_,
      ratio_rebuilt = NA_real_,
      ratio_conf_low_rebuilt = NA_real_,
      ratio_conf_high_rebuilt = NA_real_,
      stringsAsFactors = FALSE
    )
  }
}

profiles <- do.call(rbind, rows)
assert_unique(
  profiles, c("analysis_taxon_id", "outcome", "contrast"),
  "Stage 2 period profiles"
)
if (nrow(profiles) != 686L ||
    length(unique(profiles$analysis_taxon_id)) != 49L) {
  stop("PROFILE_CARDINALITY_GATE: expected 49 x 2 x 7 rows", call. = FALSE)
}

groups <- interaction(
  profiles$outcome, profiles$contrast, drop = TRUE, lex.order = TRUE
)
for (group in levels(groups)) {
  index <- which(groups == group)
  profiles$q_value[index] <- stats::p.adjust(
    profiles$p_value[index], method = "BH", n = 49L
  )
}

primary_source_path <- file.path(
  source_root, "outputs", "post_stage4a_staged_refit_stage2_v1",
  "s2_detectability", "estimates_49x2.csv"
)
primary_source <- read_csv(primary_source_path)
if (nrow(primary_source) != 98L ||
    length(unique(primary_source$analysis_taxon_id)) != 49L) {
  stop("PRIMARY_CARDINALITY_GATE: expected 49 x 2 rows", call. = FALSE)
}
assert_unique(
  primary_source, c("analysis_taxon_id", "outcome"),
  "Stage 2 primary source"
)

rebuilt <- do.call(rbind, active_check)
joined_index <- match(
  paste(primary_source$analysis_taxon_id, primary_source$outcome),
  paste(rebuilt$analysis_taxon_id, rebuilt$outcome)
)
if (anyNA(joined_index) || anyDuplicated(joined_index)) {
  stop("PRIMARY_VALIDATION_JOIN_GATE: expected a 1:1 primary join",
       call. = FALSE)
}
joined <- rebuilt[joined_index, , drop = FALSE]
completed <- grepl("^completed", primary_source$status)
differences <- c(
  primary_source$estimate[completed] - joined$estimate_rebuilt[completed],
  primary_source$standard_error[completed] -
    joined$standard_error_rebuilt[completed],
  primary_source$ratio[completed] - joined$ratio_rebuilt[completed],
  primary_source$ratio_conf_low[completed] -
    joined$ratio_conf_low_rebuilt[completed],
  primary_source$ratio_conf_high[completed] -
    joined$ratio_conf_high_rebuilt[completed]
)
if (max(abs(differences), na.rm = TRUE) > 1e-9) {
  stop("PRIMARY_VALIDATION_GATE: rebuilt checkpoint contrasts do not match ",
       "the frozen Stage 2 primary table", call. = FALSE)
}

primary_public <- primary_source[c(
  "species", "outcome", "ratio", "ratio_conf_low", "ratio_conf_high",
  "q_value", "n", "status"
)]
write_csv(primary_public, "tableS_primary_contrast_49x2_stage2.csv")
write_csv(profiles, "tableS_period_profiles_49x2_stage2.csv")

distance_source_path <- file.path(
  source_root, "outputs", "post_stage4a_staged_refit_stage2_v1",
  "s2_detectability", "distance_bands_3species.csv"
)
distance <- read_csv(distance_source_path)
if (nrow(distance) != 468L ||
    length(unique(distance$analysis_taxon_id)) != 3L ||
    length(unique(distance$band)) != 13L ||
    length(unique(distance$period)) != 6L) {
  stop("DISTANCE_CARDINALITY_GATE: expected 3 x 2 x 13 x 6 rows",
       call. = FALSE)
}
assert_unique(
  distance,
  c("analysis_taxon_id", "outcome", "band", "period"),
  "Stage 2 distance-band source"
)
distance$outcome_source <- distance$outcome
distance$outcome <- unname(c(
  detection = "checklist_reporting",
  positive_numeric_count_given_detection =
    "conditional_positive_numeric_count"
)[distance$outcome])
if (anyNA(distance$outcome)) {
  stop("DISTANCE_OUTCOME_GATE: unexpected outcome label", call. = FALSE)
}
distance$species_role <- ifelse(
  distance$unit_label == "American Robin",
  "comparison_species", "waterbird_focal_species"
)
distance_public <- distance[c(
  "model_version_id", "analysis_taxon_id", "unit_label", "species_role",
  "region", "outcome", "outcome_source", "band", "band_label", "period",
  "minimum_day", "maximum_day", "estimate", "standard_error", "conf_low",
  "conf_high", "ratio", "ratio_conf_low", "ratio_conf_high", "p_value", "n",
  "status", "bh_family_id", "bh_family_size", "p_value_bh_13"
)]
write_csv(distance_public, "tableS_distance_bands_3species_stage2.csv")

message("STAGE2_FIGURE_INPUTS=PASS")
message("PRIMARY_ROWS=", nrow(primary_public))
message("PROFILE_ROWS=", nrow(profiles))
message("DISTANCE_ROWS=", nrow(distance_public))
message("PRIMARY_REBUILD_MAX_ABS_DIFF=",
        format(max(abs(differences), na.rm = TRUE), scientific = TRUE))
