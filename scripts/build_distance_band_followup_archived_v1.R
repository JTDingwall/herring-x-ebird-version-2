#!/usr/bin/env Rscript

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
suppressPackageStartupMessages({
  library(data.table)
  library(digest)
})
source(file.path("R", "stage4a_core.R"), local = FALSE)
source(file.path("R", "stage4a_production.R"), local = FALSE)

output_dir <- "outputs/post_stage4a_distance_band_followup_v1"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
z95 <- 1.959963984540054
bands <- paste0("band_", seq(0, 24, 2), "_", seq(2, 26, 2))
band_labels <- paste0(
  seq(0, 24, 2), "-", ifelse(seq(2, 26, 2) == 26, "", "<"),
  seq(2, 26, 2), " km"
)

sources <- list(
  list(
    species = "Bald Eagle",
    version = "v2",
    directory = "outputs/post_stage4a_distance_band_sensitivity_v2",
    effects = "bald_eagle_distance_band_effects_v2.csv",
    fixed = "fixed_effects_v2.csv",
    covariance = "exposure_covariance_v2.csv",
    support = "joint_exposure_support_v2.csv"
  ),
  list(
    species = "Glaucous-winged Gull",
    version = "v1",
    directory = "outputs/post_stage4a_gwgu_distance_band_sensitivity_v1",
    effects = "glaucous_winged_gull_distance_band_effects_v1.csv",
    fixed = "fixed_effects_v1.csv",
    covariance = "exposure_covariance_v1.csv",
    support = "joint_exposure_support_v1.csv"
  )
)

write_csv <- function(x, name) {
  fwrite(as.data.table(x), file.path(output_dir, name), quote = TRUE, na = "")
}

covariance_matrix <- function(long, outcome, terms) {
  x <- long[long$outcome == outcome, , drop = FALSE]
  key <- paste(x$row_coefficient, x$column_coefficient, sep = "\r")
  if (anyDuplicated(key)) {
    stop("ARCHIVED_COVARIANCE_KEY_GATE: duplicate covariance cell",
         call. = FALSE)
  }
  lookup <- setNames(x$covariance, key)
  out <- outer(
    terms, terms,
    Vectorize(function(a, b) lookup[[paste(a, b, sep = "\r")]])
  )
  dimnames(out) <- list(terms, terms)
  if (anyNA(out) || max(abs(out - t(out))) > 1e-10) {
    stop("ARCHIVED_COVARIANCE_GEOMETRY_GATE: incomplete or asymmetric",
         call. = FALSE)
  }
  out
}

linear_contrasts <- function(beta, covariance, definitions) {
  terms <- names(beta)
  do.call(rbind, lapply(definitions, function(def) {
    w <- setNames(rep(0, length(terms)), terms)
    if (!all(names(def$weights) %in% terms)) {
      stop("ARCHIVED_CONTRAST_TERM_GATE: coefficient absent",
           call. = FALSE)
    }
    w[names(def$weights)] <- def$weights
    estimate <- sum(w * beta)
    variance <- drop(t(w) %*% covariance %*% w)
    if (!is.finite(variance) || variance <= 0) {
      stop("ARCHIVED_CONTRAST_VARIANCE_GATE: invalid variance",
           call. = FALSE)
    }
    se <- sqrt(variance)
    data.frame(
      band = def$band,
      band_label = band_labels[match(def$band, bands)],
      estimate = estimate,
      standard_error = se,
      conf_low = estimate - z95 * se,
      conf_high = estimate + z95 * se,
      ratio = exp(estimate),
      ratio_conf_low = exp(estimate - z95 * se),
      ratio_conf_high = exp(estimate + z95 * se),
      p_value = 2 * pnorm(-abs(estimate / se)),
      stringsAsFactors = FALSE
    )
  }))
}

bh_effects_all <- list()
onset_tests_all <- list()
onset_band_all <- list()
tight_all <- list()
active_all <- list()
below_all <- list()
headline_support_all <- list()

for (s in sources) {
  effects <- read.csv(
    file.path(s$directory, s$effects), stringsAsFactors = FALSE,
    check.names = FALSE
  )
  fixed <- read.csv(
    file.path(s$directory, s$fixed), stringsAsFactors = FALSE,
    check.names = FALSE
  )
  cov_long <- read.csv(
    file.path(s$directory, s$covariance), stringsAsFactors = FALSE,
    check.names = FALSE
  )
  support <- read.csv(
    file.path(s$directory, s$support), stringsAsFactors = FALSE,
    check.names = FALSE
  )
  if (nrow(effects) != 156L ||
      !setequal(unique(effects$band), bands) ||
      !setequal(unique(effects$outcome), c(
        "detection", "positive_numeric_count_given_detection"
      ))) {
    stop("ARCHIVED_EFFECTS_SCOPE_GATE: released table changed",
         call. = FALSE)
  }

  effects$bh_family_id <- paste(
    gsub("[^A-Za-z0-9]+", "_", tolower(s$species)),
    effects$outcome, effects$period, "13_bands", sep = "__"
  )
  effects$bh_family_size <- ave(
    effects$p_value, effects$bh_family_id, FUN = length
  )
  effects$p_value_bh_13 <- ave(
    effects$p_value, effects$bh_family_id,
    FUN = function(p) p.adjust(p, method = "BH")
  )
  effects$significant_nominal_0_05 <- effects$p_value < 0.05
  effects$significant_bh_0_05 <- effects$p_value_bh_13 < 0.05
  if (any(effects$bh_family_size != 13L)) {
    stop("ARCHIVED_BH_FAMILY_GATE: expected 13-member families",
         call. = FALSE)
  }
  bh_effects_all[[s$species]] <- effects

  for (outcome in unique(effects$outcome)) {
    f <- fixed[fixed$outcome == outcome, , drop = FALSE]
    beta <- setNames(f$estimate, f$coefficient)
    exposure_terms <- grep("^db_band_", names(beta), value = TRUE)
    if (length(exposure_terms) != 78L) {
      stop("ARCHIVED_FIXED_EFFECT_GATE: expected 78 exposure terms",
           call. = FALSE)
    }
    covariance <- covariance_matrix(cov_long, outcome, exposure_terms)
    beta_exposure <- beta[exposure_terms]

    onset_defs <- lapply(bands, function(band) list(
      band = band,
      weights = setNames(
        c(1, -0.5, -0.5),
        paste(
          "db", band,
          c("spawn_start", "early_pre", "immediate_pre"),
          sep = "_"
        )
      )
    ))
    onset_band <- linear_contrasts(
      beta_exposure, covariance, onset_defs
    )
    onset_band$species <- s$species
    onset_band$outcome <- outcome
    onset_band$contrast <-
      "spawn_start_minus_equal_duration_pooled_pre"
    onset_band$p_value_bh_13 <- p.adjust(
      onset_band$p_value, method = "BH"
    )
    onset_band_all[[paste(s$species, outcome)]] <- onset_band

    cmat <- matrix(
      0, nrow = length(bands), ncol = length(exposure_terms),
      dimnames = list(bands, exposure_terms)
    )
    for (i in seq_along(onset_defs)) {
      cmat[i, names(onset_defs[[i]]$weights)] <-
        onset_defs[[i]]$weights
    }
    theta <- drop(cmat %*% beta_exposure)
    vtheta <- cmat %*% covariance %*% t(cmat)
    eig <- eigen(vtheta, symmetric = TRUE, only.values = TRUE)$values
    tol <- max(eig) * max(dim(vtheta)) * .Machine$double.eps
    rank <- sum(eig > tol)
    if (rank != 13L) {
      stop("ARCHIVED_ONSET_PROFILE_RANK_GATE: expected rank 13",
           call. = FALSE)
    }
    statistic <- drop(t(theta) %*% solve(vtheta, theta))
    onset_tests_all[[paste(s$species, outcome)]] <- data.frame(
      species = s$species,
      outcome = outcome,
      contrast = "spawn_start_profile_minus_equal_duration_pooled_pre",
      pooled_pre_definition =
        "0.5 * early_pre_days_-14_-8 + 0.5 * immediate_pre_days_-7_-1",
      statistic = statistic,
      degrees_of_freedom = rank,
      p_value = pchisq(statistic, df = rank, lower.tail = FALSE),
      covariance_source = file.path(s$directory, s$covariance),
      model_refit = FALSE,
      stringsAsFactors = FALSE
    )

    tight_defs <- lapply(bands, function(band) list(
      band = band,
      weights = setNames(
        c(1, -1),
        paste(
          "db", band, c("spawn_start", "immediate_pre"), sep = "_"
        )
      )
    ))
    tight <- linear_contrasts(beta_exposure, covariance, tight_defs)
    tight$species <- s$species
    tight$outcome <- outcome
    tight$contrast <- "spawn_start_days_0_3_minus_immediate_pre_days_-7_-1"
    tight$bh_family_id <- paste(
      gsub("[^A-Za-z0-9]+", "_", tolower(s$species)),
      outcome, "tight_contrast_13_bands", sep = "__"
    )
    tight$bh_family_size <- 13L
    tight$p_value_bh_13 <- p.adjust(tight$p_value, method = "BH")
    tight$significant_bh_0_05 <- tight$p_value_bh_13 < 0.05
    tight_all[[paste(s$species, outcome)]] <- tight
  }

  active <- effects[
    effects$band == "band_0_2" & effects$period == "active_0_14",
    ,
    drop = FALSE
  ]
  active$species <- s$species
  active$clears_nominal_0_05 <- active$p_value < 0.05
  active$clears_bh_0_05 <- active$p_value_bh_13 < 0.05
  active_all[[s$species]] <- active

  below <- effects[
    effects$estimate < 0 &
      effects$period %in% c(
        "early_pre", "immediate_pre", "spawn_start",
        "early_egg", "late_egg", "active_0_14"
      ),
    ,
    drop = FALSE
  ]
  below$timing_group <- ifelse(
    below$period %in% c("early_pre", "immediate_pre"),
    "pre_spawn",
    ifelse(below$period == "active_0_14",
           "post_onset_composite", "post_onset_period")
  )
  below$species <- s$species
  below_all[[s$species]] <- below

  head <- effects[
    effects$band == "band_0_2" &
      effects$period %in% c("spawn_start", "active_0_14"),
    ,
    drop = FALSE
  ]
  support_term <- support[
    support$band == "band_0_2" & support$period == "spawn_start",
    ,
    drop = FALSE
  ]
  if (nrow(support_term) != 1L) {
    stop("ARCHIVED_HEADLINE_SUPPORT_GATE: expected one support row",
         call. = FALSE)
  }
  head$species <- s$species
  head$spawn_start_exposed_checklists <-
    support_term$exposed_checklists[[1L]]
  head$spawn_start_exposure_links <- support_term$exposure_links[[1L]]
  headline_support_all[[s$species]] <- head
}

for (s in sources) {
  nm <- if (s$species == "Bald Eagle") {
    "bald_eagle_distance_band_effects_bh_v1.csv"
  } else {
    "glaucous_winged_gull_distance_band_effects_bh_v1.csv"
  }
  write_csv(bh_effects_all[[s$species]], nm)
}
write_csv(rbindlist(onset_tests_all), "direct_onset_profile_tests_v1.csv")
write_csv(rbindlist(onset_band_all), "direct_onset_band_contrasts_v1.csv")
write_csv(rbindlist(tight_all), "tight_spawn_start_vs_immediate_pre_v1.csv")
write_csv(rbindlist(active_all, fill = TRUE), "near_band_active_0_14_summary_v1.csv")
write_csv(rbindlist(below_all, fill = TRUE), "below_baseline_inventory_v1.csv")
write_csv(rbindlist(headline_support_all, fill = TRUE),
          "near_band_headline_support_v1.csv")

denominator <- data.table(
  species = "Bald Eagle",
  eligible_checklists = 217200L,
  detection_model_rows = 217199L,
  excluded_detection_rows = 1L,
  reason = paste(
    "one prespecified structural unknown:",
    "ambiguity mask present without a resolved reported state"
  ),
  complete_case_covariate_drop = 0L,
  response_model_refit = FALSE
)
write_csv(denominator, "bald_eagle_denominator_reconciliation_v1.csv")

# Audit the source-date fields for the exact source records represented in the
# 0-26 km SoG frame. Tokens are used only for the protected one-to-one join and
# are never written.
herring_path <- Sys.getenv("HERRING_EBIRD_V2_HERRING", unset = "")
if (!nzchar(herring_path) || !file.exists(herring_path)) {
  stop("ONSET_PRECISION_SOURCE_GATE: configured open DFO CSV unavailable",
       call. = FALSE)
}
h <- fread(
  herring_path, colClasses = "character", showProgress = FALSE
)
required_h <- c(
  "Region", "Year", "StatisticalArea", "Section", "LocationCode",
  "SpawnNumber", "StartDate", "EndDate", "Longitude", "Latitude"
)
if (!all(required_h %in% names(h))) {
  stop("ONSET_PRECISION_SCHEMA_GATE: DFO source schema changed",
       call. = FALSE)
}
h[, source_row := .I]
h[, event_year := suppressWarnings(as.integer(Year))]
h[, event_longitude := suppressWarnings(as.numeric(Longitude))]
h[, event_latitude := suppressWarnings(as.numeric(Latitude))]
clean <- function(x) {
  x <- trimws(as.character(x))
  x[is.na(x)] <- ""
  x
}
h <- h[
  event_year >= 2005L & event_year <= 2025L &
    is.finite(event_longitude) & is.finite(event_latitude)
]
h[, identity__ := paste(
  source_row, event_year, clean(StatisticalArea), clean(Section),
  clean(LocationCode), clean(SpawnNumber), sep = "|"
)]
h[, token__ := substr(vapply(
  paste0("herring_source|", identity__),
  digest, character(1L), algo = "sha256", serialize = FALSE
), 1L, 24L)]
if (anyDuplicated(h$token__)) {
  stop("ONSET_PRECISION_TOKEN_GATE: source token duplicated",
       call. = FALSE)
}
links <- as.data.table(.stage4a_read_gz(file.path(
  "data", "derived",
  "post_stage4a_distance_band_sensitivity_v2_protected",
  "link_builder", "metadata_source_point_links.tsv.gz"
)))
events <- as.data.table(.stage4a_read_gz(file.path(
  "data", "derived", "stage4a_protected",
  "stage4a_event_metadata.tsv.gz"
)))
event_tokens <- events[
  region == "SoG" & checklist_year >= 2005L & checklist_year <= 2025L,
  unique(analysis_event_token)
]
linked_tokens <- unique(
  links[analysis_event_token %chin% event_tokens, herring_source_token]
)
idx <- match(linked_tokens, h$token__)
if (anyNA(idx)) {
  stop("ONSET_PRECISION_JOIN_GATE: linked DFO source token unmatched",
       call. = FALSE)
}
hp <- h[idx]
hp[, start_date := as.IDate(StartDate)]
hp[, end_date := as.IDate(EndDate)]
hp[, interval_days := as.integer(end_date - start_date)]
if (any(hp$interval_days < 0, na.rm = TRUE)) {
  stop("ONSET_PRECISION_DATE_ORDER_GATE: reversed source interval",
       call. = FALSE)
}
both <- !is.na(hp$start_date) & !is.na(hp$end_date)
q <- function(x, p) {
  x <- x[is.finite(x)]
  if (!length(x)) return(NA_real_)
  as.numeric(quantile(x, p, names = FALSE, type = 1L))
}
interval <- hp$interval_days[both]
anchor_offset <- floor(interval / 2)
precision_summary <- data.table(
  linked_source_events = nrow(hp),
  source_events_with_both_date_endpoints = sum(both),
  source_events_start_only = sum(!is.na(hp$start_date) & is.na(hp$end_date)),
  source_events_end_only = sum(is.na(hp$start_date) & !is.na(hp$end_date)),
  source_events_same_day_endpoints = sum(interval == 0L, na.rm = TRUE),
  source_events_endpoints_within_1_day = sum(interval <= 1L, na.rm = TRUE),
  source_events_endpoints_within_2_days = sum(interval <= 2L, na.rm = TRUE),
  interval_days_min = q(interval, 0),
  interval_days_q25 = q(interval, 0.25),
  interval_days_median = q(interval, 0.5),
  interval_days_q75 = q(interval, 0.75),
  interval_days_q90 = q(interval, 0.9),
  interval_days_q95 = q(interval, 0.95),
  interval_days_max = q(interval, 1),
  midpoint_offset_from_start_median_days = q(anchor_offset, 0.5),
  midpoint_offset_from_start_q95_days = q(anchor_offset, 0.95),
  represented_years = uniqueN(hp$event_year),
  represented_source_location_codes = uniqueN(hp$LocationCode),
  survey_visit_history_available = FALSE,
  biological_onset_observed = FALSE,
  model_anchor = "midpoint_of_StartDate_and_EndDate_else_available_endpoint",
  symmetric_window_precision_gate =
    "FAIL_NO_SURVEY_CADENCE_AND_ANCHOR_IS_NOT_OBSERVED_ONSET",
  symmetric_window_refit_run = FALSE
)
write_csv(precision_summary, "event_date_precision_audit_v1.csv")

manifest_files <- list.files(
  output_dir, full.names = TRUE,
  pattern = "\\.(csv)$"
)
manifest <- data.table(
  file = basename(manifest_files),
  sha256 = vapply(
    manifest_files, digest, character(1L),
    algo = "sha256", file = TRUE, serialize = FALSE
  )
)
setorder(manifest, file)
write_csv(manifest, "archived_recomputation_hash_manifest_v1.csv")
message(
  "ARCHIVED_FOLLOWUP_PASS: no model refit; ",
  nrow(rbindlist(onset_tests_all)), " direct profile tests and ",
  nrow(rbindlist(tight_all)), " tight contrasts written"
)
