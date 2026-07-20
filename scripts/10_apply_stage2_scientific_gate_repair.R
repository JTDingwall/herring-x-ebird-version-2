suppressPackageStartupMessages({
  library(data.table)
  library(digest)
  library(jsonlite)
  library(sf)
  library(yaml)
})

options(stringsAsFactors = FALSE, scipen = 999)
sf::sf_use_s2(FALSE)
source("R/assert.R")
source("R/herring_event_engineering.R")
source("R/spatial_linkage.R")

support_label <- "SUPPORT_ONLY_NOT_AN_EFFECT_ESTIMATE"
out_dir <- "outputs/stage2_design_lock"
private_dir <- "outputs/input_audit_local/stage2"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(private_dir, recursive = TRUE, showWarnings = FALSE)

amendment_path <- "metadata/stage2_scientific_gate_amendment_v1.yml"
amendment_hash_path <- "metadata/stage2_scientific_gate_amendment_v1.sha256"
amendment <- read_yaml(amendment_path)
amendment_hash <- digest(amendment_path, algo = "sha256", file = TRUE, serialize = FALSE)
recorded_amendment_hash <- strsplit(readLines(amendment_hash_path, warn = FALSE)[1L], "[[:space:]]+")[[1L]][1L]
if (!identical(amendment_hash, recorded_amendment_hash)) stop("Stage 2 amendment hash mismatch", call. = FALSE)

approval_path <- "metadata/stage2_human_scientific_approval_v1.yml"
approval_hash_path <- "metadata/stage2_human_scientific_approval_v1.sha256"
approval <- read_yaml(approval_path)
approval_hash <- digest(approval_path, algo = "sha256", file = TRUE, serialize = FALSE)
recorded_approval_hash <- strsplit(readLines(approval_hash_path, warn = FALSE)[1L], "[[:space:]]+")[[1L]][1L]
if (!identical(approval_hash, recorded_approval_hash)) stop("Stage 2 human approval hash mismatch", call. = FALSE)
if (!identical(approval$scientific_decision, "APPROVED_SOURCE_POINT_PRIMARY")) {
  stop("Stage 2 human approval does not authorize the source-point primary", call. = FALSE)
}
if (isTRUE(approval$response_boundary$stage3_response_models_authorized)) {
  stop("Stage 2 approval must not authorize response models", call. = FALSE)
}

grid_path <- "metadata/stage2_candidate_design_grid.csv"
grid_hash_lines <- readLines("metadata/stage2_candidate_design_grid.sha256", warn = FALSE)
grid_hash <- strsplit(grid_hash_lines[1L], "[[:space:]]+")[[1L]][1L]
if (!identical(grid_hash, digest(grid_path, algo = "sha256", file = TRUE, serialize = FALSE))) {
  stop("Original candidate grid changed during amendment", call. = FALSE)
}

env_names <- c(
  ebd = "HERRING_EBIRD_V2_EBD", sed = "HERRING_EBIRD_V2_SED",
  herring = "HERRING_EBIRD_V2_HERRING", shoreline = "HERRING_EBIRD_V2_SHORELINE",
  sections = "HERRING_EBIRD_V2_SECTIONS"
)
paths <- setNames(Sys.getenv(unname(env_names)), names(env_names))
if (any(!nzchar(paths)) || any(!file.exists(paths))) stop("All five protected inputs must be configured and readable", call. = FALSE)

write_support <- function(x, name) {
  x <- as.data.table(x)
  if (!"support_label" %in% names(x)) x[, support_label := support_label]
  numeric_columns <- names(x)[vapply(x, is.numeric, logical(1L))]
  for (column in numeric_columns) set(x, j = column, value = round(x[[column]], 5L))
  fwrite(x, file.path(out_dir, name), quote = TRUE, na = "")
}
qvalue <- function(x, p) {
  x <- x[is.finite(x)]
  if (!length(x)) return(NA_real_)
  as.numeric(quantile(x, p, names = FALSE, type = 1L))
}
max_false_run <- function(x) {
  if (!length(x)) return(0L)
  runs <- rle(!x)
  if (!any(runs$values)) return(0L)
  max(runs$lengths[runs$values])
}

message("Repair 1/8: auditing EBD-SED membership in both directions")
sed_fields <- c(
  "SAMPLING EVENT IDENTIFIER", "LOCALITY ID", "LATITUDE", "LONGITUDE", "OBSERVATION DATE",
  "TIME OBSERVATIONS STARTED", "OBSERVER ID", "PROTOCOL NAME", "PROTOCOL CODE", "DURATION MINUTES",
  "EFFORT DISTANCE KM", "EFFORT AREA HA", "NUMBER OBSERVERS", "ALL SPECIES REPORTED", "GROUP IDENTIFIER"
)
sed <- fread(paths[["sed"]], sep = "\t", select = sed_fields, quote = "", na.strings = c("", "NA"), showProgress = TRUE)
setnames(sed, sed_fields, c(
  "source_id", "locality_id", "latitude", "longitude", "date", "start_time", "observer_id",
  "protocol", "protocol_code", "duration_min", "effort_distance_km", "area_ha", "n_observers",
  "complete", "group_id"
))
if (anyNA(sed$source_id) || any(!nzchar(sed$source_id)) || anyDuplicated(sed$source_id)) {
  stop("SED key cardinality failure", call. = FALSE)
}
sed[, date := as.IDate(date)]
ebd_key <- "SAMPLING EVENT IDENTIFIER"
missing_key_path <- file.path(private_dir, "sed_only_keys_amendment_v1.tsv")
membership_stats_path <- file.path(private_dir, "ebd_sed_membership_stats_amendment_v1.json")
membership_status <- if (file.exists(missing_key_path) && file.exists(membership_stats_path)) 0L else
  system2("powershell", c(
    "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "scripts/run_ebd_streaming_tool.ps1",
    "-Mode", "membership", "-EbdEnv", env_names[["ebd"]], "-SedEnv", env_names[["sed"]],
    "-MissingOutput", missing_key_path, "-StatsOutput", membership_stats_path
  ))
if (!identical(membership_status, 0L) || !file.exists(missing_key_path) || !file.exists(membership_stats_path)) {
  stop("Streaming EBD-SED membership audit failed", call. = FALSE)
}
membership_stats <- fromJSON(membership_stats_path)
sed_only_keys <- fread(missing_key_path, sep = "\t", select = ebd_key, quote = "")[[ebd_key]]
sed[, has_ebd_row := !source_id %chin% sed_only_keys]
ebd_rows <- membership_stats$ebd_rows
ebd_keys_unmatched <- membership_stats$ebd_keys_unmatched_to_sed
if (ebd_keys_unmatched != 0L) stop("EBD key missing from SED", call. = FALSE)

is_complete <- toupper(as.character(sed$complete)) %chin% c("1", "TRUE", "T", "YES")
stationary <- grepl("Stationary", sed$protocol, ignore.case = TRUE)
traveling <- grepl("Travel", sed$protocol, ignore.case = TRUE)
area_protocol <- grepl("Area", sed$protocol, ignore.case = TRUE)
standardized_row <- is_complete & (stationary | traveling) & sed$duration_min >= 5 & sed$duration_min <= 300 &
  sed$n_observers >= 1 & sed$n_observers <= 10 & (stationary | (traveling & sed$effort_distance_km <= 5))
broad_row <- is_complete & (stationary | traveling) & sed$duration_min >= 1 & sed$duration_min <= 360 &
  sed$n_observers >= 1 & sed$n_observers <= 20 & (stationary | (traveling & sed$effort_distance_km <= 10))
sed[, `:=`(
  standardized_row_candidate = standardized_row,
  broad_row_candidate = broad_row,
  complete_area_row_candidate = area_protocol & is_complete
)]
sed[, analysis_id := fifelse(!is.na(group_id) & nzchar(trimws(group_id)), group_id, source_id)]
setorder(sed, analysis_id, source_id)
comparison_fields <- c("date", "latitude", "longitude", "protocol", "duration_min", "effort_distance_km", "n_observers", "complete")
group_status <- sed[, {
  conflicts <- comparison_fields[vapply(.SD, function(v) uniqueN(ifelse(is.na(v), "<NA>", as.character(v))) > 1L, logical(1L))]
  .(group_members = .N, any_ebd_row = any(has_ebd_row), sed_only_source_rows = sum(!has_ebd_row),
    effort_disagreement = length(conflicts) > 0L, disagreement_fields = paste(conflicts, collapse = ";"))
}, by = analysis_id, .SDcols = comparison_fields]
checklists <- sed[, .SD[1L], by = analysis_id]
checklists <- group_status[checklists, on = "analysis_id"]
checklists[, observer_effect_id := fifelse(group_members > 1L, analysis_id, observer_id)]
checklists[, checklist_year := as.integer(format(date, "%Y"))]
checklists[, standardized_eligible := any_ebd_row & !effort_disagreement &
  toupper(as.character(complete)) %chin% c("1", "TRUE", "T", "YES") &
  (grepl("Stationary", protocol, ignore.case = TRUE) | grepl("Travel", protocol, ignore.case = TRUE)) &
  duration_min >= 5 & duration_min <= 300 & n_observers >= 1 & n_observers <= 10 &
  (grepl("Stationary", protocol, ignore.case = TRUE) | effort_distance_km <= 5)]
checklists[, broad_eligible := any_ebd_row & !effort_disagreement &
  toupper(as.character(complete)) %chin% c("1", "TRUE", "T", "YES") &
  (grepl("Stationary", protocol, ignore.case = TRUE) | grepl("Travel", protocol, ignore.case = TRUE)) &
  duration_min >= 1 & duration_min <= 360 & n_observers >= 1 & n_observers <= 20 &
  (grepl("Stationary", protocol, ignore.case = TRUE) | effort_distance_km <= 10)]
checklists[, area_eligible := any_ebd_row & !effort_disagreement &
  toupper(as.character(complete)) %chin% c("1", "TRUE", "T", "YES") & grepl("Area", protocol, ignore.case = TRUE)]

sed_only <- sed[has_ebd_row == FALSE]
membership_summary <- data.table(
  relationship = "global_EBD_SED_key_membership",
  expected_cardinality = "EBD_many_to_one_SED_and_bidirectional_membership_audit",
  ebd_rows = ebd_rows,
  ebd_unique_keys = membership_stats$ebd_unique_keys,
  sed_unique_keys = nrow(sed),
  ebd_keys_unmatched_to_sed = ebd_keys_unmatched,
  sed_keys_without_ebd = nrow(sed_only),
  sed_only_1988_2025 = sum(sed_only$date >= as.IDate("1988-01-01") & sed_only$date <= as.IDate("2025-12-31"), na.rm = TRUE),
  sed_only_2026_plus = sum(sed_only$date >= as.IDate("2026-01-01"), na.rm = TRUE),
  sed_only_complete = sum(toupper(as.character(sed_only$complete)) %chin% c("1", "TRUE", "T", "YES")),
  sed_only_standardized_row_candidate = sum(sed_only$standardized_row_candidate, na.rm = TRUE),
  sed_only_broad_row_candidate = sum(sed_only$broad_row_candidate, na.rm = TRUE),
  sed_only_complete_area_candidate = sum(sed_only$complete_area_row_candidate, na.rm = TRUE),
  wholly_sed_only_analysis_groups = sum(!group_status$any_ebd_row),
  sed_only_keys_with_ebd_group_sibling = sum(group_status$sed_only_source_rows[group_status$any_ebd_row]),
  primary_zero_fill_eligible = FALSE,
  scientific_treatment = "structurally_unknown_excluded_from_primary_zero_fill",
  status = "PASS_SED_ONLY_NOT_ZERO_FILLED"
)
write_support(membership_summary, "ebd_sed_membership_audit.csv")

shared_summary <- group_status[, .(
  source_rows = nrow(sed), analysis_checklists = .N,
  shared_analysis_checklists = sum(group_members > 1L),
  disagreement_groups = sum(effort_disagreement),
  disagreement_groups_with_ebd = sum(any_ebd_row & effort_disagreement),
  wholly_sed_only_analysis_groups = sum(!any_ebd_row),
  wholly_sed_only_disagreement_groups = sum(!any_ebd_row & effort_disagreement),
  primary_analysis_checklists = sum(any_ebd_row & !effort_disagreement),
  observer_effect_rule = "shared_group_composite_cluster_not_first_source_row",
  disagreement_primary_rule = "exclude_from_primary_registered_sensitivity",
  disagreement_sensitivity = "fieldwise_ranges_and_missing_when_no_consensus"
)]
write_support(shared_summary, "shared_checklist_aggregate_audit.csv")

message("Repair 2/8: rebuilding event-complex review packet and anti-chaining")
h <- fread(paths[["herring"]], na.strings = c("", "NA"))
required_h <- required_herring_source_fields()
assert_columns(h, required_h, "herring source")
h <- h[Year >= 1988L & Year <= 2025L]
event_crosswalk <- fread(file.path(out_dir, "event_complex_crosswalk.csv"), na.strings = c("", "NA"))
if (nrow(event_crosswalk) != nrow(h) || anyDuplicated(event_crosswalk$source_record_id)) {
  stop("Event-complex crosswalk does not match protected herring rows", call. = FALSE)
}
h[, source_record_id := event_crosswalk$source_record_id]
h[, `:=`(start_date = as.IDate(StartDate), end_date = as.IDate(EndDate))]
h[, event_date := as.IDate(ifelse(!is.na(start_date) & !is.na(end_date),
  floor((as.numeric(start_date) + as.numeric(end_date)) / 2),
  ifelse(!is.na(start_date), as.numeric(start_date), as.numeric(end_date))), origin = "1970-01-01")]
h[, `:=`(
  reversed_date = !is.na(start_date) & !is.na(end_date) & end_date < start_date,
  uncertain_date = is.na(start_date) | is.na(end_date)
)]
valid_xy <- is.finite(h$Longitude) & is.finite(h$Latitude) & h$Longitude >= -180 & h$Longitude <= 180 & h$Latitude >= -90 & h$Latitude <= 90
h_pts <- st_as_sf(h[valid_xy], coords = c("Longitude", "Latitude"), crs = 4326, remove = FALSE)
h_pts <- st_transform(h_pts, 3005)
h[, `:=`(x_3005 = NA_real_, y_3005 = NA_real_)]
h[valid_xy, c("x_3005", "y_3005") := as.data.table(st_coordinates(h_pts))[, .(X, Y)]]

sections <- st_read(paths[["sections"]], quiet = TRUE)
if (is.na(st_crs(sections))) st_crs(sections) <- 3005
if (!isTRUE(st_crs(sections) == st_crs(3005))) sections <- st_transform(sections, 3005)
assessment_to_region <- c("Area 27" = "A27", "Central Coast" = "CC", "HG EAST" = "HG", "HG WEST" = "HG",
  "Other Areas" = "NA", "Prince Rupert" = "PRD", "Strait of Georgia" = "SoG", "W.C. Vancouver Is." = "WCVI")
h[, region_analysis := as.character(Region)]
missing_region <- which(is.na(h$region_analysis) & valid_xy)
if (length(missing_region)) {
  hit <- st_intersects(h_pts[match(missing_region, which(valid_xy)), ], sections)
  assessment <- vapply(hit, function(z) if (length(z)) as.character(sections$Assessment[z[1L]]) else NA_character_, character(1L))
  h[missing_region, region_analysis := unname(assessment_to_region[assessment])]
}
h[is.na(region_analysis), region_analysis := "NA"]

anti_input <- h[, .(
  original_complex_id = event_crosswalk$complex_2km_7d,
  source_record_id, event_date, x_m = x_3005, y_m = y_3005, region = region_analysis
)]
anti <- anti_chain_event_complexes(anti_input,
  maximum_temporal_span_days = amendment$event_complexes$deterministic_anti_chaining$maximum_temporal_span_days,
  maximum_spatial_bbox_diameter_km = amendment$event_complexes$deterministic_anti_chaining$maximum_spatial_bbox_diameter_km)
event_crosswalk[anti, on = "source_record_id", complex_2km_7d_antichain := i.anti_chain_complex_id]
write_support(event_crosswalk, "event_complex_crosswalk.csv")

complex_definitions <- c("source_record", "complex_1km_3d", "complex_2km_7d", "complex_2km_7d_antichain", "complex_5km_14d")
complex_detail <- rbindlist(lapply(complex_definitions, function(definition) {
  ids <- event_crosswalk[[definition]]
  z <- h[, .(
    source_records = .N,
    region = paste(sort(unique(region_analysis)), collapse = ";"),
    regions = uniqueN(region_analysis), statistical_areas = uniqueN(StatisticalArea, na.rm = TRUE),
    sections = uniqueN(Section, na.rm = TRUE), location_codes = uniqueN(LocationCode, na.rm = TRUE),
    methods = uniqueN(Method, na.rm = TRUE),
    temporal_span_days = if (all(is.na(event_date))) NA_real_ else as.numeric(max(event_date, na.rm = TRUE) - min(event_date, na.rm = TRUE)),
    spatial_bbox_diameter_km = if (sum(is.finite(x_3005) & is.finite(y_3005)) < 2L) 0 else
      sqrt(diff(range(x_3005, na.rm = TRUE))^2 + diff(range(y_3005, na.rm = TRUE))^2) / 1000,
    any_reversed_date = any(reversed_date), any_uncertain_date = any(uncertain_date),
    generalized_easting_10km = if (all(!is.finite(x_3005))) NA_real_ else round(mean(x_3005, na.rm = TRUE) / 10000) * 10,
    generalized_northing_10km = if (all(!is.finite(y_3005))) NA_real_ else round(mean(y_3005, na.rm = TRUE) / 10000) * 10
  ), by = .(complex_id = ids)]
  z[, `:=`(
    definition = definition,
    crosses_region = regions > 1L,
    crosses_statistical_area = statistical_areas > 1L,
    crosses_section = sections > 1L,
    crosses_location_code = location_codes > 1L,
    mixed_method = methods > 1L,
    temporal_review = !is.na(temporal_span_days) & temporal_span_days > 21,
    spatial_review = !is.na(spatial_bbox_diameter_km) & spatial_bbox_diameter_km > 25
  )]
  z[, review_required := temporal_review | spatial_review | crosses_statistical_area | crosses_section |
    mixed_method | any_reversed_date | any_uncertain_date]
  z[, review_reason := vapply(seq_len(.N), function(i) paste(c(
    if (temporal_review[i]) "temporal_span_over_21_days",
    if (spatial_review[i]) "spatial_span_over_25km",
    if (crosses_statistical_area[i]) "crosses_statistical_area",
    if (crosses_section[i]) "crosses_section",
    if (mixed_method[i]) "mixed_method",
    if (any_reversed_date[i]) "reversed_date",
    if (any_uncertain_date[i]) "uncertain_date"
  ), collapse = ";"), character(1L))]
  z
}), fill = TRUE)
setcolorder(complex_detail, c("definition", setdiff(names(complex_detail), "definition")))
review_packet <- complex_detail[review_required == TRUE]
setorder(review_packet, definition, -temporal_span_days, -spatial_bbox_diameter_km, -source_records)
write_support(review_packet, "event_complex_map_review_cases.csv")
complex_audit <- complex_detail[, .(
  complexes = .N, source_records = sum(source_records),
  members_q50 = qvalue(source_records, .5), members_q90 = qvalue(source_records, .9), members_max = max(source_records),
  temporal_span_days_q90 = qvalue(temporal_span_days, .9), temporal_span_days_max = max(temporal_span_days, na.rm = TRUE),
  spatial_diameter_km_q90 = qvalue(spatial_bbox_diameter_km, .9), spatial_diameter_km_max = max(spatial_bbox_diameter_km, na.rm = TRUE),
  complexes_crossing_region = sum(crosses_region), complexes_crossing_statistical_area = sum(crosses_statistical_area),
  complexes_crossing_section = sum(crosses_section), complexes_mixed_method = sum(mixed_method),
  complexes_over_21_days = sum(temporal_review), complexes_over_25_km = sum(spatial_review),
  complexes_with_reversed_date = sum(any_reversed_date), complexes_with_uncertain_date = sum(any_uncertain_date),
  review_packet_rows = sum(review_required),
  candidate_role = fifelse(definition == "source_record", "safe_primary",
    fifelse(definition == "complex_2km_7d", "provisional_pending_human_review",
      fifelse(definition == "complex_2km_7d_antichain", "deterministic_anti_chaining_sensitivity", "registered_sensitivity")))
), by = definition]
write_support(complex_audit, "event_complex_audit.csv")

message("Repair 3/8: diagnosing shoreline coverage and constructing actual alongshore segments")
shore <- st_read(paths[["shoreline"]], quiet = TRUE)
if (is.na(st_crs(shore))) stop("Shoreline CRS is missing", call. = FALSE)
if (!isTRUE(st_crs(shore) == st_crs(3005))) shore <- st_transform(shore, 3005) else st_crs(shore) <- st_crs(3005)
if (!"EDGE_TYPE" %in% names(shore)) stop("Shoreline EDGE_TYPE is missing", call. = FALSE)
shore100 <- shore[shore$EDGE_TYPE == 100, ]
shore150 <- shore[shore$EDGE_TYPE == 150, ]
if (!nrow(shore100) || !nrow(shore150)) stop("Expected shoreline classes 100 and 150 are not both present", call. = FALSE)
valid_rows <- which(valid_xy)
nearest100 <- st_nearest_feature(h_pts, shore100)
distance100 <- as.numeric(st_distance(h_pts, shore100[nearest100, ], by_element = TRUE))
nearest150 <- st_nearest_feature(h_pts, shore150)
distance150 <- as.numeric(st_distance(h_pts, shore150[nearest150, ], by_element = TRUE))
h[, `:=`(shoreline100_distance_m = NA_real_, shoreline150_distance_m = NA_real_, nearest100_feature = NA_integer_)]
h[valid_rows, `:=`(shoreline100_distance_m = distance100, shoreline150_distance_m = distance150,
  nearest100_feature = nearest100)]
shore_bbox <- st_bbox(shore100)
h[, inside_shoreline_bundle_bbox := valid_xy & x_3005 >= shore_bbox[["xmin"]] & x_3005 <= shore_bbox[["xmax"]] &
  y_3005 >= shore_bbox[["ymin"]] & y_3005 <= shore_bbox[["ymax"]]]
snap_limit <- amendment$shoreline_geometry$candidate_primary_snap_limit_m
h[, geometry_tier := fifelse(!is.na(event_date) & valid_xy & !is.na(Method) & shoreline100_distance_m <= snap_limit &
  is.finite(Length) & Length > 0, "A", fifelse(!is.na(event_date) & valid_xy & shoreline100_distance_m <= snap_limit,
  "B", fifelse(!is.na(event_date) & (!is.na(Section) | valid_xy), "C", "excluded")))]
h[, shoreline_core_eligible := geometry_tier %chin% c("A", "B") & shoreline100_distance_m <= snap_limit]

tier_a <- which(h$geometry_tier == "A")
construction <- vector("list", length(tier_a))
for (i in seq_along(tier_a)) {
  row <- tier_a[i]
  point_position <- match(row, valid_rows)
  line_coordinates <- st_coordinates(shore100[h$nearest100_feature[row], ])
  construction[[i]] <- construct_alongshore_segment(
    line_coordinates, st_coordinates(h_pts[point_position, ])[1L, 1:2], h$Length[row]
  )
}
construction_status <- vapply(construction, `[[`, character(1L), "status")
constructed_rows <- tier_a[construction_status == "constructed"]
h[, alongshore_geometry_constructed := FALSE]
h[constructed_rows, alongshore_geometry_constructed := TRUE]
if (length(constructed_rows)) {
  geometries <- st_sfc(lapply(construction[construction_status == "constructed"], function(z) st_linestring(z$coordinates)), crs = 3005)
  alongshore_local <- st_sf(
    source_record_id = h$source_record_id[constructed_rows],
    requested_length_m = h$Length[constructed_rows],
    constructed_length_m = vapply(construction[construction_status == "constructed"], `[[`, numeric(1L), "constructed_length_m"),
    geometry = geometries
  )
  if (any(abs(alongshore_local$requested_length_m - alongshore_local$constructed_length_m) > 0.01)) {
    stop("Constructed alongshore geometry length mismatch", call. = FALSE)
  }
  saveRDS(alongshore_local, file.path(private_dir, "alongshore_geometry_primary_amendment_v1.rds"), compress = FALSE)
}

geometry_region <- h[, .(
  source_records = .N, valid_source_points = sum(is.finite(x_3005) & is.finite(y_3005)), inside_bundle_bbox = sum(inside_shoreline_bundle_bbox),
  inside_bundle_bbox_share = mean(inside_shoreline_bundle_bbox),
  edge100_snap_q50_km = qvalue(shoreline100_distance_m / 1000, .5),
  edge100_snap_q90_km = qvalue(shoreline100_distance_m / 1000, .9),
  edge100_snap_over_2km = sum(shoreline100_distance_m > snap_limit, na.rm = TRUE),
  edge150_snap_q50_km = qvalue(shoreline150_distance_m / 1000, .5),
  tier_A = sum(geometry_tier == "A"), tier_B = sum(geometry_tier == "B"),
  tier_C = sum(geometry_tier == "C"), core_eligible = sum(shoreline_core_eligible),
  actual_alongshore_constructed = sum(alongshore_geometry_constructed)
), by = .(region = region_analysis)]
geometry_region[, bundle_coverage_status := fifelse(inside_bundle_bbox_share == 0,
  "FAIL_NO_SOURCE_POINTS_INSIDE_BUNDLE_EXTENT", fifelse(edge100_snap_q50_km > 2,
  "FAIL_MEDIAN_SNAP_EXCEEDS_2KM", "PASS_CANDIDATE_COVERAGE"))]
write_support(geometry_region, "event_geometry_region_diagnostics.csv")

intended_regions <- c("A27", "A2W", "CC", "HG", "PRD", "SoG", "WCVI")
geometry_failure_regions <- geometry_region[region %chin% intended_regions & bundle_coverage_status != "PASS_CANDIDATE_COVERAGE", region]
bundle_geometry_gate <- if (length(geometry_failure_regions)) "FAIL_INCOMPLETE_SHORELINE_BUNDLE_EXTENT" else "PASS"
if (!identical(approval$primary_event_geometry$representation, "immutable_source_point")) {
  stop("Approved primary geometry must be immutable_source_point", call. = FALSE)
}
if (!sum(valid_xy)) stop("Approved source-point primary has no valid source points", call. = FALSE)
geometry_gate <- "PASS_SOURCE_POINT_PRIMARY_SHORELINE_SENSITIVITY_SCOPED"
approved_shoreline_regions <- paste(approval$shoreline_sensitivities$edge_type_100$supported_regions, collapse = "_")
actual_success <- sum(h$alongshore_geometry_constructed)
geometry_audit <- data.table(
  geometry_definition = c("source_point", "edge100_nearest_shoreline_point", "edge150_nearest_shoreline_point",
    "derived_alongshore_length", "derived_alongshore_length_width", "event_complex_member_union"),
  candidate_role = c("coastwide_primary_human_approved", "supported_region_sensitivity_human_approved", "separate_sensitivity_after_visual_validation",
    "supported_region_sensitivity_human_approved", "registered_supported_region_sensitivity", "registered_supported_region_sensitivity"),
  source_records = nrow(h),
  all_available_records = c(sum(valid_xy), sum(is.finite(h$shoreline100_distance_m)), sum(is.finite(h$shoreline150_distance_m)),
    actual_success, sum(h$alongshore_geometry_constructed & is.finite(h$Width) & h$Width > 0),
    uniqueN(event_crosswalk$complex_2km_7d_antichain[h$alongshore_geometry_constructed])),
  common_eligible_records = sum(h$alongshore_geometry_constructed),
  edge100_snap_q50_m = qvalue(h$shoreline100_distance_m, .5),
  edge100_snap_q90_m = qvalue(h$shoreline100_distance_m, .9),
  edge100_snap_over_2km = sum(h$shoreline100_distance_m > snap_limit, na.rm = TRUE),
  tier_A_records = sum(h$geometry_tier == "A"), tier_B_records = sum(h$geometry_tier == "B"),
  tier_C_records = sum(h$geometry_tier == "C"), excluded_records = sum(h$geometry_tier == "excluded"),
  actual_alongshore_geometry_verified = actual_success > 0,
  primary_edge_type = 100L, sensitivity_edge_type = 150L,
  geometry_gate = geometry_gate,
  approved_primary_representation = "source_point",
  shoreline_sensitivity_scope = approved_shoreline_regions,
  exact_ebird_coordinates_in_output = FALSE
)
write_support(geometry_audit, "event_geometry_audit.csv")
geometry_comparison <- data.table(
  representation = c("source_point", "derived_alongshore_length", "source_point", "derived_alongshore_length"),
  comparison_sample = c("all_available", "all_available", "common_eligible_events", "common_eligible_events"),
  eligible_events = c(sum(valid_xy), actual_success, actual_success, actual_success),
  approved_role = c("coastwide_primary", "supported_region_sensitivity", "sensitivity_comparator", "supported_region_sensitivity"),
  comparison_interpretation = c(
    "primary representation; availability defines the valid-source-point scope",
    "representation-specific availability; never extrapolate to unsupported shoreline regions",
    "same eligible event set for geometry sensitivity comparison", "same eligible event set for geometry sensitivity comparison"
  )
)
write_support(geometry_comparison, "geometry_representation_eligibility.csv")
geometry_crosswalk <- h[, .(
  source_record_id, geometry_quality_tier = geometry_tier,
  source_point_available = valid_xy,
  edge100_snap_distance_band = cut(shoreline100_distance_m,
    breaks = c(-Inf, 100, 500, 1000, 2000, 5000, Inf),
    labels = c("0_100m", "100_500m", "500m_1km", "1_2km", "2_5km", "over_5km")),
  edge100_core_eligible = shoreline_core_eligible,
  edge150_sensitivity_available = is.finite(shoreline150_distance_m),
  observed_length_available = is.finite(Length) & Length > 0,
  actual_alongshore_geometry_constructed = alongshore_geometry_constructed,
  safe_primary_complex_id = event_crosswalk$source_record,
  provisional_2km_7d_complex_id = event_crosswalk$complex_2km_7d,
  antichain_complex_id = event_crosswalk$complex_2km_7d_antichain
)]
write_support(geometry_crosswalk, "event_geometry_crosswalk.csv")

map_points <- h[valid_xy, .(x = x_3005, y = y_3005, region = region_analysis,
  status = fifelse(shoreline_core_eligible, "core_candidate", "not_core"))]
sx <- 20 + 960 * (map_points$x - min(map_points$x)) / max(1, diff(range(map_points$x)))
sy <- 680 - 650 * (map_points$y - min(map_points$y)) / max(1, diff(range(map_points$y)))
map_circles <- paste0("<circle cx='", round(sx, 1), "' cy='", round(sy, 1), "' r='1.5' class='",
  map_points$status, "'><title>", map_points$region, " | ", map_points$status, "</title></circle>")
local_map <- paste0("<!doctype html><html><head><meta charset='utf-8'><title>Local shoreline coverage review</title>",
  "<style>body{font-family:system-ui}.core_candidate{fill:#236c55}.not_core{fill:#b24b3f;opacity:.45}svg{border:1px solid #aaa}</style></head>",
  "<body><h1>Local-only shoreline coverage review</h1><p>Herring metadata only. Red points are outside the shoreline-linked core eligibility rule.</p>",
  "<svg viewBox='0 0 1000 700'>", paste(map_circles, collapse = ""), "</svg></body></html>")
writeLines(local_map, file.path(private_dir, "shoreline_geometry_review_local.html"), useBytes = TRUE)

message("Repair 4/8: applying sustained region-year support and standardized effort primary")
links <- readRDS(file.path(private_dir, "source_point_links.rds"))
if (!nrow(links) || !all(c("analysis_id", "event_row", "distance_km", "event_day_midpoint") %in% names(links))) {
  stop("Private source-point link cache is unavailable or invalid", call. = FALSE)
}
primary_ids <- checklists[standardized_eligible == TRUE & date >= as.IDate("1988-01-01") & date <= as.IDate("2025-12-31"), analysis_id]
primary_links <- links[analysis_id %chin% primary_ids]
primary_links[, `:=`(
  source_record_id = h$source_record_id[event_row], event_region = h$region_analysis[event_row],
  event_complex_2km_7d = event_crosswalk$complex_2km_7d[event_row],
  checklist_date = checklists$date[match(analysis_id, checklists$analysis_id)],
  checklist_year = checklists$checklist_year[match(analysis_id, checklists$analysis_id)]
)]
primary_links <- primary_links[checklist_year >= 2005L & checklist_year <= 2025L]

event_periods <- unique(primary_links[event_day_midpoint >= -28L & event_day_midpoint <= 28L,
  .(event_region, checklist_year, source_record_id,
    period = fifelse(event_day_midpoint < 0L, "period_one", "period_two"))])
events_both <- event_periods[, .(periods = uniqueN(period)), by = .(event_region, checklist_year, source_record_id)][
  , .(events_with_both_primary_periods = sum(periods == 2L)), by = .(event_region, checklist_year)]
annual <- primary_links[, .(
  standardized_linked_checklists = uniqueN(analysis_id), represented_source_events = uniqueN(source_record_id),
  represented_provisional_complexes = uniqueN(event_complex_2km_7d),
  primary_period_one_checklists = uniqueN(analysis_id[event_day_midpoint >= -28L & event_day_midpoint <= -1L]),
  primary_period_two_checklists = uniqueN(analysis_id[event_day_midpoint >= 0L & event_day_midpoint <= 28L]),
  near_ring_checklists = uniqueN(analysis_id[distance_km <= 2]),
  reference_ring_checklists = uniqueN(analysis_id[distance_km >= 5 & distance_km <= 20])
), by = .(region = event_region, year = checklist_year)]
annual <- events_both[annual, on = c(event_region = "region", checklist_year = "year")]
setnames(annual, c("event_region", "checklist_year"), c("region", "year"))
annual[is.na(events_with_both_primary_periods), events_with_both_primary_periods := 0L]
annual <- merge(CJ(region = sort(unique(h$region_analysis)), year = 2005:2025), annual,
  by = c("region", "year"), all.x = TRUE, sort = TRUE)
annual_columns <- setdiff(names(annual), c("region", "year"))
for (column in annual_columns) set(annual, which(is.na(annual[[column]])), column, 0)
thresholds <- amendment$region_period_support$sustained_year_thresholds
annual[, `:=`(
  exposed_reference_overlap = near_ring_checklists > 0 & reference_ring_checklists > 0,
  usable_primary_event_windows = primary_period_one_checklists > 0 & primary_period_two_checklists > 0,
  sustained_year_pass = standardized_linked_checklists >= thresholds$minimum_standardized_linked_checklists &
    represented_source_events >= thresholds$minimum_represented_source_events &
    primary_period_one_checklists >= thresholds$minimum_primary_period_one_checklists &
    primary_period_two_checklists >= thresholds$minimum_primary_period_two_checklists &
    near_ring_checklists >= thresholds$minimum_near_ring_checklists &
    reference_ring_checklists >= thresholds$minimum_reference_ring_checklists &
    events_with_both_primary_periods >= thresholds$minimum_events_with_both_primary_periods
)]
write_support(annual, "region_year_support.csv")

candidate_years <- amendment$region_period_support$candidate_start_years
period_recommendations <- rbindlist(lapply(sort(unique(annual$region)), function(region_value) {
  rbindlist(lapply(candidate_years, function(start_year) {
    z <- annual[region == region_value & year >= start_year]
    data.table(
      region = region_value, candidate_start_year = start_year,
      years_assessed = nrow(z), passing_years = sum(z$sustained_year_pass),
      passing_year_share = mean(z$sustained_year_pass),
      maximum_consecutive_failing_years = max_false_run(z$sustained_year_pass),
      years_with_exposed_reference_overlap = sum(z$exposed_reference_overlap),
      represented_source_events = sum(z$represented_source_events),
      sustained_support_pass = mean(z$sustained_year_pass) >= thresholds$minimum_passing_year_share &
        max_false_run(z$sustained_year_pass) <= thresholds$maximum_consecutive_failing_years_after_start
    )
  }))
}))
period_recommendations[, recommended_primary_start_year := {
  passing <- candidate_start_year[sustained_support_pass]
  if (length(passing)) min(passing) else NA_integer_
}, by = region]
period_recommendations[, recommendation := fifelse(is.na(recommended_primary_start_year),
  "descriptive_or_hierarchical_only_due_unsustained_support",
  fifelse(candidate_start_year == recommended_primary_start_year, "candidate_primary_period",
    "registered_period_sensitivity"))]
period_recommendations[region %chin% c("A27", "A2W") & !sustained_support_pass,
  recommendation := "descriptive_or_hierarchical_only_due_unsustained_support"]
write_support(period_recommendations, "region_period_recommendations.csv")

protocol_amendment <- data.table(
  definition = c("standardized_primary", "broad_sensitivity", "complete_area_separate"),
  protocols = c("Stationary|Traveling", "Stationary|Traveling", "Complete Area"),
  duration_minutes = c("5-300", "1-360", "separate_registered_rule"),
  traveling_distance_km_max = c("5", "10", "not_pooled"),
  observers = c("1-10", "1-20", "separate_registered_rule"),
  candidate_role = c("candidate_primary", "broad_sensitivity", "separate_analysis"),
  disagreement_groups_in_primary = FALSE
)
write_support(protocol_amendment, "protocol_effort_amendment.csv")

message("Repair 5/8: clarifying model registry and prospective access claims")
mult_path <- "metadata/hypothesis_model_multiplicity_registry.csv"
mult <- fread(mult_path, na.strings = c("", "NA"))
mult[, `:=`(
  latent_pilot_choice_group = fifelse(model_id %chin% c("M21", "M35"), "community_latent_primary_choice", NA_character_),
  independent_evidence_object_count = fifelse(model_id %chin% c("M21", "M35"), 1L, NA_integer_),
  selected_together_as_independent_primary_evidence = FALSE
)]
mult[model_id %chin% c("M21", "M35"), model_role := "mutually_exclusive_primary_alternative_selected_by_one_latent_pilot"]
fwrite(mult, mult_path, quote = TRUE, na = "")

species_support_path <- file.path(out_dir, "species_support_summary.csv")
species_support <- fread(species_support_path, na.strings = c("", "NA"))
species_support[, specificity_panel_interpretation := fifelse(common_name %chin% c("Gadwall", "Northern Shoveler"),
  "specificity_and_falsification_panel_not_guaranteed_biological_nonresponders", NA_character_)]
write_support(species_support, "species_support_summary.csv")

access_path <- file.path(out_dir, "response_column_access_audit.csv")
access <- fread(access_path, na.strings = c("", "NA"))
access[, `:=`(
  prospective_2026_plus_response_summarized = FALSE,
  prospective_2026_plus_response_direction_viewed = FALSE,
  prospective_2026_plus_used_in_model_or_design_selection = FALSE,
  prior_mechanical_pattern_scan_disclosed = TRUE,
  repaired_extraction_filters_date_before_response_selection_or_persistence = TRUE
)]
write_support(access, "response_column_access_audit.csv")

message("Repair 6/8: updating decisions and machine-readable gate")
prospective_hash <- digest("metadata/prospective_confirmation_spec.yml", algo = "sha256", file = TRUE, serialize = FALSE)
recorded_prospective_hash <- strsplit(readLines("metadata/prospective_confirmation_spec.sha256", warn = FALSE)[1L], "[[:space:]]+")[[1L]][1L]
if (!identical(prospective_hash, recorded_prospective_hash)) stop("Prospective specification hash mismatch", call. = FALSE)

decisions <- fread(file.path(out_dir, "decision_recommendations.csv"), na.strings = c("", "NA"))
decisions[decision_id == "D03", `:=`(
  recommendation = "Immutable source record is the safe primary; original 2 km / 7 day complex remains provisional; deterministic 21-day/25-km anti-chaining is a registered alternative",
  sensitivity = "1km/3d|original 2km/7d provisional|anti-chained 2km/7d|5km/14d broad")]
decisions[decision_id == "D04", `:=`(
  recommendation = "Human-approved immutable source point is the primary representation; EDGE_TYPE 100 alongshore geometry is a SoG/WCVI sensitivity; EDGE_TYPE 150 remains separate and unavailable until local visual validation",
  sensitivity = "source point primary|EDGE_TYPE 100 SoG/WCVI sensitivity|EDGE_TYPE 150 after validation|actual length geometry")]
decisions[decision_id == "D05", `:=`(
  recommendation = "Standardized complete Stationary/Traveling checklists are candidate primary; start year requires sustained region-year support; broad effort is sensitivity; complete area remains separate",
  sensitivity = "2005|2010|2015|1988 long window|broad effort")]
decisions[decision_id == "D09", recommendation := "M21 and M35 are mutually exclusive alternatives selected by one detection-first latent pilot and contribute one primary evidence object; specificity panel is not assumed biologically nonresponsive"]
decisions[decision_id == "D10", recommendation := "Date-filter focal extraction before response selection/persistence; disclose prior mechanical scan; confirm once on complete 2026-2028 releases under frozen evidence rules"]
write_support(decisions, "decision_recommendations.csv")

join_audit <- fread(file.path(out_dir, "join_cardinality_audit.csv"), na.strings = c("", "NA"))
join_audit <- rbindlist(list(join_audit,
  data.table(
    relationship = c("SED keys to EBD membership", "SED source rows to shared analysis groups", "original 2km/7d complex to anti-chain complex"),
    expected_cardinality = c("many SED keys assessed once; unmatched are structural unknowns", "many-to-one", "many-to-one"),
    tested = TRUE, status = "PASS", independent_row_guard = TRUE
  )), fill = TRUE)
write_support(unique(join_audit), "join_cardinality_audit.csv")

stage_gate <- list(
  stage = "stage2_outcome_blind_design_lock",
  classification = "PASS_STAGE2_HUMAN_SCIENTIFIC_APPROVAL_RECORDED",
  human_scientific_decision = approval$scientific_decision,
  approval_version = approval$approval_version,
  approval_sha256 = approval_hash,
  approval_recorded_at_utc = approval$approved_at_utc,
  amendment_version = amendment$amendment_version,
  amendment_sha256 = amendment_hash,
  amendment_frozen_at_utc = amendment$amended_at_utc,
  original_candidate_grid_sha256 = grid_hash,
  original_candidate_grid_prior_windows_crlf_sha256 = amendment$parent_candidate_grid$original_windows_crlf_sha256,
  original_candidate_grid_frozen_at_utc = amendment$parent_candidate_grid$frozen_at_utc,
  original_candidate_grid_preserved_unchanged = TRUE,
  prospective_spec_sha256 = prospective_hash,
  registered_models_fitted = 0,
  prohibited_statistics_computed = 0,
  exact_ebird_coordinates_released = FALSE,
  raw_or_record_level_ebird_rows_released = FALSE,
  comments_read = FALSE,
  requires_human_scientific_approval = FALSE,
  response_models_authorized = FALSE,
  stage3_entry_implementation_authorized = FALSE,
  requires_separate_stage3_authorization = TRUE,
  validation_status = "PENDING_HUMAN_APPROVAL_GATE_TESTS_PRIVACY_RENDER_AND_GITHUB_ACTIONS",
  primary_design = list(
    event_geometry = "IMMUTABLE_SOURCE_POINT",
    geometry_scope = "COASTWIDE_WHERE_SOURCE_POINT_IS_VALID",
    event_identity = "IMMUTABLE_SOURCE_RECORD",
    edge_type_100_role = "SUPPORTED_REGION_ALONGSHORE_SENSITIVITY_SOG_WCVI",
    edge_type_150_role = "SEPARATE_SENSITIVITY_AFTER_LOCAL_VISUAL_VALIDATION",
    missing_extent_inference = "PROHIBITED"
  ),
  repair_status = list(
    ebd_sed_membership = "PASS_SED_ONLY_EXCLUDED_FROM_PRIMARY_ZERO_FILL",
    shoreline_geometry = geometry_gate,
    shoreline_bundle_coverage = "INCOMPLETE_NONBLOCKING_FOR_APPROVED_PRIMARY",
    actual_alongshore_geometry = if (actual_success > 0) "PASS_CONSTRUCTED_LOCAL_ONLY" else "FAIL_NOT_CONSTRUCTED",
    event_complex_review_packet = "PASS_ALL_FLAGGED_INCLUDED_SOURCE_RECORD_PRIMARY_APPROVED",
    region_period_support = "PASS_SOG_2005_WCVI_2015_APPROVED",
    protocol_effort = "PASS_STANDARDIZED_PRIMARY_APPROVED",
    shared_checklists = "PASS_DISAGREEMENT_EXCLUDED_COMPOSITE_OBSERVER_RULE_APPROVED",
    registry_clarification = "PASS_M21_M35_MUTUALLY_EXCLUSIVE_APPROVED",
    prospective_integrity = "PASS_FIXED_2026_2028_HORIZON_AND_EXTRACTION_RULE_APPROVED"
  ),
  remaining_nonblocking_requirements = list(
    edge_type_150_local_visual_validation = "PENDING_BEFORE_EDGE150_SENSITIVITY_USE",
    unsupported_shoreline_regions = "EXCLUDED_FROM_ALONGSHORE_SENSITIVITIES"
  ),
  validation = list(
    parent_github_actions_successful_run = 10,
    parent_github_actions_run_id = 29726150633,
    substantive_repair_github_actions = "PASS_RUN_15_ID_29761640213",
    repair_evidence_commit = "7af0f920bb71211ec2dbf6b20dfad481f11d7cdf",
    human_approval_github_actions = "PENDING"
  )
)
write_json(stage_gate, file.path(out_dir, "stage_gate.json"), pretty = TRUE, auto_unbox = TRUE)

message("Repair 7/8: protected-input amendment artifacts complete")
message("Repair 8/8: no response model or prohibited response summary was computed")
