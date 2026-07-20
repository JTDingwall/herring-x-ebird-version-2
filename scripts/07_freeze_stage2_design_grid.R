suppressPackageStartupMessages({
  library(data.table)
  library(digest)
  library(jsonlite)
  library(yaml)
})

grid_path <- "metadata/stage2_candidate_design_grid.csv"
hash_path <- "metadata/stage2_candidate_design_grid.sha256"
rules_path <- "metadata/stage2_support_rules.yml"
args <- commandArgs(trailingOnly = TRUE)

verify_freeze <- function() {
  required <- c(grid_path, hash_path, rules_path)
  missing <- required[!file.exists(required)]
  if (length(missing)) stop("Missing Stage 2 freeze artifacts: ", paste(missing, collapse = ", "), call. = FALSE)
  recorded <- strsplit(readLines(hash_path, warn = FALSE)[[1L]], "[[:space:]]+")[[1L]][[1L]]
  actual <- digest(grid_path, algo = "sha256", file = TRUE, serialize = FALSE)
  rules <- yaml::read_yaml(rules_path)
  if (!identical(recorded, actual) || !identical(rules$design_freeze$candidate_grid_sha256, actual)) {
    stop("Stage 2 candidate grid hash mismatch", call. = FALSE)
  }
  cat(sprintf("Stage 2 candidate grid freeze verified: %s\n", actual))
  invisible(actual)
}

if (identical(args, "--verify")) {
  verify_freeze()
  quit(save = "no", status = 0L)
}

if (any(file.exists(c(grid_path, hash_path, rules_path)))) {
  stop("Freeze artifacts already exist. Use --verify; never overwrite a frozen grid.", call. = FALSE)
}

candidate <- function(dimension, candidate_id, label, role, parameters,
                      acceptance_rule, selection_guard = "outcome_blind_support_only") {
  data.table(
    grid_version = "stage2_v1",
    dimension = dimension,
    candidate_id = candidate_id,
    candidate_label = label,
    design_role = role,
    parameters_json = jsonlite::toJSON(parameters, auto_unbox = TRUE, null = "null"),
    acceptance_rule = acceptance_rule,
    selection_guard = selection_guard
  )
}

rows <- list()
add <- function(...) rows[[length(rows) + 1L]] <<- candidate(...)

temporal <- list(
  c("phase_early_pre", "Early pre", -42, -29, "core_phase"),
  c("phase_immediate_pre", "Immediate pre", -28, -1, "core_phase"),
  c("phase_spawn_start", "Spawn start", 0, 3, "core_phase"),
  c("phase_early_egg", "Early egg", 4, 14, "core_phase"),
  c("phase_late_egg", "Late egg or hatch", 15, 28, "core_phase"),
  c("phase_post", "Post", 29, 56, "core_phase"),
  c("continuous_m60_p90", "Continuous event time -60 to +90 days", -60, 90, "core_continuous"),
  c("continuous_m90_p120", "Continuous event time -90 to +120 days", -90, 120, "long_window_sensitivity")
)
for (x in temporal) add("temporal_window", x[[1]], x[[2]], x[[5]],
                         list(start_day = as.integer(x[[3]]), end_day = as.integer(x[[4]])),
                         "retain only where metadata-only event-time support is nonempty")
for (days in c(7L, 14L, 21L, 28L, 42L)) {
  add("temporal_window", sprintf("egg_kernel_%02dd", days), sprintf("Egg-availability kernel %d days", days),
      if (days == 14L) "candidate_primary_kernel" else "kernel_sensitivity",
      list(pre_days = 0L, duration_days = days, shape = "registered_kernel_family"),
      "retain as prespecified timing sensitivity without consulting response direction")
}

for (representation in c("start", "end", "midpoint", "interval", "jitter_ready")) {
  add("event_date_representation", paste0("event_date_", representation),
      paste("Event date represented by", representation),
      if (representation == "interval") "candidate_primary_uncertainty" else "timing_sensitivity",
      list(representation = representation),
      "requires at least one valid source date; reversed dates remain flagged")
}

rings <- list(c(0, 0.5), c(0.5, 1), c(1, 2), c(2, 3), c(3, 4), c(4, 5), c(5, 10), c(10, 20))
for (r in rings) {
  id <- sprintf("ring_%s_%skm", gsub("\\.", "p", r[[1]]), gsub("\\.", "p", r[[2]]))
  add("distance", id, sprintf("Non-overlapping %.1f to %.1f km ring", r[[1]], r[[2]]), "core_ring",
      list(type = "non_overlapping_ring", lower_km = r[[1]], upper_km = r[[2]], left_closed = TRUE, right_closed = FALSE),
      "support must be represented without nested-ring duplication")
}
add("distance", "continuous_0_20km", "Continuous distance 0 to 20 km", "core_continuous",
    list(type = "continuous", lower_km = 0, upper_km = 20),
    "prediction prohibited outside observed metadata support")
for (scale in c(0.5, 1, 2, 3, 5, 10)) {
  add("distance", sprintf("kernel_scale_%skm", gsub("\\.", "p", scale)), sprintf("Additive kernel scale %.1f km", scale),
      if (scale == 2) "candidate_primary_kernel" else "kernel_sensitivity",
      list(type = "additive_multi_event_kernel", scale_km = scale, spatial_families = c("exponential", "gaussian")),
      "all concurrent events contribute; links are not independent checklist rows")
}
for (radius in c(0.5, 1, 2, 3, 4, 5, 10, 20)) {
  add("distance", sprintf("cumulative_0_%skm", gsub("\\.", "p", radius)), sprintf("Cumulative 0 to %.1f km buffer", radius),
      "nested_buffer_sensitivity", list(type = "cumulative_buffer", lower_km = 0, upper_km = radius),
      "nested buffers are sensitivities and never independent samples")
}

complexes <- list(
  source_record = list(distance_km = 0, interval_gap_days = 0, role = "parallel_core_identity"),
  complex_1km_3d = list(distance_km = 1, interval_gap_days = 3, role = "candidate_fallback_primary"),
  complex_2km_7d = list(distance_km = 2, interval_gap_days = 7, role = "candidate_primary_not_approved"),
  complex_5km_14d = list(distance_km = 5, interval_gap_days = 14, role = "broad_sensitivity")
)
for (id in names(complexes)) {
  x <- complexes[[id]]
  add("event_complex", id, gsub("_", " ", id), x$role,
      list(distance_km = x$distance_km, interval_gap_days = x$interval_gap_days,
           region_crossing_allowed = FALSE, statistical_area_crossing = "flag",
           manual_review_days = 21, manual_review_diameter_km = 25),
      "retain immutable source identity and all alternative complex crosswalks")
}

geometries <- list(
  source_point = c("Authoritative source point", "parallel_core_geometry"),
  nearest_marine_shoreline_point = c("Nearest approved marine shoreline point", "candidate_linkage_geometry"),
  derived_alongshore_length = c("Length-informed alongshore footprint", "parallel_core_geometry"),
  derived_alongshore_length_width = c("Length-plus-width footprint", "geometry_sensitivity"),
  event_complex_member_union = c("Event-complex union of member geometries", "complex_sensitivity")
)
for (id in names(geometries)) {
  add("geometry", id, geometries[[id]][[1]], geometries[[id]][[2]],
      list(metric_crs = 3005L, preserve_source_geometry = TRUE, infer_missing_extent = FALSE,
           section_polygon_is_event_footprint = FALSE),
      "construction failures and shoreline snap distance must be retained")
}

regions <- c("ALL_BC_HIERARCHICAL", "A27", "A2W", "CC", "HG", "NA", "PRD", "SoG", "WCVI")
periods <- list(
  period_2005_2025 = c(2005L, 2025L, "candidate_earliest_primary"),
  period_2010_2025 = c(2010L, 2025L, "candidate_primary"),
  period_2015_2025 = c(2015L, 2025L, "recent_sensitivity"),
  period_1988_2025 = c(1988L, 2025L, "long_window_sensitivity")
)
for (region in regions) for (period_id in names(periods)) {
  p <- periods[[period_id]]
  add("region_period", paste(region, period_id, sep = "__"), paste(region, period_id), p[[3]],
      list(region = region, start_year = as.integer(p[[1]]), end_year = as.integer(p[[2]]),
           coastwide_effect_forced = FALSE),
      "earliest primary period chosen only by response-free checklist and event coverage")
}

effort <- list(
  broad_primary = list(protocols = c("Stationary", "Traveling"), complete = TRUE, duration = c(1L, 360L), travel_km = 10, observers = c(1L, 20L), start_time_required = FALSE),
  standardized_sensitivity = list(protocols = c("Stationary", "Traveling"), complete = TRUE, duration = c(5L, 300L), travel_km = 5, observers = c(1L, 10L), start_time_required = FALSE),
  complete_area_separate = list(protocols = "Area", complete = TRUE, duration = c(1L, 360L), travel_km = NA_real_, observers = c(1L, 20L), pooled_with_stationary_traveling = FALSE)
)
for (id in names(effort)) {
  add("protocol_effort", id, gsub("_", " ", id), if (id == "broad_primary") "candidate_primary" else "sensitivity_or_separate",
      effort[[id]], "missing required effort fields exclude only that effort-defined cell and are audited")
}

eligibility <- list(
  named_species_core = list(detections = 200L, events = 50L, years = 8L, regions = 2L, per_primary_period = 50L, max_event_share = 0.20, max_observer_share = 0.20, max_location_share = 0.20, positive_numeric = 100L, positive_events = 40L, numeric_availability = 0.80),
  named_species_exploratory = list(detections = 75L, events = 25L, years = 5L, per_primary_period = 20L, max_event_share = 0.30),
  guild_community_only = list(detections = 25L, events = 10L, years = 3L, valid_taxonomy = TRUE, unambiguous_primary_guild = TRUE),
  falsification_panel = list(taxa = c("Gadwall", "Northern Shoveler"), exchangeable_control = FALSE, triple_difference_authorized = FALSE)
)
for (id in names(eligibility)) {
  add("species_guild_eligibility", id, gsub("_", " ", id), if (id == "named_species_core") "candidate_primary" else "prespecified_support_class",
      eligibility[[id]], "support class retained for all 58 taxa; no taxon deleted for sparsity")
}

count_rules <- list(
  detection = list(allowed_states = c("numeric", "X", "lower_bound", "ambiguity_affected"), output = "binary_detection"),
  positive_numeric = list(allowed_states = "numeric", minimum_value = 1, output = "positive_reported_count"),
  x_detection_only = list(allowed_states = "X", numeric_imputation = FALSE),
  lower_bound_interval = list(allowed_states = "lower_bound", primary_numeric_component = FALSE, role = "bounded_sensitivity"),
  ambiguity_guild_bounds = list(allowed_states = "ambiguity_affected", named_species_allocation = FALSE, same_guild_upper_bound_only = TRUE),
  zero_inclusive_numeric = list(zero_fill_complete_checklists = TRUE, X_as_zero = FALSE, ambiguity_as_zero = FALSE),
  ordinal_flock_size = list(cutpoints_source = "pooled_exposure_blind_marginal_counts", role = "sensitivity"),
  upper_tail = list(thresholds = c(0.99, 0.995), winsorize_primary = FALSE, role = "sensitivity")
)
for (id in names(count_rules)) {
  add("count_state", id, gsub("_", " ", id), if (id %in% c("detection", "positive_numeric")) "core_component" else "registered_sensitivity",
      count_rules[[id]], "detection and positive-count components remain separate")
}

coocc <- list(
  detection_community = list(min_detections = 25L, min_events = 10L, min_years = 3L, valid_taxonomy = TRUE),
  reduced_abundance_community = list(min_positive_numeric = 100L, min_positive_events = 40L, min_numeric_availability = 0.80),
  pairwise_descriptive = list(min_each_species_detections = 25L, min_joint_positive_checklists = 20L, min_shared_events = 10L, exposure_specific_contrast = FALSE),
  null_permutation = list(min_released_cell = 20L, preserve = c("prevalence", "checklist_richness", "effort", "date", "location", "observer"))
)
for (id in names(coocc)) {
  add("cooccurrence_eligibility", id, gsub("_", " ", id), if (id == "detection_community") "candidate_primary" else "support_or_sensitivity",
      coocc[[id]], "pairwise support is pooled across exposure; no spawn-phase or distance contrast")
}

grid <- rbindlist(rows, use.names = TRUE)
setorder(grid, dimension, candidate_id)
if (anyDuplicated(grid[, .(dimension, candidate_id)])) stop("Duplicate candidate grid keys", call. = FALSE)
fwrite(grid, grid_path, quote = TRUE, na = "")

grid_sha <- digest(grid_path, algo = "sha256", file = TRUE, serialize = FALSE)
frozen_at <- format(Sys.time(), tz = "UTC", usetz = TRUE)
rules <- list(
  design_freeze = list(
    grid_version = "stage2_v1",
    candidate_grid_path = grid_path,
    candidate_grid_sha256 = grid_sha,
    frozen_at_utc = frozen_at,
    frozen_before_response_value_access = TRUE,
    correction_policy = "retain old and new hashes; document schema or implementation correction; never change for support patterns"
  ),
  support_output_label = "SUPPORT_ONLY_NOT_AN_EFFECT_ESTIMATE",
  eligible_support_quantities = c(
    "eligible_checklists", "detections", "positive_numeric_reports", "X_reports",
    "lower_bound_or_ambiguity_affected", "represented_events", "represented_event_complexes",
    "years", "regions", "locations", "observers", "maximum_event_share",
    "maximum_location_share", "maximum_observer_share", "exposure_pooled_count_quantiles",
    "pairwise_prevalence_and_cell_counts"
  ),
  prohibited_statistics = c(
    "detection_rate_by_exposure", "bird_count_summary_by_exposure", "active_reference_contrast",
    "ratio_or_odds_ratio", "effect_size_or_coefficient", "p_value", "confidence_or_posterior_interval",
    "posterior_summary", "cooccurrence_change_by_spawn_phase_or_distance", "biological_response_plot",
    "herring_exposure_response_model"
  ),
  primary_periods = list(
    period_one = list(start_day = -28L, end_day = -1L),
    period_two = list(start_day = 0L, end_day = 28L)
  ),
  nearby_threshold_sensitivity = list(
    named_core_detections = c(150L, 200L, 250L),
    named_core_events = c(40L, 50L, 60L),
    named_core_numeric_availability = c(0.75, 0.80, 0.85),
    named_exploratory_detections = c(50L, 75L, 100L),
    guild_community_detections = c(20L, 25L, 30L)
  ),
  event_complex_acceptance = list(
    candidate_primary = "complex_2km_7d",
    never_merge_across_region = TRUE,
    flag_statistical_area_crossing = TRUE,
    manual_review_temporal_span_days = 21L,
    manual_review_spatial_diameter_km = 25,
    preserve_alternatives = TRUE
  ),
  geometry_quality = list(
    tier_A = "valid date, coordinate, method, accepted marine shoreline snap, observed Length, no major ambiguity",
    tier_B = "valid date and point with accepted marine shoreline snap but missing extent",
    tier_C = "usable section/date metadata but uncertain point or method",
    exclude = "impossible or unlocatable exposure definition only"
  ),
  count_family_selection = list(
    candidates = c("hurdle_lognormal", "hurdle_truncated_nb2", "hurdle_generalized_poisson",
                   "zero_inclusive_nb", "tweedie", "ordinal_flock_size", "upper_tail_exceedance_or_quantile"),
    criteria = c("simulation_recovery", "leave_block_out_log_score", "calibration",
                 "residual_tail_behaviour", "numerical_stability"),
    simplicity_rule = "one_standard_error",
    herring_term_selection_forbidden = TRUE
  ),
  multispecies_selection = list(
    response = "detection_first",
    latent_factors = c(2L, 3L, 4L, 5L),
    comparators = c("no_latent_factor", "no_pooling"),
    selection = c("heldout_predictive_score", "convergence_or_posterior_geometry",
                  "simulation_residual_association_recovery", "one_standard_error"),
    hash_identical_pilot_required = TRUE,
    observed_herring_response_effects_allowed = FALSE
  ),
  prospective_holdout = list(
    start_year = 2026L,
    development_access = "frozen",
    current_release_complete = FALSE,
    signed_hash_recorded_specification_required = TRUE,
    refitting_before_primary_evaluation = FALSE
  )
)
yaml::write_yaml(rules, rules_path, fileEncoding = "UTF-8")
writeLines(c(sprintf("%s  %s", grid_sha, grid_path), sprintf("# frozen_at_utc: %s", frozen_at)),
           hash_path, useBytes = TRUE)
cat(sprintf("Frozen %d candidate options at %s\nSHA-256: %s\n", nrow(grid), frozen_at, grid_sha))
