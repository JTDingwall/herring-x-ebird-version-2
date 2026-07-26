#!/usr/bin/env Rscript

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
suppressPackageStartupMessages({
  library(data.table)
  library(digest)
  library(lme4)
  library(yaml)
})
source(file.path("R", "stage4a_core.R"), local = FALSE)
source(file.path("R", "stage4a_production.R"), local = FALSE)
source(file.path("R", "post_stage4a_sog_event_study_v1.R"), local = FALSE)
source(file.path("R", "post_stage4a_distance_band_sensitivity_v2.R"),
       local = FALSE)

acknowledgement <- "through_2025_distance_band_terrestrial_controls_v1"
if (!identical(
    Sys.getenv("POST_STAGE4A_DISTANCE_BAND_FOLLOWUP_AUTHORIZED"),
    acknowledgement
)) {
  stop("CONTROL_PRODUCTION_AUTHORIZATION_GATE: exact acknowledgement required",
       call. = FALSE)
}

code_files <- c(
  "scripts/preflight_distance_band_controls_v1.R",
  "scripts/build_distance_band_followup_archived_v1.R",
  "scripts/run_distance_band_controls_v1.R",
  "scripts/run_distance_band_controls_v1.ps1",
  "metadata/post_stage4a_distance_band_followup_authorization_v1.yml",
  "metadata/post_stage4a_distance_band_followup_spec_v1.yml",
  "metadata/post_stage4a_distance_band_followup_control_selection_v1.yml"
)
dirty <- system2(
  "git",
  c("status", "--porcelain", "--untracked-files=all", "--", code_files),
  stdout = TRUE, stderr = TRUE
)
if (length(dirty) && any(nzchar(dirty))) {
  stop("CONTROL_PRODUCTION_COMMIT_GATE: code and selection must be committed",
       call. = FALSE)
}
execution_commit <- system2(
  "git", c("rev-parse", "HEAD"), stdout = TRUE
)
if (length(execution_commit) != 1L ||
    !grepl("^[0-9a-f]{40}$", execution_commit)) {
  stop("CONTROL_PRODUCTION_COMMIT_GATE: cannot resolve execution commit",
       call. = FALSE)
}

selection <- yaml::read_yaml(
  "metadata/post_stage4a_distance_band_followup_control_selection_v1.yml"
)
selected_names <- c(
  selection$mandatory_control, selection$selected_second_control
)
if (length(selected_names) != 2L ||
    !identical(selected_names[[1L]], "American Robin") ||
    !selected_names[[2L]] %in%
      c("Chestnut-backed Chickadee", "Dark-eyed Junco")) {
  stop("CONTROL_PRODUCTION_SELECTION_GATE: invalid committed selection",
       call. = FALSE)
}

protected_dir <- file.path(
  "data", "derived", "post_stage4a_distance_band_followup_v1_protected"
)
output_dir <- "outputs/post_stage4a_distance_band_followup_v1"
extract_file <- file.path(
  protected_dir, "control_candidate_rows_pre2026.tsv"
)
if (!file.exists(extract_file) || file.info(extract_file)$size == 0) {
  stop("CONTROL_PRODUCTION_EXTRACT_GATE: protected preflight extract absent",
       call. = FALSE)
}
dir.create(file.path(protected_dir, "checkpoints"),
           recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

protected_files <- c(
  events = file.path(
    "data", "derived", "stage4a_protected",
    "stage4a_event_metadata.tsv.gz"
  ),
  links_archived = file.path(
    "data", "derived", "stage3_phase2_protected",
    "metadata_source_point_links.tsv.gz"
  ),
  links_extended = file.path(
    "data", "derived",
    "post_stage4a_distance_band_sensitivity_v2_protected",
    "link_builder", "metadata_source_point_links.tsv.gz"
  ),
  control_extract = extract_file
)
if (!all(file.exists(protected_files))) {
  stop("CONTROL_PRODUCTION_INPUT_GATE: protected input absent",
       call. = FALSE)
}
protected_hashes <- vapply(
  protected_files, .post_stage4a_sha256_v1, character(1L)
)
expected_link_hashes <- c(
  links_archived =
    "f26197d0a71fd177e77774ec9e5596563c127ec8eb0f948042aff51ad805567b",
  links_extended =
    "06a34a4d3880f2dd3a969d9976b901eff855ff7362e86ae40d75a38edd697dc2"
)
if (!identical(protected_hashes[names(expected_link_hashes)],
               expected_link_hashes)) {
  stop("CONTROL_PRODUCTION_LINK_HASH_GATE: link cache changed",
       call. = FALSE)
}

ebd_names <- c(
  "CATEGORY", "TAXON CONCEPT ID", "COMMON NAME", "SCIENTIFIC NAME",
  "OBSERVATION COUNT", "BEHAVIOR CODE",
  "SAMPLING EVENT IDENTIFIER", "OBSERVATION DATE"
)
ebd <- fread(
  extract_file, sep = "\t", header = TRUE, select = ebd_names,
  quote = "", na.strings = c("", "NA"), showProgress = FALSE
)
setnames(
  ebd, ebd_names,
  c(
    "category", "taxon_concept_id", "common_name", "scientific_name",
    "observation_count", "behavior_code", "source_id", "observation_date"
  )
)
ebd[, observation_date := as.IDate(observation_date)]
if (any(ebd$observation_date > as.IDate("2025-12-31"), na.rm = TRUE)) {
  stop("CONTROL_PRODUCTION_YEAR_GATE: 2026+ response row persisted",
       call. = FALSE)
}
ebd <- ebd[category == "species" & common_name %chin% selected_names]
if (!setequal(unique(ebd$common_name), selected_names)) {
  stop("CONTROL_PRODUCTION_TAXON_GATE: selected control missing",
       call. = FALSE)
}
taxonomy <- ebd[, .(
  scientific_name = paste(sort(unique(scientific_name)), collapse = ";")
), by = common_name]
if (any(grepl(";", taxonomy$scientific_name, fixed = TRUE))) {
  stop("CONTROL_PRODUCTION_TAXONOMY_GATE: scientific-name ambiguity",
       call. = FALSE)
}

sed_cache <- readRDS(file.path(
  "outputs", "input_audit_local", "stage2", "sed_stage2_cache.rds"
))
cross <- as.data.table(sed_cache$cross_private)[
  , .(source_id, analysis_id)
]
if (anyDuplicated(cross$source_id)) {
  stop("CONTROL_PRODUCTION_SOURCE_JOIN_GATE: crosswalk key duplicated",
       call. = FALSE)
}
setkey(cross, source_id)
ebd <- cross[ebd, on = "source_id", nomatch = 0L]
if (!nrow(ebd)) {
  stop("CONTROL_PRODUCTION_SOURCE_JOIN_GATE: no selected rows joined",
       call. = FALSE)
}

parse_state <- function(x) {
  raw <- trimws(as.character(x))
  numeric_syntax <- grepl("^[0-9]+$", raw)
  lower_syntax <- grepl(
    "^(>=|>|at least[[:space:]]+)?[0-9]+[+]?$",
    raw, ignore.case = TRUE
  ) & !numeric_syntax
  data.table(
    count_state = fifelse(
      toupper(raw) == "X", "X",
      fifelse(
        numeric_syntax, "numeric",
        fifelse(lower_syntax, "lower_bound", "ambiguity_affected")
      )
    ),
    numeric_count = fifelse(numeric_syntax, as.numeric(raw), NA_real_),
    lower_bound_count = fifelse(
      lower_syntax, as.numeric(gsub("[^0-9]", "", raw)), NA_real_
    )
  )
}
states <- parse_state(ebd$observation_count)
ebd[, c("count_state", "numeric_count", "lower_bound_count") := states]
collapsed <- ebd[, {
  signatures <- unique(paste(
    count_state, numeric_count, lower_bound_count, sep = "|"
  ))
  if (length(signatures) == 1L) {
    .(
      count_state = count_state[[1L]],
      numeric_count = numeric_count[[1L]],
      lower_bound_count = lower_bound_count[[1L]],
      source_report_disagreement = FALSE
    )
  } else {
    .(
      count_state = "ambiguity_affected",
      numeric_count = NA_real_,
      lower_bound_count = NA_real_,
      source_report_disagreement = TRUE
    )
  }
}, by = .(analysis_id, common_name)]
if (anyDuplicated(collapsed[, .(analysis_id, common_name)])) {
  stop("CONTROL_PRODUCTION_COLLAPSE_GATE: duplicate analysis outcome",
       call. = FALSE)
}
hash_analysis_event <- function(x) {
  substr(vapply(
    paste0("analysis_event|", x),
    digest, character(1L), algo = "sha256", serialize = FALSE
  ), 1L, 24L)
}
collapsed[, analysis_event_token := hash_analysis_event(analysis_id)]

events_all <- .stage4a_prepare_events(
  .stage4a_read_gz(protected_files[["events"]])
)
if (nrow(events_all) != 239934L ||
    any(as.integer(events_all$checklist_year) > 2025L)) {
  stop("CONTROL_PRODUCTION_EVENT_GATE: protected population changed",
       call. = FALSE)
}
selected <- events_all$region == "SoG" &
  events_all$checklist_year >= 2005L &
  events_all$checklist_year <= 2025L
if (anyNA(selected) || sum(selected) != 217200L) {
  stop("CONTROL_PRODUCTION_SOG_GATE: expected 217200 checklists",
       call. = FALSE)
}
events <- events_all[selected, , drop = FALSE]
rm(events_all)
stage4a_validate_folds(events)

archived <- .stage4a_read_gz(protected_files[["links_archived"]])
extended <- .stage4a_read_gz(protected_files[["links_extended"]])
link_key <- function(x) paste(
  x$analysis_event_token, x$herring_source_token, sep = "\r"
)
archived_key <- link_key(archived)
extended_key <- link_key(extended)
if (anyDuplicated(archived_key) || anyDuplicated(extended_key) ||
    !all(archived_key %in% extended_key)) {
  stop("CONTROL_PRODUCTION_LINK_RECONCILIATION_GATE: failed",
       call. = FALSE)
}
archived$link_provenance__ <- "archived_0_20"
extra <- extended[!extended_key %in% archived_key, , drop = FALSE]
if (!nrow(extra) ||
    any(as.numeric(extra$distance_km) < 20 |
        as.numeric(extra$distance_km) > 26.0001)) {
  stop("CONTROL_PRODUCTION_LINK_EXTENSION_GATE: expected 20-26 only",
       call. = FALSE)
}
extra$link_provenance__ <- "new_20_26"
links <- rbind(archived, extra)
joint <- post_stage4a_add_distance_band_exposure_v2(events, links)
events <- joint$events
exposure_support <- joint$support
rm(archived, extended, extra, links, joint)

event_tokens <- as.character(events$analysis_event_token)
terms <- post_stage4a_distance_band_terms_v2()
model_results <- list()
for (species in selected_names) {
  z <- collapsed[common_name == species]
  idx <- match(event_tokens, z$analysis_event_token)
  dat <- events
  dat$detection <- ifelse(is.na(idx), 0L, 1L)
  ambiguity <- !is.na(idx) &
    z$count_state[idx] == "ambiguity_affected"
  dat$detection[ambiguity] <- NA_integer_
  dat$numeric_count <- z$numeric_count[idx]
  dat$analysis_taxon_id <- paste0(
    "ctl_", substr(digest(
      paste0("terrestrial_control|", species),
      algo = "sha256", serialize = FALSE
    ), 1L, 12L)
  )
  model_id <- paste0(
    "SOG_DISTANCE_BAND_CONTROL_",
    toupper(gsub("[^A-Za-z0-9]+", "_", species)),
    "_v1"
  )
  for (outcome in c(
      "detection", "positive_numeric_count_given_detection"
  )) {
    checkpoint <- file.path(
      protected_dir, "checkpoints",
      paste0(gsub("[^A-Za-z0-9]+", "_", tolower(species)),
             "_", outcome, ".rds")
    )
    signature <- paste(
      execution_commit, species, outcome,
      protected_hashes,
      .post_stage4a_sha256_v1(
        "metadata/post_stage4a_distance_band_followup_spec_v1.yml"
      ),
      .post_stage4a_sha256_v1(
        "metadata/post_stage4a_distance_band_followup_control_selection_v1.yml"
      ),
      sep = "|", collapse = "|"
    )
    result <- post_stage4a_fit_distance_band_component_v2(
      dat, outcome, checkpoint, signature
    )
    result$effects$model_version_id <- model_id
    result$effects$analysis_taxon_id <- unique(dat$analysis_taxon_id)
    result$effects$unit_label <- species
    result$diagnostic$model_version_id <- model_id
    result$diagnostic$analysis_taxon_id <- unique(dat$analysis_taxon_id)
    result$diagnostic$unit_label <- species
    for (part in c(
        "term_support", "fixed_effects", "exposure_covariance"
    )) {
      result[[part]]$model_version_id <- model_id
      result[[part]]$analysis_taxon_id <- unique(dat$analysis_taxon_id)
      result[[part]]$unit_label <- species
    }
    model_results[[paste(species, outcome, sep = "\r")]] <- result
  }
}

effects <- rbindlist(lapply(model_results, `[[`, "effects"), fill = TRUE)
diagnostics <- rbindlist(
  lapply(model_results, `[[`, "diagnostic"), fill = TRUE
)
term_support <- rbindlist(
  lapply(model_results, `[[`, "term_support"), fill = TRUE
)
fixed_effects <- rbindlist(
  lapply(model_results, `[[`, "fixed_effects"), fill = TRUE
)
exposure_covariance <- rbindlist(
  lapply(model_results, `[[`, "exposure_covariance"), fill = TRUE
)
support_lookup <- unique(as.data.table(exposure_support)[
  , .(term, band, period)
])
term_support <- merge(
  term_support, support_lookup, by = "term", all.x = TRUE, sort = FALSE
)
if (anyNA(term_support$band) || anyNA(term_support$period)) {
  stop("CONTROL_PRODUCTION_SUPPORT_JOIN_GATE: unmatched term",
       call. = FALSE)
}

effects[, bh_family_id := paste(
  gsub("[^A-Za-z0-9]+", "_", tolower(unit_label)),
  outcome, period, "13_bands", sep = "__"
)]
effects[, bh_family_size := .N, by = bh_family_id]
effects[, p_value_bh_13 := p.adjust(p_value, method = "BH"),
        by = bh_family_id]
effects[, significant_nominal_0_05 := p_value < 0.05]
effects[, significant_bh_0_05 := p_value_bh_13 < 0.05]
if (any(effects$bh_family_size != 13L)) {
  stop("CONTROL_PRODUCTION_BH_GATE: expected 13-member families",
       call. = FALSE)
}

cov_matrix <- function(x, coefficient_names) {
  key <- paste(x$row_coefficient, x$column_coefficient, sep = "\r")
  if (anyDuplicated(key)) {
    stop("CONTROL_PRODUCTION_COVARIANCE_KEY_GATE", call. = FALSE)
  }
  lookup <- setNames(x$covariance, key)
  out <- outer(
    coefficient_names, coefficient_names,
    Vectorize(function(a, b) lookup[[paste(a, b, sep = "\r")]])
  )
  dimnames(out) <- list(coefficient_names, coefficient_names)
  if (anyNA(out) || max(abs(out - t(out))) > 1e-10) {
    stop("CONTROL_PRODUCTION_COVARIANCE_GEOMETRY_GATE",
         call. = FALSE)
  }
  out
}
z95 <- 1.959963984540054
bands <- post_stage4a_distance_band_spec_v2()$band
tight_rows <- list()
profile_rows <- list()
for (species in selected_names) {
  for (outcome in unique(effects$outcome)) {
    f <- fixed_effects[
      unit_label == species & get("outcome") == outcome
    ]
    beta <- setNames(f$estimate, f$coefficient)
    beta <- beta[grep("^db_band_", names(beta))]
    cv <- exposure_covariance[
      unit_label == species & get("outcome") == outcome
    ]
    v <- cov_matrix(cv, names(beta))
    calc <- function(weights) {
      w <- setNames(rep(0, length(beta)), names(beta))
      w[names(weights)] <- weights
      estimate <- sum(w * beta)
      se <- sqrt(drop(t(w) %*% v %*% w))
      c(
        estimate = estimate, standard_error = se,
        conf_low = estimate - z95 * se,
        conf_high = estimate + z95 * se,
        p_value = 2 * pnorm(-abs(estimate / se))
      )
    }
    tight <- rbindlist(lapply(bands, function(band) {
      out <- calc(setNames(
        c(1, -1),
        paste("db", band, c("spawn_start", "immediate_pre"), sep = "_")
      ))
      data.table(
        species = species, outcome = outcome, band = band,
        estimate = out[["estimate"]],
        standard_error = out[["standard_error"]],
        conf_low = out[["conf_low"]], conf_high = out[["conf_high"]],
        ratio = exp(out[["estimate"]]),
        ratio_conf_low = exp(out[["conf_low"]]),
        ratio_conf_high = exp(out[["conf_high"]]),
        p_value = out[["p_value"]]
      )
    }))
    tight[, p_value_bh_13 := p.adjust(p_value, method = "BH")]
    tight[, significant_bh_0_05 := p_value_bh_13 < 0.05]
    tight_rows[[paste(species, outcome)]] <- tight

    cmat <- matrix(
      0, nrow = length(bands), ncol = length(beta),
      dimnames = list(bands, names(beta))
    )
    for (i in seq_along(bands)) {
      cmat[i, paste(
        "db", bands[[i]],
        c("spawn_start", "early_pre", "immediate_pre"), sep = "_"
      )] <- c(1, -0.5, -0.5)
    }
    theta <- drop(cmat %*% beta)
    vtheta <- cmat %*% v %*% t(cmat)
    statistic <- drop(t(theta) %*% solve(vtheta, theta))
    profile_rows[[paste(species, outcome)]] <- data.table(
      species = species, outcome = outcome,
      contrast = "spawn_start_profile_minus_equal_duration_pooled_pre",
      statistic = statistic,
      degrees_of_freedom = 13L,
      p_value = pchisq(statistic, 13L, lower.tail = FALSE)
    )
  }
}
tight <- rbindlist(tight_rows)
profile_tests <- rbindlist(profile_rows)

near <- effects[
  band == "band_0_2" &
    period %in% c(
      "early_pre", "immediate_pre", "spawn_start",
      "early_egg", "late_egg", "active_0_14"
    )
]
near_tight <- tight[band == "band_0_2"]
classification_rows <- list()
for (species in selected_names) {
  for (outcome in unique(effects$outcome)) {
    spawn <- near[
      unit_label == species & get("outcome") == outcome &
        period == "spawn_start"
    ]
    jump <- near_tight[
      get("species") == species & get("outcome") == outcome
    ]
    upward <- spawn$estimate > 0 & spawn$p_value_bh_13 < 0.05 &
      jump$estimate > 0 & jump$p_value_bh_13 < 0.05
    downward <- spawn$estimate < 0 & spawn$p_value_bh_13 < 0.05 &
      jump$estimate < 0 & jump$p_value_bh_13 < 0.05
    classification <- if (upward) {
      "upward_near_band_spike_at_recorded_event_midpoint"
    } else if (downward) {
      "downward_near_band_spike_at_recorded_event_midpoint"
    } else {
      paste0(
        "no_BH_significant_near_band_spike_relative_to_both_",
        "same_band_baseline_and_immediate_pre"
      )
    }
    classification_rows[[paste(species, outcome)]] <- data.table(
      species = species, outcome = outcome,
      classification = classification,
      spawn_start_ratio_vs_baseline = spawn$ratio,
      spawn_start_conf_low = spawn$ratio_conf_low,
      spawn_start_conf_high = spawn$ratio_conf_high,
      spawn_start_p_bh_13 = spawn$p_value_bh_13,
      spawn_start_vs_immediate_pre_ratio = jump$ratio,
      spawn_start_vs_immediate_pre_conf_low = jump$ratio_conf_low,
      spawn_start_vs_immediate_pre_conf_high = jump$ratio_conf_high,
      spawn_start_vs_immediate_pre_p_bh_13 = jump$p_value_bh_13
    )
  }
}
classification <- rbindlist(classification_rows)

fwrite(effects, file.path(
  output_dir, "terrestrial_control_distance_band_effects_v1.csv"
), quote = TRUE, na = "")
fwrite(diagnostics, file.path(
  output_dir, "terrestrial_control_model_diagnostics_v1.csv"
), quote = TRUE, na = "")
fwrite(term_support, file.path(
  output_dir, "terrestrial_control_model_term_support_v1.csv"
), quote = TRUE, na = "")
fwrite(fixed_effects, file.path(
  output_dir, "terrestrial_control_fixed_effects_v1.csv"
), quote = TRUE, na = "")
fwrite(exposure_covariance, file.path(
  output_dir, "terrestrial_control_exposure_covariance_v1.csv"
), quote = TRUE, na = "")
fwrite(tight, file.path(
  output_dir, "terrestrial_control_tight_contrasts_v1.csv"
), quote = TRUE, na = "")
fwrite(profile_tests, file.path(
  output_dir, "terrestrial_control_direct_profile_tests_v1.csv"
), quote = TRUE, na = "")
fwrite(near, file.path(
  output_dir, "terrestrial_control_near_band_timing_v1.csv"
), quote = TRUE, na = "")
fwrite(classification, file.path(
  output_dir, "terrestrial_control_near_band_classification_v1.csv"
), quote = TRUE, na = "")

period_order <- c(
  "baseline", "early_pre", "immediate_pre",
  "spawn_start", "early_egg", "late_egg"
)
period_labels <- c(
  "Baseline\n-28 to -15", "Early pre\n-14 to -8",
  "Immediate pre\n-7 to -1", "Event midpoint\n0 to 3",
  "Early egg\n4 to 14", "Late egg\n15 to 28"
)
baseline <- CJ(
  unit_label = selected_names,
  outcome = unique(effects$outcome)
)
baseline[, `:=`(
  period = "baseline", ratio = 1,
  ratio_conf_low = 1, ratio_conf_high = 1
)]
plot_data <- rbindlist(list(
  baseline,
  effects[
    band == "band_0_2" &
      contrast_type == "within_band_period_minus_baseline",
    .(
      unit_label, outcome, period,
      ratio, ratio_conf_low, ratio_conf_high
    )
  ]
), fill = TRUE)
palette <- c(
  "American Robin" = "#3B7D23",
  "Chestnut-backed Chickadee" = "#6A4C93",
  "Dark-eyed Junco" = "#6A4C93"
)
outcome_titles <- c(
  detection = "Checklist reporting",
  positive_numeric_count_given_detection =
    "Reported number, conditional on numeric detection"
)
figure_path <- file.path(
  output_dir, "terrestrial_control_near_band_timing_v1.png"
)
png(figure_path, width = 2800, height = 1900, res = 220)
par(mfrow = c(2, 2), oma = c(4, 2, 5, 1), family = "sans")
for (outcome in names(outcome_titles)) {
  outcome_data <- plot_data[get("outcome") == outcome]
  finite <- c(outcome_data$ratio_conf_low, outcome_data$ratio_conf_high)
  finite <- finite[is.finite(finite) & finite > 0]
  ylim <- range(finite)
  padding <- exp(0.12 * diff(log(ylim)))
  ylim <- c(ylim[[1L]] / padding, ylim[[2L]] * padding)
  for (species in selected_names) {
    d <- outcome_data[unit_label == species]
    d <- d[match(period_order, d$period)]
    x <- seq_along(period_order)
    par(mar = c(7.2, 5.5, 3.3, 1.2))
    plot(
      x, d$ratio, type = "b", log = "y", ylim = ylim,
      xaxt = "n", xlab = "", ylab = "Ratio versus same-band baseline",
      pch = 21, bg = "white", col = palette[[species]],
      lwd = 2, main = paste(species, "-", outcome_titles[[outcome]]),
      bty = "l"
    )
    axis(1, at = x, labels = period_labels, las = 2,
         tick = FALSE, cex.axis = 0.72)
    abline(h = 1, lty = 3, col = "#555555")
    use <- d$period != "baseline"
    segments(
      x[use], d$ratio_conf_low[use],
      x[use], d$ratio_conf_high[use],
      col = palette[[species]], lwd = 1.3
    )
    points(
      x, d$ratio, pch = 21, bg = "white",
      col = palette[[species]], lwd = 1.5
    )
  }
}
mtext(
  "Terrestrial negative controls within 0-<2 km of recorded herring source points",
  outer = TRUE, side = 3, line = 2.2, cex = 1.25, font = 2
)
mtext(
  "Same 13-band mixed-model machinery; ratios versus each band's days -28 to -15 baseline; 95% intervals",
  outer = TRUE, side = 3, line = 0.7, cex = 0.78
)
mtext(
  "Event time is anchored to the recorded StartDate-EndDate midpoint, not directly observed biological onset.",
  outer = TRUE, side = 1, line = 1.5, cex = 0.72
)
dev.off()

execution_record <- list(
  execution_version = "post_stage4a_distance_band_followup_controls_v1",
  executed_at_utc = format(
    as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"
  ),
  execution_code_commit = execution_commit,
  authorization_record =
    "metadata/post_stage4a_distance_band_followup_authorization_v1.yml",
  specification_record =
    "metadata/post_stage4a_distance_band_followup_spec_v1.yml",
  control_selection_record =
    "metadata/post_stage4a_distance_band_followup_control_selection_v1.yml",
  selected_controls = selected_names,
  analysis_status = "post_result_exploratory_estimand_refinement",
  registered_49_species_family_changed = FALSE,
  controls_enter_primary_BH_family = FALSE,
  historical_stage4a_outputs_modified = FALSE,
  historical_distance_band_models_refit = FALSE,
  region = "SoG",
  years = c(2005L, 2025L),
  eligible_checklists = nrow(events),
  model_components = nrow(diagnostics),
  protected_input_hashes = as.list(protected_hashes),
  records_2026_plus_persisted = 0L,
  manuscript_edited = FALSE,
  final_gate = "PASS_PENDING_HUMAN_TERRESTRIAL_CONTROL_REVIEW"
)
yaml::write_yaml(
  execution_record,
  file.path(output_dir, "terrestrial_control_execution_record_v1.yml")
)

output_files <- list.files(
  output_dir, full.names = TRUE,
  pattern = "terrestrial_control_.*\\.(csv|yml|png)$"
)
manifest <- data.table(
  file = basename(output_files),
  sha256 = vapply(
    output_files, digest, character(1L),
    algo = "sha256", file = TRUE, serialize = FALSE
  )
)
setorder(manifest, file)
fwrite(
  manifest,
  file.path(output_dir, "terrestrial_control_hash_manifest_v1.csv"),
  quote = TRUE, na = ""
)
message(
  "CONTROL_PRODUCTION_PASS: fitted ", nrow(diagnostics),
  " components for ", paste(selected_names, collapse = " and ")
)
