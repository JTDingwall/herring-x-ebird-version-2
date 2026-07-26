# Build privacy-safe aggregates for REFEREE_READS_REPORT.md.
#
# This script does not fit or refit any species-response model. It reads the
# frozen through-2025 event/link inventory, persisted release CSVs, and the
# preassigned guild registry. The only fitted objects are the item-10
# species-level inverse-variance meta-regressions requested by the referee.

options(stringsAsFactors = FALSE)

reference_root <- ".worktrees/conventional-sensitivity-v9"
editorial_dir <- file.path(
  reference_root, "outputs", "editorial_requested_analysis_v1"
)
event_study_dir <- file.path(
  reference_root, "outputs", "post_stage4a_sog_event_study_v1"
)
aggregate_dir <- file.path("outputs", "referee_reads_v1")
figures_dir <- "figures_out"
dir.create(aggregate_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

required_files <- c(
  file.path(
    "data", "derived", "stage4a_protected",
    "stage4a_event_metadata.tsv.gz"
  ),
  file.path(
    "data", "derived", "stage3_phase2_protected",
    "metadata_source_point_links.tsv.gz"
  ),
  file.path(editorial_dir, "active_minus_pre_contrasts.csv"),
  file.path(editorial_dir, "absolute_predictions.csv"),
  file.path(editorial_dir, "sensitivity_comparisons.csv"),
  file.path(event_study_dir, "effect_estimates_v1.csv"),
  file.path(event_study_dir, "specificity_comparators_v1.csv"),
  file.path(reference_root, "diagnostics", "D5_species_support_prevalence.csv"),
  file.path(reference_root, "metadata", "canonical_species_registry.csv")
)
if (!all(file.exists(required_files))) {
  stop(
    "Missing required inputs: ",
    paste(required_files[!file.exists(required_files)], collapse = ", "),
    call. = FALSE
  )
}

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("The data.table package is required.", call. = FALSE)
}

source(
  file.path(reference_root, "R", "stage4a_core.R"),
  local = FALSE
)
source(
  file.path(reference_root, "R", "stage4a_production.R"),
  local = FALSE
)
source(
  file.path(reference_root, "R", "post_stage4a_sog_event_study_v1.R"),
  local = FALSE
)

write_release_csv <- function(x, name) {
  utils::write.csv(
    x, file.path(aggregate_dir, name),
    row.names = FALSE, na = ""
  )
}

num <- function(x) suppressWarnings(as.numeric(x))
is_completed <- function(x) grepl("^completed", x)

# -------------------------------------------------------------------------
# Items 1, 5, and 9: descriptive event/link/frame calculations.
# Join declaration:
#   events (one row per analysis_event_token) 1:m selected_links;
#   selected_links m:1 events; the m:1 match is asserted below.
# -------------------------------------------------------------------------

events_all <- .stage4a_read_gz(required_files[[1L]])
if (nrow(events_all) != 239934L ||
    any(as.integer(events_all$checklist_year) > 2025L)) {
  stop("Through-2025 event metadata cardinality/year gate failed.",
       call. = FALSE)
}
events_all <- .stage4a_prepare_events(events_all)
keep_events <- events_all$region == "SoG" &
  events_all$checklist_year >= 2005L &
  events_all$checklist_year <= 2025L
events <- events_all[keep_events, , drop = FALSE]
rm(events_all)
if (nrow(events) != 217200L ||
    anyDuplicated(events$analysis_event_token)) {
  stop("Eligible checklist key/cardinality gate failed.", call. = FALSE)
}

links <- .stage4a_read_gz(required_files[[2L]])
selected_links <- links[
  links$analysis_event_token %in% events$analysis_event_token,
  , drop = FALSE
]
event_match <- match(
  selected_links$analysis_event_token,
  events$analysis_event_token
)
if (anyNA(event_match) ||
    !all(selected_links$checklist_year ==
         events$checklist_year[event_match])) {
  stop("Selected-link m:1 event join gate failed.", call. = FALSE)
}
if (length(unique(selected_links$herring_source_token)) != 1120L) {
  stop("Source-event cardinality gate failed.", call. = FALSE)
}

classified <- post_stage4a_classify_links_v1(selected_links)
classified$herring_source_token <- selected_links$herring_source_token
classified$event_block_token <- events$event_block_token[event_match]
classified <- classified[!is.na(classified$term), , drop = FALSE]

joint <- post_stage4a_add_joint_exposure_v1(events, links)
events_joint <- joint$events
rm(links, joint)
if (nrow(events_joint) != 217200L ||
    anyDuplicated(events_joint$analysis_event_token)) {
  stop("Joint-exposure checklist key/cardinality gate failed.",
       call. = FALSE)
}

terms <- post_stage4a_exposure_terms_v1()
link_distribution <- do.call(rbind, lapply(terms, function(term) {
  values <- as.integer(events_joint[[term]])
  exposed <- values > 0L
  pieces <- strsplit(sub("^es_", "", term), "_", fixed = TRUE)[[1L]]
  data.frame(
    period = paste(pieces[-1L], collapse = "_"),
    zone = pieces[[1L]],
    term = term,
    exposed_checklists = sum(exposed),
    exactly_one = sum(values[exposed] == 1L),
    exactly_one_proportion = mean(values[exposed] == 1L),
    exactly_two = sum(values[exposed] == 2L),
    exactly_two_proportion = mean(values[exposed] == 2L),
    three_or_more = sum(values[exposed] >= 3L),
    three_or_more_proportion = mean(values[exposed] >= 3L),
    maximum = max(values[exposed]),
    stringsAsFactors = FALSE
  )
}))
write_release_csv(link_distribution, "item1_period_zone_link_distribution.csv")

source_zone_counts <- aggregate(
  zone ~ herring_source_token, classified,
  function(x) length(unique(x))
)
block_zone_counts <- aggregate(
  zone ~ event_block_token, classified,
  function(x) length(unique(x))
)
dual_source_events <- sum(source_zone_counts$zone == 2L)
dual_blocks <- sum(block_zone_counts$zone == 2L)
dual_block_tokens <- block_zone_counts$event_block_token[
  block_zone_counts$zone == 2L
]
target_link_total <- rowSums(events_joint[, terms, drop = FALSE])
exposed_checklists <- target_link_total > 0L
dual_block_checklists <- exposed_checklists &
  events_joint$event_block_token %in% dual_block_tokens
block_summary <- data.frame(
  metric = c(
    "source_events_total",
    "source_events_both_zones",
    "event_blocks_total",
    "event_blocks_both_zones",
    "exposed_checklists",
    "exposed_checklists_in_both_zone_blocks",
    "share_exposed_checklists_in_both_zone_blocks"
  ),
  value = c(
    length(unique(selected_links$herring_source_token)),
    dual_source_events,
    length(unique(events$event_block_token)),
    dual_blocks,
    sum(exposed_checklists),
    sum(dual_block_checklists),
    sum(dual_block_checklists) / sum(exposed_checklists)
  )
)
write_release_csv(block_summary, "item5_event_block_zone_representation.csv")

effort_summary_one <- function(use, zone, window, variable, values) {
  values <- num(values[use])
  values <- values[is.finite(values)]
  data.frame(
    zone = zone,
    window = window,
    variable = variable,
    checklists = length(values),
    mean = mean(values),
    q25 = unname(stats::quantile(values, 0.25, type = 7)),
    median = stats::median(values),
    q75 = unname(stats::quantile(values, 0.75, type = 7)),
    stringsAsFactors = FALSE
  )
}

effort_rows <- list()
i <- 0L
for (zone in c("near", "reference")) {
  memberships <- list(
    pre_onset_minus14_to_minus1 =
      events_joint[[paste0("es_", zone, "_early_pre")]] > 0L |
      events_joint[[paste0("es_", zone, "_immediate_pre")]] > 0L,
    active_0_to_14 =
      events_joint[[paste0("es_", zone, "_spawn_start")]] > 0L |
      events_joint[[paste0("es_", zone, "_early_egg")]] > 0L
  )
  for (window in names(memberships)) {
    for (variable in c(
      "duration_minutes", "effort_distance_km", "observer_count"
    )) {
      i <- i + 1L
      effort_rows[[i]] <- effort_summary_one(
        memberships[[window]], zone, window, variable,
        events_joint[[variable]]
      )
    }
  }
}
effort_summary <- do.call(rbind, effort_rows)
write_release_csv(effort_summary, "item9_effort_descriptives.csv")

# -------------------------------------------------------------------------
# Item 1: binary-any-link sensitivity comparisons.
# Join declaration:
#   sensitivity rows and primary rows are already 1:1 by
#   analysis_taxon_id x outcome x comparison in the released table; assert.
# -------------------------------------------------------------------------

sensitivity <- utils::read.csv(
  file.path(editorial_dir, "sensitivity_comparisons.csv"),
  check.names = FALSE
)
binary <- sensitivity[
  sensitivity$sensitivity_id == "binary_any_link" &
    sensitivity$comparison == "active_minus_pre14",
  , drop = FALSE
]
if (nrow(binary) != 98L ||
    anyDuplicated(binary[c(
      "analysis_taxon_id", "outcome", "comparison"
    )])) {
  stop("Binary sensitivity key/cardinality gate failed.", call. = FALSE)
}
binary_completed <- binary[
  is_completed(binary$primary_status) &
    is_completed(binary$status) &
    is.finite(binary$primary_estimate) &
    is.finite(binary$estimate),
  , drop = FALSE
]
binary_summary <- do.call(rbind, lapply(
  unique(binary$outcome),
  function(outcome) {
    x <- binary_completed[binary_completed$outcome == outcome, , drop = FALSE]
    primary_sig <- num(x$primary_q_value) < 0.05
    data.frame(
      outcome = outcome,
      paired_estimable_species = nrow(x),
      direction_agreement = sum(x$direction_concordant),
      primary_bh_significant = sum(primary_sig),
      primary_bh_sign_preserved =
        sum(primary_sig & x$direction_concordant),
      primary_bh_remains_bh_significant =
        sum(primary_sig & num(x$sensitivity_q_value) < 0.05),
      primary_bh_keeps_direction_and_significance =
        sum(primary_sig & x$direction_concordant &
            num(x$sensitivity_q_value) < 0.05),
      stringsAsFactors = FALSE
    )
  }
))
write_release_csv(binary_summary, "item1_binary_summary.csv")

binary_focal_names <- c(
  "Bonaparte's Gull", "American Herring Gull", "California Gull",
  "Long-tailed Duck", "Surf Scoter", "Short-billed Gull"
)
binary_focal <- binary[
  binary$species %in% binary_focal_names &
    (
      (binary$outcome == "checklist_reporting" &
       binary$species %in% binary_focal_names[1:3]) |
      (binary$outcome == "conditional_positive_numeric_count" &
       binary$species %in% binary_focal_names[4:6])
    ),
  c(
    "species", "outcome", "primary_ratio", "primary_ratio_conf_low",
    "primary_ratio_conf_high", "primary_q_value", "ratio",
    "ratio_conf_low", "ratio_conf_high", "sensitivity_q_value",
    "direction_concordant", "status"
  ),
  drop = FALSE
]
write_release_csv(binary_focal, "item1_binary_focal_species.csv")

# -------------------------------------------------------------------------
# Items 2, 3, 4, and 6: persisted release tables.
# -------------------------------------------------------------------------

comparators <- utils::read.csv(
  file.path(event_study_dir, "specificity_comparators_v1.csv"),
  check.names = FALSE
)
write_release_csv(comparators, "item2_specificity_comparators.csv")

named_species <- c(
  "Bonaparte's Gull", "American Herring Gull", "California Gull",
  "Iceland Gull", "Glaucous-winged Gull", "Short-billed Gull",
  "Western Gull", "Glaucous Gull", "Long-tailed Duck", "Surf Scoter",
  "White-winged Scoter", "Harlequin Duck", "Barrow's Goldeneye",
  "Bufflehead", "Common Goldeneye", "Greater Scaup", "Common Merganser",
  "Red-breasted Merganser", "Common Loon", "Pacific Loon",
  "Double-crested Cormorant", "Bald Eagle", "Great Blue Heron",
  "Mallard", "American Wigeon", "Northern Pintail", "Brant",
  "Surfbird", "Rhinoceros Auklet", "Gadwall", "Northern Shoveler"
)
support <- utils::read.csv(
  file.path(reference_root, "diagnostics", "D5_species_support_prevalence.csv"),
  check.names = FALSE
)
support_named <- support[
  match(named_species, support$unit_label),
  c(
    "unit_label", "analysis_taxon_id", "detections",
    "positive_numeric", "prevalence"
  ),
  drop = FALSE
]
if (anyNA(support_named$analysis_taxon_id)) {
  stop("Named-species support join gate failed.", call. = FALSE)
}
support_named$prevalence_percent <- 100 * num(support_named$prevalence)
support_named$detections_reported <- ifelse(
  num(support_named$detections) < 20, NA, num(support_named$detections)
)
support_named$positive_numeric_reported <- ifelse(
  num(support_named$positive_numeric) < 20,
  NA, num(support_named$positive_numeric)
)
support_named$suppressed_below_20 <- num(support_named$detections) < 20 |
  num(support_named$positive_numeric) < 20
write_release_csv(support_named, "item3_named_species_prevalence.csv")

diagnostics <- utils::read.csv(
  file.path(editorial_dir, "model_diagnostics.csv"),
  check.names = FALSE
)
contrasts <- utils::read.csv(
  file.path(editorial_dir, "active_minus_pre_contrasts.csv"),
  check.names = FALSE
)
western_diag <- diagnostics[
  diagnostics$species == "Western Gull" &
    diagnostics$outcome == "conditional_positive_numeric_count",
  , drop = FALSE
]
western_contrast <- contrasts[
  contrasts$species == "Western Gull" &
    contrasts$outcome == "conditional_positive_numeric_count" &
    contrasts$comparison == "active_minus_pre14",
  , drop = FALSE
]
western <- cbind(
  western_diag[c(
    "species", "outcome", "engine", "n", "singular_fit",
    "event_block_variance", "observer_variance", "location_variance",
    "residual_variance", "status"
  )],
  western_contrast[c(
    "estimate", "standard_error", "conf_low", "conf_high",
    "ratio", "ratio_conf_low", "ratio_conf_high", "q_value"
  )]
)
western$adjusted_significant <- num(western$q_value) < 0.05
write_release_csv(western, "item4_western_gull_singular_fit.csv")

predictions <- utils::read.csv(
  file.path(editorial_dir, "absolute_predictions.csv"),
  check.names = FALSE
)
prediction_targets <- data.frame(
  species = c(
    "Glaucous-winged Gull", "Short-billed Gull", "Surf Scoter"
  ),
  outcome = c(
    "checklist_reporting",
    "conditional_positive_numeric_count",
    "conditional_positive_numeric_count"
  )
)
prediction_quantities <- c(
  "baseline_near", "baseline_reference",
  "pre14_near", "pre14_reference",
  "active_near", "active_reference",
  "baseline_near_reference", "pre14_near_reference",
  "active_near_reference", "pre14_baseline_adjusted",
  "active_baseline_adjusted", "active_minus_pre14"
)
prediction_rows <- merge(
  predictions[
    predictions$prediction_configuration ==
      "observed_covariate_standardization" &
      predictions$quantity %in% prediction_quantities,
    , drop = FALSE
  ],
  prediction_targets,
  by = c("species", "outcome"),
  all = FALSE,
  sort = FALSE
)
prediction_rows <- prediction_rows[
  order(
    match(prediction_rows$species, prediction_targets$species),
    match(prediction_rows$quantity, prediction_quantities)
  ),
  , drop = FALSE
]
write_release_csv(prediction_rows, "item6_absolute_predictions.csv")

# -------------------------------------------------------------------------
# Item 7: reconstructed supplementary tables and frozen pre-trend checks.
# The separately described 05_supp_pretrend_and_tables.R was not present.
# -------------------------------------------------------------------------

primary_table <- contrasts[
  contrasts$comparison == "active_minus_pre14",
  c(
    "species", "outcome", "ratio", "ratio_conf_low", "ratio_conf_high",
    "q_value", "n", "status"
  ),
  drop = FALSE
]
if (nrow(primary_table) != 98L ||
    anyDuplicated(primary_table[c("species", "outcome")])) {
  stop("Supplement primary-table key/cardinality gate failed.",
       call. = FALSE)
}
utils::write.csv(
  primary_table,
  file.path(figures_dir, "tableS_primary_contrast_49x2.csv"),
  row.names = FALSE, na = ""
)

primary_wide <- reshape(
  primary_table[c("species", "outcome", "status")],
  idvar = "species", timevar = "outcome", direction = "wide"
)
support_core <- support[
  support$analysis_taxon_id %in%
    unique(contrasts$analysis_taxon_id[
      contrasts$comparison == "active_minus_pre14"
    ]),
  , drop = FALSE
]
support_table <- merge(
  support_core,
  primary_wide,
  by.x = "unit_label", by.y = "species",
  all.x = TRUE, sort = FALSE
)
support_table <- support_table[
  match(support_core$unit_label, support_table$unit_label), , drop = FALSE
]
if (nrow(support_table) != 49L ||
    anyNA(support_table$status.checklist_reporting)) {
  stop("Supplement support-table join/cardinality gate failed.",
       call. = FALSE)
}
utils::write.csv(
  support_table,
  file.path(figures_dir, "tableS_species_support.csv"),
  row.names = FALSE, na = ""
)

effects <- utils::read.csv(
  file.path(event_study_dir, "effect_estimates_v1.csv"),
  check.names = FALSE
)
pretrend <- effects[
  effects$analysis_role == "core_species" &
    effects$contrast %in% c("did_early_pre", "did_immediate_pre"),
  , drop = FALSE
]
pretrend_summary <- do.call(rbind, lapply(
  split(pretrend, interaction(
    pretrend$outcome, pretrend$contrast, drop = TRUE
  )),
  function(x) {
    x <- x[is_completed(x$status) & is.finite(x$estimate), , drop = FALSE]
    data.frame(
      outcome = x$outcome[[1L]],
      contrast = x$contrast[[1L]],
      ecological_period = x$ecological_period[[1L]],
      estimable_species = nrow(x),
      bh_q_lt_0_05 = sum(num(x$q_value) < 0.05, na.rm = TRUE),
      median_ratio = stats::median(num(x$ratio), na.rm = TRUE),
      minimum_q_value = min(num(x$q_value), na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  }
))
pretrend_summary <- pretrend_summary[
  order(pretrend_summary$outcome, pretrend_summary$contrast),
  , drop = FALSE
]
utils::write.csv(
  pretrend_summary,
  file.path(figures_dir, "tableS_pretrend_summary.csv"),
  row.names = FALSE, na = ""
)

plot_pretrend <- function(device, path) {
  device(path)
  active_device <- grDevices::dev.cur()
  on.exit({
    if (grDevices::dev.cur() == active_device) {
      grDevices::dev.off()
    }
  }, add = TRUE)
  outcomes <- c("detection", "positive_numeric_count_given_detection")
  labels <- c(
    detection = "Checklist reporting",
    positive_numeric_count_given_detection = "Reported number"
  )
  old <- graphics::par(
    mfrow = c(1, 2), mar = c(4.3, 4.3, 2.2, 1.0),
    las = 1, bty = "l"
  )
  for (outcome in outcomes) {
    x <- pretrend[
      pretrend$outcome == outcome & is_completed(pretrend$status) &
        is.finite(pretrend$estimate),
      , drop = FALSE
    ]
    xpos <- ifelse(x$contrast == "did_early_pre", 1, 2)
    graphics::plot(
      jitter(xpos, amount = 0.08), num(x$ratio),
      xaxt = "n", xlab = "", ylab = "Near/reference ratio vs baseline",
      main = labels[[outcome]], pch = 16,
      col = grDevices::adjustcolor("#255F85", alpha.f = 0.55)
    )
    graphics::axis(
      1, at = 1:2,
      labels = c("Days -14 to -8", "Days -7 to -1")
    )
    graphics::abline(h = 1, lty = 2, col = "grey40")
  }
  graphics::par(old)
  invisible(grDevices::dev.off())
}
set.seed(20260725)
plot_pretrend(
  function(path) grDevices::png(
    path, width = 1800, height = 900, res = 170
  ),
  file.path(figures_dir, "figS_pretrend.png")
)
set.seed(20260725)
plot_pretrend(
  function(path) grDevices::pdf(
    path, width = 10.6, height = 5.3, useDingbats = FALSE
  ),
  file.path(figures_dir, "figS_pretrend.pdf")
)

pretrend_claims <- pretrend[
  pretrend$unit_label %in% c("Great Blue Heron", "Iceland Gull") &
    pretrend$outcome == "positive_numeric_count_given_detection" &
    pretrend$contrast == "did_immediate_pre",
  c(
    "unit_label", "outcome", "contrast", "estimate", "standard_error",
    "ratio", "ratio_conf_low", "ratio_conf_high", "p_value", "q_value",
    "status"
  ),
  drop = FALSE
]
write_release_csv(pretrend_summary, "item7_pretrend_summary.csv")
write_release_csv(pretrend_claims, "item7_pretrend_named_claims.csv")

# -------------------------------------------------------------------------
# Item 8: paired signs and exact McNemar test.
# Join declaration:
#   one detection and one count row per analysis_taxon_id; inner 1:1 join;
#   require all 46 count-estimable species to have an estimable reporting row.
# -------------------------------------------------------------------------

active <- effects[
  effects$analysis_role == "core_species" &
    effects$contrast == "did_active_0_14_day" &
    is_completed(effects$status) &
    is.finite(effects$estimate),
  c("analysis_taxon_id", "unit_label", "outcome", "estimate"),
  drop = FALSE
]
reporting <- active[
  active$outcome == "detection",
  c("analysis_taxon_id", "unit_label", "estimate"),
  drop = FALSE
]
counts <- active[
  active$outcome == "positive_numeric_count_given_detection",
  c("analysis_taxon_id", "unit_label", "estimate"),
  drop = FALSE
]
paired <- merge(
  reporting, counts,
  by = c("analysis_taxon_id", "unit_label"),
  suffixes = c("_reporting", "_count"),
  all = FALSE
)
if (nrow(paired) != 46L ||
    anyDuplicated(paired$analysis_taxon_id)) {
  stop("Paired-outcome 1:1 join/cardinality gate failed.", call. = FALSE)
}
paired$positive_reporting <- paired$estimate_reporting > 0
paired$positive_count <- paired$estimate_count > 0
both_positive <- sum(paired$positive_reporting & paired$positive_count)
count_only <- sum(!paired$positive_reporting & paired$positive_count)
reporting_only <- sum(paired$positive_reporting & !paired$positive_count)
both_negative <- sum(!paired$positive_reporting & !paired$positive_count)
discordant <- count_only + reporting_only
mcnemar_p <- if (discordant) {
  stats::binom.test(
    min(count_only, reporting_only), discordant,
    p = 0.5, alternative = "two.sided"
  )$p.value
} else {
  1
}
paired_summary <- data.frame(
  positive_both = both_positive,
  positive_count_only = count_only,
  positive_reporting_only = reporting_only,
  negative_both = both_negative,
  paired_species = nrow(paired),
  reporting_positive = sum(paired$positive_reporting),
  reporting_positive_proportion = mean(paired$positive_reporting),
  count_positive = sum(paired$positive_count),
  count_positive_proportion = mean(paired$positive_count),
  discordant_pairs = discordant,
  exact_mcnemar_p_value = mcnemar_p
)
write_release_csv(paired_summary, "item8_paired_outcome_asymmetry.csv")

# -------------------------------------------------------------------------
# Item 10: inverse-variance meta-regression of spawn-start minus early-egg.
# The released checkpoints persist effects/SEs but not coefficient covariance,
# so the requested archived-SE variance is SE_spawn^2 + SE_early^2.
# -------------------------------------------------------------------------

guilds <- utils::read.csv(
  file.path(reference_root, "metadata", "canonical_species_registry.csv"),
  check.names = FALSE
)[, c("analysis_taxon_id", "common_name", "guild_ids"), drop = FALSE]
timing_rows <- list()
guild_rows <- list()
heterogeneity_rows <- list()
j <- 0L

for (outcome in c(
  "detection", "positive_numeric_count_given_detection"
)) {
  spawn <- effects[
    effects$analysis_role == "core_species" &
      effects$outcome == outcome &
      effects$contrast == "did_spawn_start" &
      is_completed(effects$status) &
      is.finite(effects$estimate) &
      is.finite(effects$standard_error),
    c(
      "analysis_taxon_id", "unit_label", "estimate", "standard_error"
    ),
    drop = FALSE
  ]
  early <- effects[
    effects$analysis_role == "core_species" &
      effects$outcome == outcome &
      effects$contrast == "did_early_egg" &
      is_completed(effects$status) &
      is.finite(effects$estimate) &
      is.finite(effects$standard_error),
    c(
      "analysis_taxon_id", "unit_label", "estimate", "standard_error"
    ),
    drop = FALSE
  ]
  timing <- merge(
    spawn, early,
    by = c("analysis_taxon_id", "unit_label"),
    suffixes = c("_spawn_start", "_early_egg"),
    all = FALSE
  )
  timing <- merge(
    timing, guilds,
    by = "analysis_taxon_id",
    all.x = TRUE, sort = FALSE
  )
  if (anyNA(timing$guild_ids) ||
      any(timing$unit_label != timing$common_name)) {
    stop("Timing-to-guild m:1 join gate failed.", call. = FALSE)
  }
  expected_n <- if (outcome == "detection") 48L else 46L
  if (nrow(timing) != expected_n ||
      anyDuplicated(timing$analysis_taxon_id)) {
    stop("Timing contrast key/cardinality gate failed for ", outcome,
         call. = FALSE)
  }
  timing$outcome <- outcome
  timing$timing_contrast <-
    num(timing$estimate_spawn_start) - num(timing$estimate_early_egg)
  timing$timing_variance <-
    num(timing$standard_error_spawn_start)^2 +
    num(timing$standard_error_early_egg)^2
  timing$timing_standard_error <- sqrt(timing$timing_variance)
  timing$variance_method <-
    "archived_standard_errors_covariance_unavailable_assumed_zero"
  timing$inverse_variance_weight <- 1 / timing$timing_variance
  j <- j + 1L
  timing_rows[[j]] <- timing

  guild_factor <- factor(timing$guild_ids)
  design <- stats::model.matrix(~ 0 + guild_factor)
  weights <- timing$inverse_variance_weight
  information <- crossprod(design, weights * design)
  coefficients <- solve(
    information,
    crossprod(design, weights * timing$timing_contrast)
  )
  coefficient_covariance <- solve(information)
  coefficient_se <- sqrt(diag(coefficient_covariance))
  guild_names <- levels(guild_factor)
  fitted <- drop(design %*% coefficients)
  grand_mean <- sum(weights * timing$timing_contrast) / sum(weights)
  q_total <- sum(
    weights * (timing$timing_contrast - grand_mean)^2
  )
  q_residual <- sum(weights * (timing$timing_contrast - fitted)^2)
  q_between <- q_total - q_residual
  df_between <- length(guild_names) - 1L
  df_residual <- nrow(timing) - length(guild_names)

  guild_rows[[j]] <- data.frame(
    outcome = outcome,
    guild = guild_names,
    species = as.integer(table(guild_factor)[guild_names]),
    mean_link_contrast = drop(coefficients),
    standard_error = coefficient_se,
    conf_low = drop(coefficients) -
      1.959963984540054 * coefficient_se,
    conf_high = drop(coefficients) +
      1.959963984540054 * coefficient_se,
    ratio_spawn_start_vs_early_egg = exp(drop(coefficients)),
    stringsAsFactors = FALSE
  )
  heterogeneity_rows[[j]] <- data.frame(
    outcome = outcome,
    species = nrow(timing),
    guilds = length(guild_names),
    q_between = q_between,
    df_between = df_between,
    p_guild_differences = stats::pchisq(
      q_between, df_between, lower.tail = FALSE
    ),
    q_residual = q_residual,
    df_residual = df_residual,
    p_residual_heterogeneity = stats::pchisq(
      q_residual, df_residual, lower.tail = FALSE
    ),
    residual_i2_percent = 100 * max(
      0, (q_residual - df_residual) / q_residual
    ),
    variance_method =
      "archived_standard_errors_covariance_unavailable_assumed_zero",
    stringsAsFactors = FALSE
  )
}
timing_all <- do.call(rbind, timing_rows)
guild_all <- do.call(rbind, guild_rows)
heterogeneity_all <- do.call(rbind, heterogeneity_rows)
write_release_csv(timing_all, "item10_species_timing_contrasts.csv")
write_release_csv(guild_all, "item10_guild_means.csv")
write_release_csv(
  heterogeneity_all, "item10_meta_regression_tests.csv"
)

message("REFEREE_READS_PART1_AGGREGATES=PASS")
