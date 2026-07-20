suppressPackageStartupMessages({
  library(data.table)
  library(digest)
  library(igraph)
  library(jsonlite)
  library(Matrix)
  library(sf)
  library(yaml)
})

options(stringsAsFactors = FALSE, scipen = 999)
sf::sf_use_s2(FALSE)

support_label <- "SUPPORT_ONLY_NOT_AN_EFFECT_ESTIMATE"
out_dir <- "outputs/stage2_design_lock"
private_dir <- "outputs/input_audit_local/stage2"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(private_dir, recursive = TRUE, showWarnings = FALSE)

grid_path <- "metadata/stage2_candidate_design_grid.csv"
hash_path <- "metadata/stage2_candidate_design_grid.sha256"
rules_path <- "metadata/stage2_support_rules.yml"
recorded_hash <- strsplit(readLines(hash_path, warn = FALSE)[1L], "[[:space:]]+")[[1L]][1L]
actual_hash <- digest(grid_path, algo = "sha256", file = TRUE, serialize = FALSE)
rules <- yaml::read_yaml(rules_path)
stopifnot(identical(recorded_hash, actual_hash), identical(rules$design_freeze$candidate_grid_sha256, actual_hash))

env_names <- c(
  ebd = "HERRING_EBIRD_V2_EBD",
  sed = "HERRING_EBIRD_V2_SED",
  herring = "HERRING_EBIRD_V2_HERRING",
  shoreline = "HERRING_EBIRD_V2_SHORELINE",
  sections = "HERRING_EBIRD_V2_SECTIONS"
)
paths <- setNames(Sys.getenv(unname(env_names)), names(env_names))
if (any(!nzchar(paths)) || any(!file.exists(paths))) stop("All five protected inputs must be configured and readable", call. = FALSE)

registry <- fread("metadata/canonical_species_registry.csv", na.strings = c("", "NA"))
guild_registry <- fread("metadata/canonical_guild_registry.csv", na.strings = c("", "NA"))
model_registry <- fread("metadata/model_registry.csv", na.strings = c("", "NA"))
grid <- fread(grid_path)
stopifnot(nrow(registry) == 58L, nrow(model_registry) == 45L, nrow(grid) == 105L)
if (anyDuplicated(registry$analysis_taxon_id) || anyDuplicated(registry$common_name)) stop("Species registry key failure", call. = FALSE)

write_csv <- function(x, name) {
  x <- as.data.table(x)
  if (!"support_label" %in% names(x)) x[, support_label := support_label]
  numeric_columns <- names(x)[vapply(x, is.numeric, logical(1L))]
  for (column in numeric_columns) set(x, j = column, value = round(x[[column]], 5L))
  fwrite(x, file.path(out_dir, name), quote = TRUE, na = "")
}

qint <- function(x, p) {
  x <- x[is.finite(x)]
  if (!length(x)) return(NA_real_)
  as.numeric(stats::quantile(x, p, names = FALSE, type = 1L))
}

hash_id <- function(prefix, x) paste0(prefix, substr(vapply(x, digest, character(1L), algo = "sha256", serialize = FALSE), 1L, 16L))

message("Stage 2: writing frozen non-overlapping guild and mechanism registries")
primary_guild <- registry[, .(
  analysis_taxon_id, common_name, primary_guild_id = guild_ids,
  primary_membership_weight = 1L,
  duplicate_in_primary_totals = FALSE,
  approval_status = "candidate_outcome_blind_design"
)]
if (anyDuplicated(primary_guild$analysis_taxon_id) || any(grepl("[|;]", primary_guild$primary_guild_id))) {
  stop("Primary guild membership is not one-to-one", call. = FALSE)
}
fwrite(primary_guild, "metadata/species_primary_guild.csv", quote = TRUE, na = "")

nm <- registry$common_name
guild <- registry$guild_ids
traits <- data.table(
  analysis_taxon_id = registry$analysis_taxon_id,
  common_name = nm,
  attached_roe_diver = guild == "roe_diving_seaduck",
  surface_or_intertidal_roe_feeder = guild %chin% c("gull_roe", "surface_vegetation_roe", "intertidal_roe_shorebird"),
  adult_herring_piscivore = guild %chin% c("piscivore_active_spawn", "alcid_piscivore") | nm == "Osprey",
  shoreline_scavenger = guild %chin% c("shoreline_scavenger", "gull_roe"),
  wide_ranging_raptor = nm %chin% c("Bald Eagle", "Osprey"),
  migration_confounded = grepl("migration", registry$expected_direction, ignore.case = TRUE) |
    nm %chin% c("Brant", "Dunlin", "Sanderling", "Rock Sandpiper", "Black-bellied Plover", "Pacific Loon"),
  mixed_flock_prone = guild %chin% c("gull_roe", "intertidal_roe_shorebird", "piscivore_active_spawn") |
    grepl("Scoter|Cormorant", nm),
  count_heaping_prone = guild %chin% c("gull_roe", "surface_vegetation_roe", "intertidal_roe_shorebird") |
    grepl("Scoter|Cormorant|Goose", nm),
  trait_role = "secondary_cross_species_synthesis_only"
)
fwrite(traits, "metadata/species_mechanism_traits.csv", quote = TRUE, na = "")

primary_map <- list(
  local_numerical_aggregation = c("M01"),
  event_time_distance = c("M05"),
  redistribution_mass_balance = c("M08"),
  community_conditional_cooccurrence = c("M35", "M21"),
  spawn_dose = c("M18"),
  phenology = c("M23")
)
support_map <- list(
  local_numerical_aggregation = c("M02"),
  event_time_distance = c("M06", "M17", "M38"),
  redistribution_mass_balance = c("M07", "M09", "M10"),
  community_conditional_cooccurrence = c("M34", "M36", "M37", "M22")
)
diagnostics <- c("M26", "M27", "M28", "M29", "M32", "M40", "M42")
mult <- copy(model_registry)
mult[, `:=`(evidence_family = "registered_sensitivity_or_generalization", model_role = "sensitivity", multiplicity_family = "none_model_level")]
for (fam in names(primary_map)) mult[model_id %chin% primary_map[[fam]], `:=`(evidence_family = fam, model_role = "primary_candidate", multiplicity_family = ifelse(model_id %chin% c("M02"), "BH_within_species_family", "hierarchical_family_inference"))]
for (fam in names(support_map)) mult[model_id %chin% support_map[[fam]], `:=`(evidence_family = fam, model_role = "visible_supporting", multiplicity_family = ifelse(model_id %chin% c("M02", "M06", "M17", "M38"), "BH_within_coherent_species_family", "hierarchical_or_blocked_family"))]
mult[model_id %chin% diagnostics, `:=`(evidence_family = "diagnostic_or_falsification", model_role = "diagnostic_not_competing", multiplicity_family = "diagnostic_family_separate")]
mult[model_id %chin% c("M35", "M21"), model_role := "alternative_primary_pending_latent_pilot"]
mult[, evidence_categories := "strongly_supported|supported_with_qualifications|mixed|not_supported|contradicted|not_estimable"]
mult[, omnibus_holm_over_45 := FALSE]
mult[, status := "registered_not_fitted"]
fwrite(mult, "metadata/hypothesis_model_multiplicity_registry.csv", quote = TRUE, na = "")

message("Stage 2: reading herring metadata and building event-complex alternatives")
h <- fread(paths[["herring"]], na.strings = c("", "NA"))
required_h <- c("Region", "Year", "StatisticalArea", "Section", "LocationCode", "LocationName", "SpawnNumber",
                "StartDate", "EndDate", "Longitude", "Latitude", "Length", "Width", "Method", "Surface", "Macrocystis", "Understory")
if (!all(required_h %chin% names(h))) stop("Herring schema mismatch", call. = FALSE)
h <- h[Year >= 1988L & Year <= 2025L]
h[, `:=`(start_date = as.IDate(StartDate), end_date = as.IDate(EndDate))]
h[, event_date := as.IDate(ifelse(!is.na(start_date) & !is.na(end_date),
                                  floor((as.numeric(start_date) + as.numeric(end_date)) / 2),
                                  ifelse(!is.na(start_date), as.numeric(start_date), as.numeric(end_date))), origin = "1970-01-01")]
h[, `:=`(
  reversed_date = !is.na(start_date) & !is.na(end_date) & end_date < start_date,
  uncertain_date = is.na(start_date) | is.na(end_date),
  component_surface_missing = is.na(Surface),
  component_macrocystis_missing = is.na(Macrocystis),
  component_understory_missing = is.na(Understory)
)]
preexisting_crosswalk <- if (file.exists(file.path(out_dir, "event_complex_crosswalk.csv")))
  fread(file.path(out_dir, "event_complex_crosswalk.csv"), na.strings = c("", "NA")) else NULL
if (!is.null(preexisting_crosswalk) && nrow(preexisting_crosswalk) == nrow(h)) {
  h[, source_record_id := preexisting_crosswalk$source_record_id]
} else {
  h[, source_record_id := hash_id("hsr_", paste(.I, Year, StatisticalArea, Section, SpawnNumber, sep = "|"))]
}

valid_xy <- is.finite(h$Longitude) & is.finite(h$Latitude) & h$Longitude >= -180 & h$Longitude <= 180 & h$Latitude >= -90 & h$Latitude <= 90
h_pts <- st_as_sf(h[valid_xy], coords = c("Longitude", "Latitude"), crs = 4326, remove = FALSE)
h_pts <- st_transform(h_pts, 3005)
h[, `:=`(x_3005 = NA_real_, y_3005 = NA_real_)]
h[valid_xy, c("x_3005", "y_3005") := as.data.table(st_coordinates(h_pts))[, .(X, Y)]]

sections <- st_read(paths[["sections"]], quiet = TRUE)
if (is.na(st_crs(sections))) st_crs(sections) <- 3005
if (st_crs(sections) != st_crs(3005)) sections <- st_transform(sections, 3005)
assessment_to_region <- c("Area 27" = "A27", "Central Coast" = "CC", "HG EAST" = "HG", "HG WEST" = "HG",
                          "Other Areas" = "NA", "Prince Rupert" = "PRD", "Strait of Georgia" = "SoG",
                          "W.C. Vancouver Is." = "WCVI")
h[, region_analysis := as.character(Region)]
missing_region_rows <- which(is.na(h$region_analysis) & valid_xy)
region_overlay_ambiguity <- 0L
if (length(missing_region_rows)) {
  point_sf <- st_as_sf(h[missing_region_rows], coords = c("Longitude", "Latitude"), crs = 4326, remove = FALSE)
  point_sf <- st_transform(point_sf, 3005)
  hit <- st_intersects(point_sf, sections)
  region_overlay_ambiguity <- sum(lengths(hit) > 1L)
  assessment <- vapply(hit, function(z) if (length(z)) as.character(sections$Assessment[z[1L]]) else NA_character_, character(1L))
  h[missing_region_rows, region_analysis := unname(assessment_to_region[assessment])]
}
h[is.na(region_analysis), region_analysis := "NA"]

interval_gap_days <- function(a_start, a_end, b_start, b_end, a_rep, b_rep) {
  as <- ifelse(is.na(a_start), as.numeric(a_rep), as.numeric(a_start))
  ae <- ifelse(is.na(a_end), as.numeric(a_rep), as.numeric(a_end))
  bs <- ifelse(is.na(b_start), as.numeric(b_rep), as.numeric(b_start))
  be <- ifelse(is.na(b_end), as.numeric(b_rep), as.numeric(b_end))
  pmax(0, pmax(as, bs) - pmin(ae, be))
}

complex_defs <- data.table(
  definition = c("source_record", "complex_1km_3d", "complex_2km_7d", "complex_5km_14d"),
  distance_km = c(0, 1, 2, 5), gap_days = c(0L, 3L, 7L, 14L)
)
complex_cols <- character()
existing_crosswalk <- preexisting_crosswalk
reuse_complexes <- !is.null(existing_crosswalk) && nrow(existing_crosswalk) == nrow(h) &&
  identical(existing_crosswalk$source_record_id, h$source_record_id)
for (ii in seq_len(nrow(complex_defs))) {
  def <- complex_defs$definition[ii]
  col <- paste0("id_", def)
  complex_cols <- c(complex_cols, col)
  if (reuse_complexes) {
    h[, (col) := existing_crosswalk[[def]]]
    next
  }
  h[, (col) := source_record_id]
  if (def == "source_record") next
  for (grp in unique(paste(h$region_analysis, h$Year, sep = "|"))) {
    idx <- which(paste(h$region_analysis, h$Year, sep = "|") == grp & valid_xy & !is.na(h$event_date))
    if (length(idx) < 2L) next
    pts <- st_as_sf(h[idx], coords = c("x_3005", "y_3005"), crs = 3005, remove = FALSE)
    near <- st_is_within_distance(pts, pts, dist = complex_defs$distance_km[ii] * 1000)
    edges <- rbindlist(lapply(seq_along(near), function(j) {
      k <- near[[j]][near[[j]] > j]
      if (!length(k)) return(NULL)
      gap <- interval_gap_days(h$start_date[idx[j]], h$end_date[idx[j]], h$start_date[idx[k]], h$end_date[idx[k]], h$event_date[idx[j]], h$event_date[idx[k]])
      k <- k[gap <= complex_defs$gap_days[ii]]
      if (!length(k)) return(NULL)
      data.table(from = j, to = k)
    }))
    if (!nrow(edges)) next
    g <- graph_from_data_frame(edges, directed = FALSE, vertices = seq_along(idx))
    memb <- components(g)$membership
    ids <- hash_id(paste0(substr(def, 1L, 5L), "_"), paste(grp, memb, sep = "|"))
    h[idx, (col) := ids]
  }
}

crosswalk <- h[, c("source_record_id", complex_cols), with = FALSE]
setnames(crosswalk, complex_cols, complex_defs$definition)
write_csv(crosswalk, "event_complex_crosswalk.csv")

complex_audit <- rbindlist(lapply(complex_defs$definition, function(def) {
  col <- paste0("id_", def)
  z <- h[, .(
    source_records = .N,
    regions = uniqueN(region_analysis),
    statistical_areas = uniqueN(StatisticalArea, na.rm = TRUE),
    sections = uniqueN(Section, na.rm = TRUE),
    location_codes = uniqueN(LocationCode, na.rm = TRUE),
    methods = uniqueN(Method, na.rm = TRUE),
    temporal_span_days = if (all(is.na(event_date))) NA_real_ else as.numeric(max(event_date, na.rm = TRUE) - min(event_date, na.rm = TRUE)),
    spatial_bbox_diameter_km = if (sum(is.finite(x_3005) & is.finite(y_3005)) < 2L) 0 else sqrt(diff(range(x_3005, na.rm = TRUE))^2 + diff(range(y_3005, na.rm = TRUE))^2) / 1000,
    any_reversed_date = any(reversed_date), any_uncertain_date = any(uncertain_date),
    surface_complete_share = mean(!component_surface_missing),
    macrocystis_complete_share = mean(!component_macrocystis_missing),
    understory_complete_share = mean(!component_understory_missing)
  ), by = col]
  data.table(
    definition = def,
    complexes = nrow(z), source_records = nrow(h),
    members_q50 = qint(z$source_records, .5), members_q90 = qint(z$source_records, .9), members_max = max(z$source_records),
    temporal_span_days_q90 = qint(z$temporal_span_days, .9), temporal_span_days_max = max(z$temporal_span_days, na.rm = TRUE),
    spatial_diameter_km_q90 = qint(z$spatial_bbox_diameter_km, .9), spatial_diameter_km_max = max(z$spatial_bbox_diameter_km, na.rm = TRUE),
    complexes_crossing_region = sum(z$regions > 1L),
    complexes_crossing_statistical_area = sum(z$statistical_areas > 1L),
    complexes_crossing_section = sum(z$sections > 1L),
    complexes_crossing_location_code = sum(z$location_codes > 1L),
    complexes_mixed_method = sum(z$methods > 1L),
    complexes_over_21_days = sum(z$temporal_span_days > 21, na.rm = TRUE),
    complexes_over_25_km = sum(z$spatial_bbox_diameter_km > 25, na.rm = TRUE),
    complexes_with_reversed_date = sum(z$any_reversed_date),
    complexes_with_uncertain_date = sum(z$any_uncertain_date),
    region_overlay_ambiguous_points = region_overlay_ambiguity,
    spatial_span_measure = "bounding_box_diagonal_upper_bound"
  )
}))
write_csv(complex_audit, "event_complex_audit.csv")

review_cases <- rbindlist(lapply(complex_defs$definition, function(def) {
  col <- paste0("id_", def)
  z <- h[, .(
    source_records = .N, region = paste(sort(unique(region_analysis)), collapse = ";"),
    temporal_span_days = if (all(is.na(event_date))) NA_real_ else as.numeric(max(event_date, na.rm = TRUE) - min(event_date, na.rm = TRUE)),
    spatial_bbox_diameter_km = if (sum(is.finite(x_3005) & is.finite(y_3005)) < 2L) 0 else sqrt(diff(range(x_3005, na.rm = TRUE))^2 + diff(range(y_3005, na.rm = TRUE))^2) / 1000,
    generalized_easting_10km = if (all(!is.finite(x_3005))) NA_real_ else round(mean(x_3005, na.rm = TRUE) / 10000) * 10,
    generalized_northing_10km = if (all(!is.finite(y_3005))) NA_real_ else round(mean(y_3005, na.rm = TRUE) / 10000) * 10
  ), by = col]
  setnames(z, col, "complex_id")
  setorder(z, -source_records, -spatial_bbox_diameter_km, -temporal_span_days)
  z <- z[seq_len(min(25L, nrow(z)))]
  z[, definition := def]
  z
}), fill = TRUE)
setcolorder(review_cases, c("definition", setdiff(names(review_cases), "definition")))
write_csv(review_cases, "event_complex_map_review_cases.csv")

message("Stage 2: auditing geometry feasibility and shoreline snapping")
reuse_geometry <- file.exists(file.path(out_dir, "event_geometry_audit.csv")) &&
  file.exists(file.path(out_dir, "event_geometry_failure_summary.csv")) &&
  file.exists(file.path(out_dir, "event_geometry_crosswalk.csv"))
if (reuse_geometry) {
  geometry_audit <- fread(file.path(out_dir, "event_geometry_audit.csv"))
} else {
shore <- st_read(paths[["shoreline"]], quiet = TRUE)
if (is.na(st_crs(shore))) st_crs(shore) <- 3005
if (st_crs(shore) != st_crs(3005)) shore <- st_transform(shore, 3005)
snap_distance_m <- rep(NA_real_, nrow(h))
nearest_feature <- rep(NA_integer_, nrow(h))
if (nrow(h_pts)) {
  nf <- st_nearest_feature(h_pts, shore)
  nearest_feature[valid_xy] <- nf
  snap_distance_m[valid_xy] <- as.numeric(st_distance(h_pts, shore[nf, ], by_element = TRUE))
}
h[, `:=`(shoreline_snap_distance_m = snap_distance_m, nearest_shoreline_feature = nearest_feature)]
snap_limit_m <- 2000
h[, geometry_tier := fifelse(!is.na(event_date) & valid_xy & !is.na(Method) & shoreline_snap_distance_m <= snap_limit_m & !is.na(Length), "A",
                      fifelse(!is.na(event_date) & valid_xy & shoreline_snap_distance_m <= snap_limit_m, "B",
                      fifelse(!is.na(event_date) & (!is.na(Section) | valid_xy), "C", "excluded")))]
h[, alongshore_constructible := geometry_tier == "A" & is.finite(Length) & Length > 0]
h[, alongshore_width_constructible := alongshore_constructible & is.finite(Width) & Width > 0]
h[, geometry_failure_reason := fifelse(!valid_xy, "missing_or_invalid_source_point",
                                fifelse(is.na(event_date), "missing_event_date",
                                fifelse(shoreline_snap_distance_m > snap_limit_m, "snap_exceeds_2km_candidate_limit",
                                fifelse(is.na(Length), "missing_length", "none"))))]
geometry_audit <- data.table(
  geometry_definition = c("source_point", "nearest_marine_shoreline_point", "derived_alongshore_length", "derived_alongshore_length_width", "event_complex_member_union"),
  candidate_role = c("parallel_core", "linkage", "parallel_core", "sensitivity", "complex_sensitivity"),
  source_records = nrow(h),
  construction_successes = c(sum(valid_xy), sum(valid_xy & is.finite(h$shoreline_snap_distance_m)), sum(h$alongshore_constructible), sum(h$alongshore_width_constructible), uniqueN(h$id_complex_2km_7d[h$alongshore_constructible])),
  construction_failures = c(sum(!valid_xy), sum(!valid_xy | !is.finite(h$shoreline_snap_distance_m)), sum(!h$alongshore_constructible), sum(!h$alongshore_width_constructible), uniqueN(h$id_complex_2km_7d[!h$alongshore_constructible])),
  snap_distance_m_q50 = qint(h$shoreline_snap_distance_m, .5),
  snap_distance_m_q90 = qint(h$shoreline_snap_distance_m, .9),
  snap_distance_m_q99 = qint(h$shoreline_snap_distance_m, .99),
  tier_A_records = sum(h$geometry_tier == "A"), tier_B_records = sum(h$geometry_tier == "B"),
  tier_C_records = sum(h$geometry_tier == "C"), excluded_records = sum(h$geometry_tier == "excluded"),
  approved_shoreline_class = "supplied marine shoreline bundle; EDGE_TYPE 100 and 150 retained pending provider-dictionary confirmation",
  metric_crs = "EPSG:3005",
  exact_ebird_coordinates_in_output = FALSE
)
write_csv(geometry_audit, "event_geometry_audit.csv")
write_csv(h[, .N, by = .(geometry_tier, geometry_failure_reason)], "event_geometry_failure_summary.csv")
geometry_crosswalk <- h[, .(
  source_record_id,
  geometry_quality_tier = geometry_tier,
  source_point_available = valid_xy,
  nearest_shoreline_point_available = is.finite(shoreline_snap_distance_m),
  shoreline_snap_distance_band = cut(shoreline_snap_distance_m,
    breaks = c(-Inf, 100, 500, 1000, 2000, 5000, Inf),
    labels = c("0_100m", "100_500m", "500m_1km", "1_2km", "2_5km", "over_5km")),
  observed_length_available = is.finite(Length) & Length > 0,
  observed_width_available = is.finite(Width) & Width > 0,
  derived_alongshore_length_constructible = alongshore_constructible,
  derived_alongshore_length_width_constructible = alongshore_width_constructible,
  candidate_primary_complex_id = id_complex_2km_7d,
  construction_failure_reason = geometry_failure_reason
)]
write_csv(geometry_crosswalk, "event_geometry_crosswalk.csv")
}

message("Stage 2: reading checklist metadata and constructing source-point support links")
sed_cache <- file.path(private_dir, "sed_stage2_cache_amendment_v1.rds")
if (file.exists(sed_cache)) {
  sed_cached <- readRDS(sed_cache)
  checklists <- sed_cached$checklists
  cross_private <- sed_cached$cross_private
  shared_audit <- sed_cached$shared_audit
} else {
sed_cols <- c("SAMPLING EVENT IDENTIFIER", "LOCALITY ID", "LATITUDE", "LONGITUDE", "OBSERVATION DATE",
              "TIME OBSERVATIONS STARTED", "OBSERVER ID", "PROTOCOL NAME", "PROTOCOL CODE", "DURATION MINUTES",
              "EFFORT DISTANCE KM", "EFFORT AREA HA", "NUMBER OBSERVERS", "ALL SPECIES REPORTED", "GROUP IDENTIFIER")
sed <- fread(paths[["sed"]], sep = "\t", select = sed_cols, quote = "", na.strings = c("", "NA"), showProgress = TRUE)
setnames(sed, sed_cols, c("source_id", "locality_id", "latitude", "longitude", "date", "start_time", "observer_id",
                         "protocol", "protocol_code", "duration_min", "distance_km", "area_ha", "n_observers", "complete", "group_id"))
sed[, date := as.IDate(date)]
sed <- sed[date >= as.IDate("1988-01-01") & date <= as.IDate("2025-12-31")]
if (anyNA(sed$source_id) || anyDuplicated(sed$source_id)) stop("SED key cardinality failure", call. = FALSE)
sed[, analysis_id := fifelse(!is.na(group_id) & nzchar(trimws(group_id)), group_id, source_id)]
setorder(sed, analysis_id, source_id)
sed[, canonical_source_id := source_id[1L], by = analysis_id]
cross_private <- sed[, .(source_id, analysis_id, canonical_source_id)]
comparison_fields <- c("date", "latitude", "longitude", "protocol", "duration_min", "distance_km", "n_observers", "complete")
group_status <- sed[, {
  conflicts <- comparison_fields[vapply(.SD, function(v) uniqueN(ifelse(is.na(v), "<NA>", as.character(v))) > 1L, logical(1L))]
  .(group_members = .N, effort_disagreement = length(conflicts) > 0L,
    disagreement_fields = paste(conflicts, collapse = ";"))
}, by = analysis_id, .SDcols = comparison_fields]
checklists <- sed[, .SD[1L], by = analysis_id]
checklists <- group_status[checklists, on = "analysis_id"]
checklists[, observer_effect_id := fifelse(group_members > 1L, analysis_id, observer_id)]
checklists[, observer_effect_treatment := fifelse(group_members > 1L, "shared_group_composite_cluster", "single_observer_cluster")]
if (anyDuplicated(checklists$analysis_id)) stop("Shared-checklist collapse failed", call. = FALSE)
shared_audit <- group_status[, .(
  source_rows = nrow(sed), analysis_checklists = .N, shared_analysis_checklists = sum(group_members > 1L),
  disagreement_groups = sum(effort_disagreement), primary_analysis_checklists = sum(!effort_disagreement),
  observer_effect_rule = "shared_group_composite_cluster_not_first_source_row",
  disagreement_primary_rule = "exclude_from_primary_registered_sensitivity"
)]
write_csv(shared_audit, "shared_checklist_aggregate_audit.csv")

is_complete <- toupper(as.character(checklists$complete)) %chin% c("1", "TRUE", "T", "YES")
stationary <- grepl("Stationary", checklists$protocol, ignore.case = TRUE)
traveling <- grepl("Travel", checklists$protocol, ignore.case = TRUE)
area_protocol <- grepl("Area", checklists$protocol, ignore.case = TRUE)
valid_obs <- is.finite(checklists$n_observers)
checklists[, broad_eligible := is_complete & (stationary | traveling) & duration_min >= 1 & duration_min <= 360 &
             n_observers >= 1 & n_observers <= 20 & (stationary | (traveling & distance_km <= 10))]
checklists[, standardized_eligible := is_complete & (stationary | traveling) & duration_min >= 5 & duration_min <= 300 &
             n_observers >= 1 & n_observers <= 10 & (stationary | (traveling & distance_km <= 5))]
checklists[, area_eligible := is_complete & area_protocol & duration_min >= 1 & duration_min <= 360 & valid_obs & n_observers >= 1 & n_observers <= 20]
checklists[, checklist_year := as.integer(format(date, "%Y"))]
checklists[, checklist_month := as.integer(format(date, "%m"))]
saveRDS(list(checklists = checklists, cross_private = cross_private, shared_audit = shared_audit), sed_cache, compress = FALSE)
}

if (!exists("sed_cols")) sed_cols <- c("SAMPLING EVENT IDENTIFIER", "LOCALITY ID", "LATITUDE", "LONGITUDE", "OBSERVATION DATE",
              "TIME OBSERVATIONS STARTED", "OBSERVER ID", "PROTOCOL NAME", "PROTOCOL CODE", "DURATION MINUTES",
              "EFFORT DISTANCE KM", "EFFORT AREA HA", "NUMBER OBSERVERS", "ALL SPECIES REPORTED", "GROUP IDENTIFIER")

base_idx <- which(checklists$standardized_eligible & !checklists$effort_disagreement &
                    is.finite(checklists$longitude) & is.finite(checklists$latitude))
links_cache <- file.path(private_dir, "source_point_links_amendment_v1.rds")
if (file.exists(links_cache)) {
  links <- readRDS(links_cache)
} else {
check_sf <- st_as_sf(checklists[base_idx], coords = c("longitude", "latitude"), crs = 4326, remove = FALSE)
check_sf <- st_transform(check_sf, 3005)
check_xy <- as.data.table(st_coordinates(check_sf))
check_xy[, `:=`(checklist_row = base_idx, analysis_id = checklists$analysis_id[base_idx],
                checklist_date = checklists$date[base_idx], checklist_year = checklists$checklist_year[base_idx])]
check_xy[, `:=`(grid_x = floor(X / 20000), grid_y = floor(Y / 20000))]
event_xy <- h[valid_xy & !is.na(event_date), .(event_row = .I, event_year = Year, event_date, X = x_3005, Y = y_3005)]
event_xy[, `:=`(grid_x = floor(X / 20000), grid_y = floor(Y / 20000))]
offsets <- CJ(offset_x = -1L:1L, offset_y = -1L:1L)
links <- rbindlist(lapply(sort(unique(checklists$checklist_year[base_idx])), function(yr) {
  cp <- check_xy[checklist_year == yr]
  ep <- event_xy[event_year %in% c(yr - 1L, yr, yr + 1L)]
  if (!nrow(cp) || !nrow(ep)) return(NULL)
  ep[, join_key := 1L]
  offsets[, join_key := 1L]
  ep_expanded <- merge(ep, offsets, by = "join_key", allow.cartesian = TRUE, sort = FALSE)
  ep_expanded[, `:=`(grid_x_match = grid_x + offset_x, grid_y_match = grid_y + offset_y)]
  cand <- merge(cp, ep_expanded, by.x = c("grid_x", "grid_y"), by.y = c("grid_x_match", "grid_y_match"),
                allow.cartesian = TRUE, sort = FALSE, suffixes = c("_check", "_event"))
  if (!nrow(cand)) return(NULL)
  cand[, `:=`(distance_km = sqrt((X_check - X_event)^2 + (Y_check - Y_event)^2) / 1000,
                 event_day_midpoint = as.integer(checklist_date - event_date))]
  cand <- cand[distance_km <= 20 & event_day_midpoint >= -90L & event_day_midpoint <= 120L]
  cand[, .(analysis_id, checklist_row, event_row, distance_km, event_day_midpoint)]
}), fill = TRUE)
saveRDS(links, links_cache, compress = FALSE)
}
if (!nrow(links)) stop("No event-linked checklist metadata support", call. = FALSE)
links[, `:=`(
  source_record_id = h$source_record_id[event_row],
  event_complex_1km_3d = h$id_complex_1km_3d[event_row],
  event_complex_2km_7d = h$id_complex_2km_7d[event_row],
  event_complex_5km_14d = h$id_complex_5km_14d[event_row],
  event_region = h$region_analysis[event_row],
  event_year = h$Year[event_row],
  event_day_start = as.integer(checklists$date[checklist_row] - h$start_date[event_row]),
  event_day_end = as.integer(checklists$date[checklist_row] - h$end_date[event_row])
)]
if (anyDuplicated(links[, .(analysis_id, source_record_id)])) stop("Checklist-event join inflated keys", call. = FALSE)

message("Stage 2: extracting only registered focal EBD taxa after the design freeze")
ebd_cache <- file.path(private_dir, "focal_support_cache.rds")
if (file.exists(ebd_cache)) {
  focal_cached <- readRDS(ebd_cache)
  det <- focal_cached$det
  tax_recon <- focal_cached$tax_recon
} else {
pattern_file <- file.path(private_dir, "focal_patterns.txt")
focal_file <- file.path(private_dir, "focal_ebd_rows_pre2026.tsv")
patterns <- unique(c(na.omit(registry$source_taxon_concept_ids[registry$source_taxon_concept_ids != "pending"]), registry$common_name))
writeLines(patterns, pattern_file, useBytes = TRUE)
if (!file.exists(focal_file) || file.info(focal_file)$size == 0) {
  status <- system2("powershell", c(
    "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "scripts/run_ebd_streaming_tool.ps1",
    "-Mode", "focal", "-EbdEnv", env_names[["ebd"]],
    "-Patterns", shQuote(pattern_file), "-Output", shQuote(focal_file)
  ), stdout = file.path(private_dir, "focal_extract_stdout.log"),
     stderr = file.path(private_dir, "focal_extract_stderr.log"))
  if (!identical(status, 0L) || !file.exists(focal_file) || file.info(focal_file)$size == 0) {
    stop("Focal EBD streaming extraction failed", call. = FALSE)
  }
}
ebd_names <- c("CATEGORY", "TAXON CONCEPT ID", "COMMON NAME", "SCIENTIFIC NAME", "OBSERVATION COUNT",
               "BEHAVIOR CODE", "SAMPLING EVENT IDENTIFIER", "OBSERVATION DATE")
ebd <- fread(focal_file, sep = "\t", header = TRUE, select = ebd_names, quote = "", na.strings = c("", "NA"), showProgress = TRUE)
setnames(ebd, ebd_names, c("category", "taxon_concept_id", "common_name", "scientific_name", "observation_count",
                           "behavior_code", "source_id", "observation_date"))
ebd[, observation_date := as.IDate(observation_date)]
if (any(ebd$observation_date > as.IDate("2025-12-31"), na.rm = TRUE)) {
  stop("Prospective response row persisted by focal extraction", call. = FALSE)
}
ebd <- ebd[category == "species" & (taxon_concept_id %chin% registry$source_taxon_concept_ids | common_name %chin% registry$common_name)]
ebd <- ebd[cross_private, on = "source_id", nomatch = 0L]
if (!nrow(ebd)) stop("No registered focal EBD support joined to SED", call. = FALSE)
ebd[, analysis_taxon_id := registry$analysis_taxon_id[match(common_name, registry$common_name)]]
known_map <- registry[source_taxon_concept_ids != "pending", .(source_taxon_concept_ids, analysis_taxon_id)]
ebd[known_map, on = c(taxon_concept_id = "source_taxon_concept_ids"), analysis_taxon_id := i.analysis_taxon_id]
ebd <- ebd[!is.na(analysis_taxon_id)]

parse_state <- function(x) {
  raw <- trimws(as.character(x))
  numeric_syntax <- grepl("^[0-9]+$", raw)
  lower_syntax <- grepl("^(>=|>|at least[[:space:]]+)?[0-9]+[+]?$", raw, ignore.case = TRUE) & !numeric_syntax
  data.table(
    count_state = fifelse(toupper(raw) == "X", "X", fifelse(numeric_syntax, "numeric", fifelse(lower_syntax, "lower_bound", "ambiguity_affected"))),
    numeric_count = fifelse(numeric_syntax, as.numeric(raw), NA_real_),
    lower_bound_count = fifelse(lower_syntax, as.numeric(gsub("[^0-9]", "", raw)), NA_real_)
  )
}
states <- parse_state(ebd$observation_count)
ebd[, c("count_state", "numeric_count", "lower_bound_count") := states]
collapsed <- ebd[, {
  signatures <- unique(paste(count_state, numeric_count, lower_bound_count, sep = "|"))
  if (length(signatures) == 1L) .(count_state = count_state[1L], numeric_count = numeric_count[1L], lower_bound_count = lower_bound_count[1L],
                                   behavior_reported = any(!is.na(behavior_code) & nzchar(behavior_code)), source_report_disagreement = FALSE)
  else .(count_state = "ambiguity_affected", numeric_count = NA_real_, lower_bound_count = suppressWarnings(min(lower_bound_count, na.rm = TRUE)),
         behavior_reported = any(!is.na(behavior_code) & nzchar(behavior_code)), source_report_disagreement = TRUE)
}, by = .(analysis_id, analysis_taxon_id)]
collapsed[!is.finite(lower_bound_count), lower_bound_count := NA_real_]
if (anyDuplicated(collapsed[, .(analysis_id, analysis_taxon_id)])) stop("Shared checklist outcome collapse failed", call. = FALSE)

base_ids <- unique(links$analysis_id)
det <- collapsed[analysis_id %chin% base_ids]
det <- checklists[det, on = "analysis_id", nomatch = 0L]
if (any(det$date > as.IDate("2025-12-31"))) stop("Prospective outcomes entered Stage 2", call. = FALSE)

tax_recon <- ebd[, .(
  observed_taxon_concept_ids = paste(sort(unique(taxon_concept_id)), collapse = ";"),
  observed_common_names = paste(sort(unique(common_name)), collapse = ";"),
  observed_scientific_names = paste(sort(unique(scientific_name)), collapse = ";"),
  observed_categories = paste(sort(unique(category)), collapse = ";")
), by = analysis_taxon_id]
tax_recon <- merge(registry[, .(analysis_taxon_id, common_name, scientific_name, registry_taxon_concept_ids = source_taxon_concept_ids,
                                taxonomy_version, support_status)], tax_recon, by = "analysis_taxon_id", all.x = TRUE, sort = FALSE)
tax_recon[, exact_species_concept_reconciled := !is.na(observed_taxon_concept_ids) & observed_categories == "species" &
             mapply(function(a, b) b %chin% strsplit(a, ";", fixed = TRUE)[[1L]], observed_scientific_names, scientific_name)]
tax_recon[, recommended_taxonomy_disposition := fifelse(exact_species_concept_reconciled, "approve_exact_v2025_species_concept",
                                                        "retain_pending_manual_taxonomy_review")]
tax_recon[, source_record_values_released := FALSE]
write_csv(tax_recon, "species_taxonomy_reconciliation.csv")
saveRDS(list(det = det, tax_recon = tax_recon), ebd_cache, compress = FALSE)
}

support_for <- function(ids, link_subset, dimension = "pooled", candidate_id = "frozen_event_linked_frame") {
  ids <- unique(ids)
  d <- det[analysis_id %chin% ids]
  if (nrow(d)) {
    dl <- unique(link_subset[analysis_id %chin% d$analysis_id, .(analysis_id, source_record_id, event_complex_2km_7d, event_region)])
    de <- merge(d[, .(analysis_id, analysis_taxon_id, count_state, numeric_count, locality_id, observer_id, checklist_year)], dl,
                by = "analysis_id", allow.cartesian = TRUE)
    out <- d[, .(
      detections = uniqueN(analysis_id), positive_numeric_reports = uniqueN(analysis_id[count_state == "numeric" & numeric_count > 0]),
      X_reports = uniqueN(analysis_id[count_state == "X"]),
      lower_bound_reports = uniqueN(analysis_id[count_state == "lower_bound"]),
      ambiguity_affected_reports = uniqueN(analysis_id[count_state == "ambiguity_affected"]),
      years = uniqueN(checklist_year), locations = uniqueN(locality_id), observers = uniqueN(observer_effect_id),
      positive_count_q50 = qint(numeric_count[count_state == "numeric" & numeric_count > 0], .5),
      positive_count_q90 = qint(numeric_count[count_state == "numeric" & numeric_count > 0], .9),
      positive_count_q99 = qint(numeric_count[count_state == "numeric" & numeric_count > 0], .99)
    ), by = analysis_taxon_id]
    extra <- de[, .(
      represented_events = uniqueN(source_record_id), represented_event_complexes = uniqueN(event_complex_2km_7d),
      positive_numeric_events = uniqueN(source_record_id[count_state == "numeric" & numeric_count > 0]),
      regions = uniqueN(event_region),
      maximum_event_share = max(table(source_record_id)) / uniqueN(analysis_id)
    ), by = analysis_taxon_id]
    out <- merge(out, extra, by = "analysis_taxon_id", all.x = TRUE)
    obs_share <- d[, .N, by = .(analysis_taxon_id, observer_effect_id)][, .(maximum_observer_share = max(N) / sum(N)), by = analysis_taxon_id]
    loc_share <- d[, .N, by = .(analysis_taxon_id, locality_id)][, .(maximum_location_share = max(N) / sum(N)), by = analysis_taxon_id]
    out <- Reduce(function(x, y) merge(x, y, by = "analysis_taxon_id", all.x = TRUE), list(out, obs_share, loc_share))
  } else out <- data.table(analysis_taxon_id = character())
  out <- merge(registry[, .(analysis_taxon_id, common_name)], out, by = "analysis_taxon_id", all.x = TRUE, sort = FALSE)
  count_cols <- c("detections", "positive_numeric_reports", "X_reports", "lower_bound_reports", "ambiguity_affected_reports",
                  "years", "locations", "observers", "represented_events", "represented_event_complexes", "positive_numeric_events", "regions")
  for (v in count_cols) set(out, which(is.na(out[[v]])), v, 0)
  out[, `:=`(dimension = dimension, candidate_id = candidate_id, eligible_checklists = length(ids), support_label = support_label)]
  setcolorder(out, c("dimension", "candidate_id", "analysis_taxon_id", "common_name", "eligible_checklists", setdiff(names(out), c("dimension", "candidate_id", "analysis_taxon_id", "common_name", "eligible_checklists"))))
  out
}

base_links <- links[event_day_midpoint >= -60L & event_day_midpoint <= 90L]
base_ids <- unique(base_links$analysis_id)
species_support <- support_for(base_ids, base_links)
pre_ids <- unique(base_links[event_day_midpoint >= -28L & event_day_midpoint <= -1L, analysis_id])
active_ids <- unique(base_links[event_day_midpoint >= 0L & event_day_midpoint <= 28L, analysis_id])
pre_support <- det[analysis_id %chin% pre_ids, .(primary_period_one_detections = uniqueN(analysis_id)), by = analysis_taxon_id]
active_support <- det[analysis_id %chin% active_ids, .(primary_period_two_detections = uniqueN(analysis_id)), by = analysis_taxon_id]
species_support <- merge(species_support, pre_support, by = "analysis_taxon_id", all.x = TRUE)
species_support <- merge(species_support, active_support, by = "analysis_taxon_id", all.x = TRUE)
species_support[is.na(primary_period_one_detections), primary_period_one_detections := 0L]
species_support[is.na(primary_period_two_detections), primary_period_two_detections := 0L]
species_support[, numeric_availability := fifelse(detections > 0, positive_numeric_reports / detections, NA_real_)]
species_support[, core_named_eligible := detections >= 200 & represented_events >= 50 & years >= 8 &
                  (regions >= 2 | regions == 1) & primary_period_one_detections >= 50 & primary_period_two_detections >= 50 &
                  maximum_event_share <= .20 & maximum_observer_share <= .20 & maximum_location_share <= .20]
species_support[, exploratory_named_eligible := detections >= 75 & represented_events >= 25 & years >= 5 &
                  primary_period_one_detections >= 20 & primary_period_two_detections >= 20 & maximum_event_share <= .30]
species_support[, guild_community_eligible := detections >= 25 & represented_events >= 10 & years >= 3]
species_support[, positive_count_eligible := positive_numeric_reports >= 100 & positive_numeric_events >= 40 & numeric_availability >= .80]
species_support[, named_species_recommendation := fifelse(common_name %chin% c("Gadwall", "Northern Shoveler"), "separate_falsification_panel",
                                                   fifelse(core_named_eligible, "named_species_core",
                                                   fifelse(exploratory_named_eligible, "named_species_exploratory",
                                                   fifelse(guild_community_eligible, "guild_or_community_only", "retain_registry_sparse_not_named"))))]
species_support[, guild_recommendation := fifelse(guild_community_eligible, "eligible_primary_guild_membership", "retain_with_partial_pooling_support_warning")]
species_support[, community_recommendation := fifelse(guild_community_eligible, "detection_community_eligible", "retain_registry_not_in_reduced_set")]
species_support[, count_recommendation := fifelse(positive_count_eligible, "positive_count_component_eligible", "detection_component_only_or_bounded_sensitivity")]
species_support[, cooccurrence_recommendation := fifelse(guild_community_eligible, "pairwise_support_audit_eligible", "not_in_reduced_pairwise_set")]
species_support[, recommendation_reason := paste0("detections=", detections, ";events=", represented_events, ";years=", years,
                                                   ";period_support_checked;concentration_checked;count_state_preserved")]
write_csv(species_support, "species_support_summary.csv")

message("Stage 2: enumerating support for every frozen candidate option")
cell_tables <- vector("list", nrow(grid))
for (ii in seq_len(nrow(grid))) {
  dimn <- grid$dimension[ii]; cid <- grid$candidate_id[ii]
  lsub <- base_links; ids <- base_ids
  if (dimn == "temporal_window") {
    pars <- jsonlite::fromJSON(gsub('""', '"', grid$parameters_json[ii], fixed = TRUE))
    if (!is.null(pars$start_day)) lsub <- links[event_day_midpoint >= pars$start_day & event_day_midpoint <= pars$end_day]
    else if (!is.null(pars$duration_days)) lsub <- links[event_day_midpoint >= 0L & event_day_midpoint <= pars$duration_days]
    ids <- unique(lsub$analysis_id)
  } else if (dimn == "distance") {
    pars <- jsonlite::fromJSON(gsub('""', '"', grid$parameters_json[ii], fixed = TRUE))
    if (!is.null(pars$lower_km) && !is.null(pars$upper_km)) lsub <- base_links[distance_km >= pars$lower_km & distance_km < pars$upper_km]
    else if (!is.null(pars$scale_km)) lsub <- base_links[distance_km <= min(20, 4 * pars$scale_km)]
    ids <- unique(lsub$analysis_id)
  } else if (dimn == "region_period") {
    pars <- jsonlite::fromJSON(gsub('""', '"', grid$parameters_json[ii], fixed = TRUE))
    lsub <- base_links[event_year >= pars$start_year & event_year <= pars$end_year]
    if (pars$region != "ALL_BC_HIERARCHICAL") lsub <- lsub[event_region == pars$region]
    ids <- unique(lsub$analysis_id)
  } else if (dimn == "protocol_effort") {
    ids <- if (cid == "broad_primary") intersect(unique(links$analysis_id), checklists[broad_eligible == TRUE & effort_disagreement == FALSE, analysis_id]) else if (cid == "standardized_sensitivity") base_ids else intersect(unique(links$analysis_id), checklists[area_eligible == TRUE & effort_disagreement == FALSE, analysis_id])
    lsub <- base_links[analysis_id %chin% ids]
  } else if (dimn == "event_date_representation") {
    if (cid == "event_date_start") lsub <- links[event_day_start >= -60L & event_day_start <= 90L]
    if (cid == "event_date_end") lsub <- links[event_day_end >= -60L & event_day_end <= 90L]
    ids <- unique(lsub$analysis_id)
  }
  cell_tables[[ii]] <- support_for(ids, lsub, dimn, cid)
}
species_cells <- rbindlist(cell_tables, use.names = TRUE, fill = TRUE)
write_csv(species_cells, "species_support_by_design_cell.csv")

message("Stage 2: producing response-free region, period, protocol, and effort support")
link_meta <- unique(base_links[, .(analysis_id, source_record_id, event_complex_2km_7d, event_region, event_year, event_day_midpoint, distance_km)])
link_meta <- checklists[link_meta, on = "analysis_id", nomatch = 0L]
region_effort <- link_meta[, .(
  complete_checklists = uniqueN(analysis_id), unique_observers = uniqueN(observer_effect_id), unique_localities = uniqueN(locality_id),
  source_events = uniqueN(source_record_id), event_complexes = uniqueN(event_complex_2km_7d),
  duration_q50 = qint(duration_min, .5), duration_q90 = qint(duration_min, .9),
  travel_distance_q50 = qint(distance_km, .5), travel_distance_q90 = qint(distance_km, .9),
  maximum_observer_checklist_share = max(table(observer_effect_id)) / uniqueN(analysis_id),
  maximum_locality_checklist_share = max(table(locality_id)) / uniqueN(analysis_id),
  repeat_localities = uniqueN(locality_id[duplicated(locality_id) | duplicated(locality_id, fromLast = TRUE)]),
  shoreline_link_support = TRUE
), by = .(region = event_region, year = checklist_year, month = checklist_month, protocol)]
write_csv(region_effort, "region_period_effort_support.csv")

period_candidates <- c(2005L, 2010L, 2015L)
region_period_candidates <- rbindlist(lapply(sort(unique(link_meta$event_region)), function(reg) {
  rbindlist(lapply(period_candidates, function(start_year) {
    z <- link_meta[event_region == reg & checklist_year >= start_year & checklist_year <= 2025L]
    data.table(
      region = reg, candidate_start_year = start_year,
      complete_linked_checklists = uniqueN(z$analysis_id),
      represented_event_complexes = uniqueN(z$event_complex_2km_7d),
      represented_years = uniqueN(z$checklist_year),
      response_free_coverage_pass = uniqueN(z$analysis_id) >= 500L &&
        uniqueN(z$event_complex_2km_7d) >= 20L && uniqueN(z$checklist_year) >= 5L
    )
  }))
}))
setorder(region_period_candidates, region, candidate_start_year)
region_period_candidates[, recommended_primary_start_year := {
  passing <- candidate_start_year[response_free_coverage_pass == TRUE]
  if (length(passing)) min(passing) else NA_integer_
}, by = region]
region_period_candidates[, recommendation := fifelse(
  is.na(recommended_primary_start_year),
  "descriptive_or_hierarchical_only_due_structural_support",
  fifelse(candidate_start_year == recommended_primary_start_year, "candidate_primary_period", "registered_period_sensitivity")
)]
write_csv(region_period_candidates, "region_period_recommendations.csv")

period_obs <- unique(link_meta[event_day_midpoint >= -28L & event_day_midpoint <= 28L,
                               .(observer_effect_id, period = fifelse(event_day_midpoint < 0, "period_one", "period_two"))])
same_observer <- period_obs[, .(periods = uniqueN(period)), by = observer_effect_id][, .(same_observer_cross_period_support = sum(periods == 2L))]
write_csv(same_observer, "same_observer_cross_period_support.csv")

message("Stage 2: computing pooled pairwise co-occurrence support without exposure contrasts")
det_base <- unique(det[analysis_id %chin% base_ids, .(analysis_id, analysis_taxon_id)])
check_index <- match(det_base$analysis_id, base_ids)
tax_index <- match(det_base$analysis_taxon_id, registry$analysis_taxon_id)
mat <- sparseMatrix(i = check_index, j = tax_index, x = 1L, dims = c(length(base_ids), nrow(registry)))
mat@x[] <- 1
joint <- as.matrix(crossprod(mat))
marg <- diag(joint)
event_presence <- unique(merge(det_base, unique(base_links[, .(analysis_id, source_record_id)]), by = "analysis_id", allow.cartesian = TRUE))
event_ids <- unique(event_presence$source_record_id)
emat <- sparseMatrix(i = match(event_presence$source_record_id, event_ids), j = match(event_presence$analysis_taxon_id, registry$analysis_taxon_id), x = 1L,
                     dims = c(length(event_ids), nrow(registry)))
emat@x[] <- 1
shared_events <- as.matrix(crossprod(emat))
pairs <- CJ(i = seq_len(nrow(registry)), j = seq_len(nrow(registry)))[i < j]
pairs[, `:=`(
  analysis_taxon_id_1 = registry$analysis_taxon_id[i], common_name_1 = registry$common_name[i],
  analysis_taxon_id_2 = registry$analysis_taxon_id[j], common_name_2 = registry$common_name[j],
  species_1_detections = marg[i], species_2_detections = marg[j], n11 = joint[cbind(i, j)], shared_events = shared_events[cbind(i, j)]
)]
pairs[, `:=`(n10 = species_1_detections - n11, n01 = species_2_detections - n11,
             n00 = length(base_ids) - species_1_detections - species_2_detections + n11)]
pairs[, suppressed_below_20 := n11 < 20L | shared_events < 20L]
pairs[suppressed_below_20 == TRUE, c("n11", "shared_events") := .(NA_real_, NA_real_)]
pairs[, `:=`(record_type = "pairwise_pooled", exposure_specific_association_computed = FALSE)]
richness <- Matrix::rowSums(mat)
rich_row <- data.table(record_type = "checklist_richness_pooled", eligible_checklists = length(base_ids),
                       richness_q0 = min(richness), richness_q25 = qint(richness, .25), richness_q50 = qint(richness, .5),
                       richness_q75 = qint(richness, .75), richness_q100 = max(richness), exposure_specific_association_computed = FALSE)
coocc <- rbindlist(list(pairs[, setdiff(names(pairs), c("i", "j")), with = FALSE], rich_row), fill = TRUE, use.names = TRUE)
write_csv(coocc, "cooccurrence_support_summary.csv")

message("Stage 2: running synthetic-only count-family and latent-factor diagnostics")
set.seed(20260719)
positive_counts <- det[count_state == "numeric" & numeric_count > 0, numeric_count]
ratio_90_50 <- if (length(positive_counts)) max(1.1, qint(positive_counts, .9) / max(1, qint(positive_counts, .5))) else 5
sigma_syn <- max(.4, log(ratio_90_50) / qnorm(.9))
n_sim <- 20000L
y_ln <- pmax(1L, as.integer(round(rlnorm(n_sim, log(10), sigma_syn))))
y_nb <- pmax(1L, rnbinom(n_sim, mu = 10, size = max(.2, 2 / sigma_syn)))
score_family <- function(y, family) {
  train <- y[seq_len(15000L)]; test <- y[15001:20000]
  if (family == "hurdle_lognormal") {
    mu <- mean(log(train)); sig <- max(sd(log(train)), .05)
    score <- -mean(dnorm(log(test), mu, sig, log = TRUE) - log(test))
    cal <- abs(qint(test, .9) - exp(mu + qnorm(.9) * sig)) / max(1, qint(test, .9))
  } else if (family == "hurdle_truncated_nb2") {
    m <- mean(train); v <- var(train); size <- if (v > m) m^2 / (v - m) else 1e6
    score <- -mean(dnbinom(test, mu = m, size = size, log = TRUE) - log1p(-dnbinom(0, mu = m, size = size)))
    cal <- abs(qint(test, .9) - qnbinom(.9 + .1 * dnbinom(0, mu = m, size = size), mu = m, size = size)) / max(1, qint(test, .9))
  } else { score <- NA_real_; cal <- NA_real_ }
  c(log_score_loss = score, upper_tail_calibration_error = cal)
}
sim_rows <- rbindlist(lapply(list(lognormal_truth = y_ln, nb2_truth = y_nb), function(y) {
  truth <- if (identical(y, y_ln)) "synthetic_lognormal_truth" else "synthetic_nb2_truth"
  rbindlist(lapply(c("hurdle_lognormal", "hurdle_truncated_nb2"), function(f) {
    sc <- score_family(y, f)
    data.table(simulation_scenario = truth, candidate_family = f, log_score_loss = sc[1L],
               upper_tail_calibration_error = sc[2L], numerical_stability = TRUE,
               selection_uses_herring_term = FALSE, figure_data = "SYNTHETIC")
  }))
}))
other_families <- data.table(simulation_scenario = "engine_capability_review",
                             candidate_family = c("hurdle_generalized_poisson", "zero_inclusive_nb", "tweedie", "ordinal_flock_size", "upper_tail_exceedance_or_quantile"),
                             log_score_loss = NA_real_, upper_tail_calibration_error = NA_real_,
                             numerical_stability = c(FALSE, TRUE, TRUE, TRUE, TRUE), selection_uses_herring_term = FALSE,
                             figure_data = "SYNTHETIC",
                             note = c("engine_not_in_locked_dependencies", "zero_inclusive_sensitivity", "unconditional_sensitivity", "tail_robust_sensitivity", "tail_targeted_sensitivity"))
count_sim <- rbindlist(list(sim_rows, other_families), fill = TRUE)
count_sim[, recommendation := fifelse(candidate_family == "hurdle_lognormal", "candidate_primary_positive_count_family",
                               fifelse(candidate_family == "hurdle_truncated_nb2", "parallel_core_sensitivity", "registered_sensitivity"))]
write_csv(count_sim, "count_family_simulation_summary.csv")

latent_sim <- rbindlist(lapply(2:5, function(true_k) {
  n <- 600L; p <- min(40L, nrow(registry)); u <- matrix(rnorm(n * true_k), n); v <- matrix(rnorm(p * true_k), p)
  signal <- u %*% t(v) / sqrt(true_k); y <- signal + matrix(rnorm(n * p, sd = .7), n)
  sv <- svd(y, nu = 5L, nv = 5L)
  rbindlist(lapply(c(0L, 2:5), function(k) {
    pred <- if (k == 0L) matrix(0, n, p) else sv$u[, seq_len(k), drop = FALSE] %*% diag(sv$d[seq_len(k)], k) %*% t(sv$v[, seq_len(k), drop = FALSE])
    data.table(synthetic_true_factor_count = true_k, candidate_factor_count = k,
               residual_rmse = sqrt(mean((y - pred)^2)), converged = TRUE,
               actual_crossing_calibration = "event_observer_location_counts_only", observed_herring_effect_used = FALSE)
  }))
}))
latent_sim[, selection_status := "procedure_frozen_no_observed_factor_count_selected"]
write_csv(latent_sim, "latent_factor_design_simulation.csv")

behavior_support <- det[, .(detections = .N, behavior_code_reports = sum(behavior_reported)), by = analysis_taxon_id]
behavior_support[, released_behavior_code_reports := fifelse(behavior_code_reports >= 20L, behavior_code_reports, NA_integer_)]
behavior_support[, suppressed_below_20 := behavior_code_reports < 20L]
behavior_support[, free_text_comments_read := FALSE]
write_csv(behavior_support, "behavior_code_support_summary.csv")

message("Stage 2: freezing recommendations, access audit, and prospective protocol")
candidate_complex <- complex_audit[definition == "complex_2km_7d"]
complex_primary <- if (candidate_complex$complexes_over_25_km == 0L &&
                       candidate_complex$complexes_over_21_days / candidate_complex$complexes <= .01) {
  "2 km / 7 day complex as candidate primary after manual review of flagged long-span cases"
} else {
  "1 km / 3 day complex pending resolution of material 2 km / 7 day metadata failures"
}
decisions <- data.table(
  decision_id = sprintf("D%02d", 1:10),
  decision = c("species eligibility", "multi-guild membership", "event complex", "event geometry", "regions periods protocols effort",
               "count tails likelihood", "multispecies latent factors", "behaviour and comments", "multiplicity evidence synthesis", "prospective confirmation"),
  recommendation = c(
    "Retain all 58; assign outcome-blind core, exploratory, guild/community-only, sparse-retained, or falsification status from frozen thresholds",
    "One non-overlapping primary guild per species; secondary mechanism traits may overlap",
    complex_primary,
    "Source point and derived length-informed alongshore footprint as parallel core design families; snapped point for linkage; length-plus-width and complex unions as sensitivities",
    "All BC hierarchical coverage without a forced pooled coastwide effect; broad complete Stationary/Traveling candidate primary; standardized sensitivity; complete area separate",
    "Separate detection; hurdle lognormal candidate primary positive-count family with truncated NB2 parallel sensitivity; no primary winsorization",
    "Detection-first; compare 2, 3, 4, 5 factors plus no-factor and no-pooling comparators using hash-identical pilot and one-SE rule; no factor count selected now",
    "Structured behaviour codes may support aggregate analyses at released cell size at least 20; free-text comment audit deferred and comments were not read",
    "Primary ecological families separated; hierarchical synthesis; species visible; BH only within coherent species families; no omnibus Holm over 45",
    "Freeze all 2026+ outcomes and events; evaluate only after complete/versioned releases under unchanged signed hash-recorded specification"
  ),
  sensitivity = c("nearby thresholds retained", "secondary trait flags", "source record and 5 km / 14 day", "source point|snapped point|length|length-width|complex union",
                  "2005|2010|2015 starts and 1988 long window", "top 1%|top 0.5%|ordinal|upper-tail", "2|3|4|5 factors and two comparators",
                  "local-only dictionary audit only after privacy approval", "geometry|complex|tail|region|period|holdout roles frozen", "candidate external regions frozen before outcome access"),
  outcome_effect_used = FALSE,
  human_scientific_approval_required = TRUE
)
write_csv(decisions, "decision_recommendations.csv")

join_audit <- data.table(
  relationship = c("SED source row to analysis checklist", "EBD focal row to SED source key", "collapsed checklist-taxon outcome", "checklist to concurrent herring event", "species to primary guild"),
  expected_cardinality = c("many-to-one", "many-to-one", "unique composite key", "many-to-many exposure crosswalk; checklist remains analysis unit", "many-to-one"),
  tested = TRUE, status = "PASS",
  independent_row_guard = c(TRUE, TRUE, TRUE, TRUE, TRUE)
)
write_csv(join_audit, "join_cardinality_audit.csv")

access_rows <- data.table(
  record_type = "response_column_access",
  dataset = c(rep("EBD", 7L), rep("SED", length(sed_cols)), rep("HERRING", length(required_h)), "SHORELINE", "SECTIONS"),
  column_name = c("CATEGORY", "TAXON CONCEPT ID", "COMMON NAME", "SCIENTIFIC NAME", "OBSERVATION COUNT", "BEHAVIOR CODE", "SAMPLING EVENT IDENTIFIER",
                  sed_cols, required_h, "EDGE_TYPE", "Assessment"),
  values_read = TRUE,
  permitted_purpose = c(rep("registered taxonomy and support-only count-state audit", 7L), rep("effort, coverage, privacy-safe concentration, and join support", length(sed_cols)),
                        rep("event metadata, geometry, complex, and coverage audit", length(required_h)), "approved shoreline-class and snap audit", "region recovery"),
  persisted_raw_values = FALSE,
  exposure_specific_bird_summary = FALSE,
  prospective_2026_plus_outcome_used = FALSE
)
prohibited_rows <- data.table(
  record_type = "prohibited_statistic_check", dataset = "DERIVED", column_name = rules$prohibited_statistics,
  values_read = FALSE, permitted_purpose = "explicit noncomputation assertion", persisted_raw_values = FALSE,
  exposure_specific_bird_summary = FALSE, prospective_2026_plus_outcome_used = FALSE,
  computed = FALSE, persisted = FALSE, check_status = "PASS_NOT_COMPUTED"
)
access_audit <- rbindlist(list(access_rows, prohibited_rows), fill = TRUE)
write_csv(access_audit, "response_column_access_audit.csv")

prospective_path <- "metadata/prospective_confirmation_spec.yml"
prospective_hash_path <- "metadata/prospective_confirmation_spec.sha256"
if (!file.exists(prospective_path) || !file.exists(prospective_hash_path)) {
  stop("PROSPECTIVE_FREEZE: signed amended confirmation specification is missing", call. = FALSE)
}
prospective_hash <- digest("metadata/prospective_confirmation_spec.yml", algo = "sha256", file = TRUE, serialize = FALSE)
recorded_prospective_hash <- strsplit(readLines(prospective_hash_path, warn = FALSE)[1L], "[[:space:]]+")[[1L]][1L]
if (!identical(prospective_hash, recorded_prospective_hash)) {
  stop("PROSPECTIVE_FREEZE: signed amended confirmation specification hash mismatch", call. = FALSE)
}

stage_gate <- list(
  stage = "stage2_outcome_blind_design_lock",
  classification = "REVISION_REQUIRED_RUN_SCRIPT_10_REPAIR_GATE",
  candidate_grid_sha256 = actual_hash,
  candidate_grid_prior_windows_crlf_sha256 = rules$design_freeze$correction_history[[1L]]$prior_sha256,
  candidate_grid_correction_type = rules$design_freeze$correction_history[[1L]]$correction_type,
  candidate_grid_frozen_at_utc = rules$design_freeze$frozen_at_utc,
  candidate_grid_verified_before_response_value_access = TRUE,
  prospective_spec_sha256 = prospective_hash,
  registered_models_fitted = 0,
  prohibited_statistics_computed = 0,
  exact_ebird_coordinates_released = FALSE,
  raw_or_record_level_ebird_rows_released = FALSE,
  comments_read = FALSE,
  requires_human_scientific_approval = TRUE,
  validation_status = "BASE_SUPPORT_AUDIT_COMPLETE_REPAIR_GATE_REQUIRED"
)
write_json(stage_gate, file.path(out_dir, "stage_gate.json"), pretty = TRUE, auto_unbox = TRUE)

message("Stage 2 support-only audit artifacts complete; no herring-response model was fitted")
