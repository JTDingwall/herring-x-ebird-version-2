#!/usr/bin/env Rscript

# Build the Marine Environmental Research v3 descriptive tables and figures.
# This script reads only tracked, privacy-safe aggregate outputs. It does not
# read protected response data, model objects, row-level coordinates, or 2026+
# response records, and it does not fit or refit any response model.

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "AGENTS.md"))) {
  stop("Run from the repository root.", call. = FALSE)
}

suppressPackageStartupMessages({
  library(ggplot2)
  library(sf)
})

pkg_root <- file.path(repo_root, "manuscript", "journal_submission",
                      "marine_environmental_research")
dirs <- file.path(pkg_root, c("source_v3", "generated_v3", "figures_v3",
                              "tables_v3", "rendered_v3", "audits"))
invisible(lapply(dirs, dir.create, recursive = TRUE, showWarnings = FALSE))

path <- function(...) file.path(repo_root, ...)
out_path <- function(subdir, name) file.path(pkg_root, subdir, name)
read_csv <- function(...) read.csv(path(...), check.names = FALSE,
                                   na.strings = "")
write_csv <- function(x, f) write.csv(x, f, row.names = FALSE, na = "")

assert <- function(ok, msg) if (!isTRUE(ok)) stop(msg, call. = FALSE)
num <- function(x) suppressWarnings(as.numeric(x))
safe_div <- function(x, y) ifelse(is.finite(x) & is.finite(y) & y > 0, x / y, NA_real_)
slug <- function(x) gsub("[^a-z0-9]+", "_", tolower(x))

sample_sizes <- read_csv("outputs", "stage4a_results", "aggregate_sample_sizes.csv")
effects <- read_csv("outputs", "stage4a_results", "effect_estimates.csv")
fold_balance <- read_csv("outputs", "stage3_phase3_validation", "fold_balance.csv")
fold_strata <- read_csv("outputs", "stage3_phase3_validation", "fold_stratum_balance.csv")
observer_support <- read_csv("outputs", "stage3_phase3_validation", "observer_robustness_summary.csv")
region_support <- read_csv("outputs", "stage3_phase2_sampling_support", "region_period_support.csv")
region_year <- read_csv("outputs", "stage2_design_lock", "region_year_support.csv")
stage2_species <- read_csv("outputs", "stage2_design_lock", "species_support_summary.csv")
species_guild <- read_csv("metadata", "species_primary_guild.csv")
guild_registry <- read_csv("metadata", "canonical_guild_registry.csv")
event_time <- read_csv("outputs", "stage4a_publication_v2", "event_time_table_v2.csv")
sens <- read_csv("outputs", "stage4a_publication_sensitivity_v2", "sensitivity_effect_estimates_v2.csv")
fals <- read_csv("outputs", "stage4a_publication_v2", "sog_falsification_claim_audit_v2.csv")
model_geometry <- read_csv("outputs", "stage4a_results", "model_geometry.csv")
singular <- read_csv("outputs", "stage4a_publication_v2", "singular_fit_claim_audit_v2.csv")

assert(nrow(sample_sizes[sample_sizes$model_id == "M02", ]) == 196L,
       "Expected 49 species in each of four released regions.")
assert(nrow(fals) == 2L, "Expected the two-species M29 panel.")

# -------------------------------------------------------------------------
# Frozen region, exposure, event, observer, and sampling summaries.
# -------------------------------------------------------------------------

event_folds <- fold_balance[fold_balance$validation_view == "event_blocked", ]
sum_field <- function(z, field) sum(num(z[[field]]), na.rm = TRUE)
regions <- c("SoG", "WCVI", "CC", "NA")
region_labels <- c(SoG = "Strait of Georgia", WCVI = "West Coast Vancouver Island",
                   CC = "Central Coast", "NA" = "North")
year_start <- c(SoG = 2005, WCVI = 2015, CC = 1988, "NA" = 1988)

region_rows <- lapply(regions, function(r) {
  z <- event_folds[event_folds$region == r, ]
  n <- sum_field(z, "independent_checklists")
  a <- sum_field(z, "active_checklists")
  ref <- sum_field(z, "contemporaneous_reference_checklists")
  obs <- observer_support[observer_support$region == r, ]
  data.frame(
    region = r,
    region_label = unname(region_labels[r]),
    start_year = unname(year_start[r]),
    end_year = 2025,
    eligible_checklists = n,
    active_checklists = a,
    reference_checklists = ref,
    other_checklists = n - a - ref,
    active_proportion = safe_div(a, n),
    reference_proportion = safe_div(ref, n),
    other_proportion = safe_div(n - a - ref, n),
    represented_herring_source_events = sum_field(z, "herring_source_events"),
    event_blocks = sum_field(z, "event_blocks"),
    source_events_both_primary_periods = sum_field(z, "source_events_with_both_primary_periods"),
    dominant_observer_share = num(obs$dominant_observer_share),
    effective_observer_replication = num(obs$effective_observer_replication),
    scientific_role = obs$scientific_role,
    stringsAsFactors = FALSE
  )
})
region_summary <- do.call(rbind, region_rows)
assert(region_summary$eligible_checklists[region_summary$region == "SoG"] == 217200,
       "SoG frame mismatch.")
assert(region_summary$eligible_checklists[region_summary$region == "WCVI"] == 8584,
       "WCVI frame mismatch.")

primary_support <- region_support[
  region_support$effort_frame == "candidate_primary" &
    ((region_support$region == "SoG" & region_support$period_id == "start_2005") |
     (region_support$region == "WCVI" & region_support$period_id == "start_2015") |
     (region_support$region %in% c("CC", "NA") &
        region_support$period_id == "complete_1988_2025")), ]
primary_support <- primary_support[match(regions, primary_support$region), ]
region_summary$stationary_candidate_frame <- num(primary_support$stationary_events)
region_summary$traveling_candidate_frame <- num(primary_support$traveling_events)
region_summary$duration_median_minutes_candidate_frame <- num(primary_support$duration_q50)
region_summary$duration_p90_minutes_candidate_frame <- num(primary_support$duration_q90)
region_summary$travel_distance_median_km_candidate_frame <- num(primary_support$travel_distance_q50)
region_summary$travel_distance_p90_km_candidate_frame <- num(primary_support$travel_distance_q90)
region_summary$observer_count_median_candidate_frame <- num(primary_support$observer_number_q50)
region_summary$observer_count_p90_candidate_frame <- num(primary_support$observer_number_q90)
region_summary$unique_observer_clusters_candidate_frame <- num(primary_support$unique_observer_clusters)
region_summary$unique_location_clusters_candidate_frame <- num(primary_support$unique_generalized_locations)

# Executed v2 sparse-engine specification gives final-frame cluster counts.
region_summary$unique_observer_clusters_final_frame <- NA_real_
region_summary$unique_location_clusters_final_frame <- NA_real_
region_summary$unique_observer_clusters_final_frame[region_summary$region == "SoG"] <- 29248
region_summary$unique_location_clusters_final_frame[region_summary$region == "SoG"] <- 22980
region_summary$unique_observer_clusters_final_frame[region_summary$region == "WCVI"] <- 1880
region_summary$unique_location_clusters_final_frame[region_summary$region == "WCVI"] <- 1144

write_csv(region_summary, out_path("tables_v3", "Table_1_study_coverage_v3.csv"))

# Long, machine-readable descriptive statistics registry.
desc <- list()
add_desc <- function(region, metric, value, denominator = NA_real_, unit = "count",
                     frame, source, availability = "available", note = "") {
  desc[[length(desc) + 1L]] <<- data.frame(
    region = region, metric = metric, value = value, denominator = denominator,
    proportion = if (is.finite(value) && is.finite(denominator) && denominator > 0)
      value / denominator else NA_real_, unit = unit, frame = frame,
    source = source, availability = availability, note = note,
    stringsAsFactors = FALSE)
}
for (i in seq_len(nrow(region_summary))) {
  z <- region_summary[i, ]
  src_fold <- "outputs/stage3_phase3_validation/fold_balance.csv; event_blocked folds summed"
  add_desc(z$region, "eligible_complete_checklists", z$eligible_checklists,
           frame = "frozen Stage 4A analytical frame", source = src_fold)
  add_desc(z$region, "active_checklists", z$active_checklists, z$eligible_checklists,
           frame = "frozen Stage 4A analytical frame", source = src_fold,
           note = "Mutually exclusive active_reference_class=active")
  add_desc(z$region, "contemporaneous_reference_checklists", z$reference_checklists,
           z$eligible_checklists, frame = "frozen Stage 4A analytical frame", source = src_fold,
           note = "Mutually exclusive active_reference_class=reference")
  add_desc(z$region, "other_checklists", z$other_checklists, z$eligible_checklists,
           frame = "frozen Stage 4A analytical frame", source = src_fold,
           note = "Omitted active/reference category in M01/M02")
  add_desc(z$region, "represented_herring_source_events", z$represented_herring_source_events,
           frame = "frozen Stage 4A analytical frame", source = src_fold)
  add_desc(z$region, "event_blocks", z$event_blocks,
           frame = "frozen Stage 4A analytical frame", source = src_fold)
  add_desc(z$region, "source_events_both_primary_periods", z$source_events_both_primary_periods,
           frame = "frozen Stage 4A analytical frame", source = src_fold)
  add_desc(z$region, "dominant_observer_share", z$dominant_observer_share,
           unit = "proportion", frame = "frozen Stage 4A analytical frame",
           source = "outputs/stage3_phase3_validation/observer_robustness_summary.csv")
  add_desc(z$region, "effective_observer_replication", z$effective_observer_replication,
           unit = "effective count", frame = "frozen Stage 4A analytical frame",
           source = "outputs/stage3_phase3_validation/observer_robustness_summary.csv")
  for (nm in c("stationary_candidate_frame", "traveling_candidate_frame",
               "duration_median_minutes_candidate_frame", "duration_p90_minutes_candidate_frame",
               "travel_distance_median_km_candidate_frame", "travel_distance_p90_km_candidate_frame",
               "observer_count_median_candidate_frame", "observer_count_p90_candidate_frame")) {
    add_desc(z$region, nm, num(z[[nm]]), frame = "response-free candidate-primary support frame",
             source = "outputs/stage3_phase2_sampling_support/region_period_support.csv",
             note = "Candidate support frame; not identical to final response-analysis denominator")
  }
  add_desc(z$region, "concurrent_event_linked_checklists", NA_real_,
           frame = "frozen Stage 4A analytical frame", source = "not released as aggregate",
           availability = "unavailable_without_new_aggregate_authorization",
           note = "No protected cache was opened")
}

strata <- fold_strata[fold_strata$validation_view == "event_blocked" &
                        fold_strata$region %in% regions, ]
keys <- unique(strata[c("region", "stratum_dimension", "stratum_id")])
for (i in seq_len(nrow(keys))) {
  k <- keys[i, ]
  z <- strata[strata$region == k$region & strata$stratum_dimension == k$stratum_dimension &
                strata$stratum_id == k$stratum_id, ]
  n <- sum(num(z$independent_checklists), na.rm = TRUE)
  den <- region_summary$eligible_checklists[match(k$region, region_summary$region)]
  add_desc(k$region, paste(k$stratum_dimension, k$stratum_id, sep = ":"), n, den,
           frame = "frozen Stage 4A analytical frame",
           source = "outputs/stage3_phase3_validation/fold_stratum_balance.csv; event_blocked folds summed",
           note = "Strata overlap when one checklist links to multiple events; proportions are not compositional")
}
descriptive_statistics <- do.call(rbind, desc)
write_csv(descriptive_statistics, out_path("tables_v3", "descriptive_statistics_v3.csv"))

# -------------------------------------------------------------------------
# Species descriptive summary: regional final-frame states plus pooled,
# response-free support-only X, ambiguity, quantile, and concentration fields.
# -------------------------------------------------------------------------

m02_samples <- sample_sizes[sample_sizes$model_id == "M02", ]
m02_samples$n <- num(m02_samples$n)
m02_samples$detections <- num(m02_samples$detections)
m02_samples$positive_numeric <- num(m02_samples$positive_numeric)
m02_samples$structural_unknown <- num(m02_samples$structural_unknown)
m02_samples$complete_checklist_nondetections <- m02_samples$n - m02_samples$detections
m02_samples$detection_prevalence <- safe_div(m02_samples$detections, m02_samples$n)
m02_samples$numeric_availability_among_detections <-
  safe_div(m02_samples$positive_numeric, m02_samples$detections)

guild_lookup <- species_guild[c("common_name", "primary_guild_id")]
m02_samples <- merge(m02_samples, guild_lookup, by.x = "unit_label", by.y = "common_name",
                     all.x = TRUE, sort = FALSE)

stage2_keep <- c("common_name", "eligible_checklists", "detections",
                 "positive_numeric_reports", "X_reports", "lower_bound_reports",
                 "ambiguity_affected_reports", "years", "locations", "observers",
                 "positive_count_q50", "positive_count_q90", "positive_count_q99",
                 "represented_events", "represented_event_complexes",
                 "maximum_event_share", "maximum_observer_share", "maximum_location_share",
                 "numeric_availability", "support_label", "named_species_recommendation",
                 "positive_count_eligible")
stage2_sub <- stage2_species[stage2_species$common_name %in% unique(m02_samples$unit_label),
                             stage2_keep]
names(stage2_sub)[names(stage2_sub) != "common_name"] <-
  paste0("pooled_stage2_", names(stage2_sub)[names(stage2_sub) != "common_name"])
m02_samples <- merge(m02_samples, stage2_sub, by.x = "unit_label", by.y = "common_name",
                     all.x = TRUE, sort = FALSE)

m02_eff <- effects[effects$model_id == "M02", ]
det_eff <- m02_eff[m02_eff$outcome == "detection", c("region", "unit_label", "status")]
cnt_eff <- m02_eff[m02_eff$outcome == "positive_count", c("region", "unit_label", "status")]
names(det_eff)[3] <- "detection_fit_status"
names(cnt_eff)[3] <- "positive_count_fit_status"
m02_samples <- merge(m02_samples, det_eff, by = c("region", "unit_label"), all.x = TRUE, sort = FALSE)
m02_samples <- merge(m02_samples, cnt_eff, by = c("region", "unit_label"), all.x = TRUE, sort = FALSE)
m02_samples$positive_count_iqr <- NA_real_
m02_samples$regional_years_represented <- NA_real_
m02_samples$regional_event_blocks <- NA_real_
m02_samples$regional_observer_support <- NA_real_
m02_samples$regional_location_support <- NA_real_
m02_samples$regional_count_distribution_status <-
  "not released; pooled response-free quantiles supplied in pooled_stage2_* fields"
m02_samples$source_regional <- "outputs/stage4a_results/aggregate_sample_sizes.csv"
m02_samples$source_pooled_support <- "outputs/stage2_design_lock/species_support_summary.csv"
m02_samples$interpretation <- "unadjusted descriptive checklist reporting; not a spawn effect"

species_order <- c("region", "unit_label", "primary_guild_id", "n", "detections",
                   "detection_prevalence", "complete_checklist_nondetections",
                   "positive_numeric", "numeric_availability_among_detections",
                   "structural_unknown", "pooled_stage2_X_reports",
                   "pooled_stage2_lower_bound_reports", "pooled_stage2_ambiguity_affected_reports",
                   "pooled_stage2_positive_count_q50", "positive_count_iqr",
                   "pooled_stage2_positive_count_q90", "pooled_stage2_positive_count_q99",
                   "pooled_stage2_years", "pooled_stage2_represented_events",
                   "pooled_stage2_observers", "pooled_stage2_locations",
                   "pooled_stage2_maximum_observer_share", "pooled_stage2_maximum_event_share",
                   "detection_fit_status", "positive_count_fit_status",
                   "regional_count_distribution_status", "source_regional",
                   "source_pooled_support", "interpretation")
species_desc <- m02_samples[species_order]
species_desc <- species_desc[order(species_desc$region, species_desc$unit_label), ]
assert(nrow(species_desc) == 196L, "Species descriptive summary cardinality changed.")
write_csv(species_desc, out_path("tables_v3", "species_descriptive_summary_v3.csv"))

# -------------------------------------------------------------------------
# Guild descriptive summary.
# -------------------------------------------------------------------------

m01_samples <- sample_sizes[sample_sizes$model_id == "M01", ]
m01_samples$n <- num(m01_samples$n)
m01_samples$detections <- num(m01_samples$detections)
m01_samples$positive_numeric <- num(m01_samples$positive_numeric)
m01_samples$structural_unknown <- num(m01_samples$structural_unknown)
m01_samples$detection_prevalence <- safe_div(m01_samples$detections, m01_samples$n)
m01_samples$numeric_availability_among_detections <-
  safe_div(m01_samples$positive_numeric, m01_samples$detections)
members <- aggregate(common_name ~ primary_guild_id, species_guild,
                     function(x) paste(sort(x), collapse = "; "))
member_n <- aggregate(common_name ~ primary_guild_id, species_guild, length)
names(member_n)[2] <- "member_taxa"
guild_desc <- merge(m01_samples, guild_registry[c("guild_id", "guild_label", "mechanism",
                                                  "membership_rule", "analysis_priority")],
                    by.x = "unit_label", by.y = "guild_id", all.x = TRUE, sort = FALSE)
guild_desc <- merge(guild_desc, members, by.x = "unit_label", by.y = "primary_guild_id",
                    all.x = TRUE, sort = FALSE)
guild_desc <- merge(guild_desc, member_n, by.x = "unit_label", by.y = "primary_guild_id",
                    all.x = TRUE, sort = FALSE)
guild_desc$member_taxa[is.na(guild_desc$member_taxa)] <- 2L
guild_desc$common_name[is.na(guild_desc$common_name)] <- "Gadwall; Northern Shoveler"
guild_desc$detected_member_taxa_distribution <- NA_character_
guild_desc$positive_numeric_guild_count_distribution <- NA_character_
guild_desc$availability_note <- paste(
  "Regional prevalence is released; per-checklist richness and guild-count quantiles",
  "are not released and were not reconstructed from protected rows.")
guild_desc$source <- "outputs/stage4a_results/aggregate_sample_sizes.csv; metadata/species_primary_guild.csv"
guild_desc <- guild_desc[c("region", "unit_label", "guild_label", "mechanism",
                           "member_taxa", "common_name", "n", "detections",
                           "detection_prevalence", "positive_numeric",
                           "numeric_availability_among_detections", "structural_unknown",
                           "detected_member_taxa_distribution",
                           "positive_numeric_guild_count_distribution", "availability_note", "source")]
guild_desc <- guild_desc[order(guild_desc$region, guild_desc$unit_label), ]
write_csv(guild_desc, out_path("tables_v3", "guild_descriptive_summary_v3.csv"))

# -------------------------------------------------------------------------
# Herring-event descriptive summary, including explicit unavailable fields.
# -------------------------------------------------------------------------

herring_rows <- list()
add_herring <- function(region, metric, value, unit, source, status = "available", note = "") {
  herring_rows[[length(herring_rows) + 1L]] <<- data.frame(
    region = region, metric = metric, value = value, unit = unit, source = source,
    availability = status, note = note, stringsAsFactors = FALSE)
}
for (i in seq_len(nrow(region_summary))) {
  z <- region_summary[i, ]
  src <- "outputs/stage3_phase3_validation/fold_balance.csv; event_blocked folds summed"
  add_herring(z$region, "represented_herring_source_events", z$represented_herring_source_events,
              "events", src)
  add_herring(z$region, "event_blocks", z$event_blocks, "blocks", src)
  add_herring(z$region, "source_events_both_primary_periods", z$source_events_both_primary_periods,
              "events", src)
  add_herring(z$region, "active_near_checklists", z$active_checklists, "checklists", src)
  add_herring(z$region, "contemporaneous_reference_checklists", z$reference_checklists,
              "checklists", src)
  add_herring(z$region, "event_date_within_year_distribution", NA_real_, "not released",
              "not released as aggregate", "unavailable_without_new_aggregate_authorization",
              "No protected event rows were opened")
  add_herring(z$region, "checklists_per_event_distribution", NA_real_, "not released",
              "not released as aggregate", "unavailable_without_new_aggregate_authorization")
  add_herring(z$region, "concurrent_event_linkage_distribution", NA_real_, "not released",
              "not released as aggregate", "unavailable_without_new_aggregate_authorization")
  add_herring(z$region, "relative_spawn_index_distribution", NA_real_, "not analyzed",
              "Stage 4A does not fit or release a comparable intensity distribution",
              "reserved_for_future_authorized_analysis",
              "Relative index is not absolute biomass; missing components are not zero")
}
for (i in seq_len(nrow(keys))) {
  k <- keys[i, ]
  if (!k$region %in% regions) next
  z <- strata[strata$region == k$region & strata$stratum_dimension == k$stratum_dimension &
                strata$stratum_id == k$stratum_id, ]
  add_herring(k$region, paste(k$stratum_dimension, k$stratum_id, sep = ":"),
              sum(num(z$independent_checklists), na.rm = TRUE), "linked checklists",
              "outputs/stage3_phase3_validation/fold_stratum_balance.csv; event_blocked folds summed",
              note = "Nonexclusive when checklists have multiple concurrent event links")
}
herring_desc <- do.call(rbind, herring_rows)
write_csv(herring_desc, out_path("tables_v3", "herring_event_descriptive_summary_v3.csv"))

# -------------------------------------------------------------------------
# Main inferential tables on interpretable ratio scales. Values are pure
# transformations of frozen coefficients; no estimate is changed.
# -------------------------------------------------------------------------

focal_taxa <- c("Surf Scoter", "Short-billed Gull", "Glaucous-winged Gull",
                "Harlequin Duck", "White-winged Scoter", "Common Merganser",
                "Red-breasted Merganser", "Canada Goose", "Common Loon",
                "Black Oystercatcher", "Black Turnstone", "Great Blue Heron")
focal <- effects[effects$model_id == "M02" & effects$region %in% c("SoG", "WCVI") &
                   effects$unit_label %in% focal_taxa &
                   effects$outcome %in% c("detection", "positive_count"), ]
for (v in c("estimate", "conf_low", "conf_high", "q_value", "n")) focal[[v]] <- num(focal[[v]])
focal$ratio <- exp(focal$estimate)
focal$ratio_conf_low <- exp(focal$conf_low)
focal$ratio_conf_high <- exp(focal$conf_high)
focal$ratio_interpretation <- ifelse(focal$outcome == "detection", "detection odds ratio",
                                     "conditional positive-count ratio")
focal$contrast_interpretation <- "active-near versus omitted other exposure class"
write_csv(focal, out_path("tables_v3", "Table_3_focal_species_effects_v3.csv"))

m29 <- fals
for (v in c("estimate_log_odds", "conf_low", "conf_high", "bh_q_value", "n")) m29[[v]] <- num(m29[[v]])
m29$odds_ratio <- exp(m29$estimate_log_odds)
m29$odds_ratio_conf_low <- exp(m29$conf_low)
m29$odds_ratio_conf_high <- exp(m29$conf_high)
write_csv(m29, out_path("tables_v3", "Table_4_specificity_sensitivity_v3.csv"))

# -------------------------------------------------------------------------
# Figure helpers and style.
# -------------------------------------------------------------------------

ink <- "#1F2D3A"
blue <- "#2C7891"
blue_light <- "#A7CFD8"
gold <- "#C98B2A"
rust <- "#A44A3F"
grey <- "#697782"
paper <- "#FCFCFA"

theme_mer <- function(base_size = 10.5) {
  theme_minimal(base_size = base_size, base_family = "sans") +
    theme(plot.background = element_rect(fill = paper, colour = NA),
          panel.background = element_rect(fill = paper, colour = NA),
          plot.title = element_text(face = "bold", colour = ink, size = rel(1.25)),
          plot.subtitle = element_text(colour = grey, margin = margin(b = 8)),
          plot.caption = element_text(colour = grey, size = rel(0.78), hjust = 0),
          axis.title = element_text(colour = ink), axis.text = element_text(colour = ink),
          strip.text = element_text(face = "bold", colour = ink),
          strip.background = element_rect(fill = "#EAF0F2", colour = NA),
          panel.grid.minor = element_blank(),
          panel.grid.major.y = element_line(colour = "#E2E7E9", linewidth = 0.25),
          panel.grid.major.x = element_line(colour = "#E2E7E9", linewidth = 0.25),
          legend.position = "bottom", legend.title = element_text(face = "bold"))
}

cap <- function(x) paste(strwrap(x, width = 105), collapse = "\n")

save_plot <- function(p, stem, width, height) {
  png_file <- out_path("figures_v3", paste0(stem, ".png"))
  pdf_file <- out_path("figures_v3", paste0(stem, ".pdf"))
  ggsave(png_file, p, width = width, height = height, units = "in", dpi = 600,
         bg = paper, limitsize = FALSE)
  ggsave(pdf_file, p, width = width, height = height, units = "in", device = cairo_pdf,
         bg = paper, limitsize = FALSE)
}

# Figure 1: public generalized BC context plus broad region-level aggregates.
world_gpkg <- "C:/Program Files/QGIS 3.34.10/apps/qgis-ltr/resources/data/world_map.gpkg"
assert(file.exists(world_gpkg), "Public generalized QGIS world map is unavailable.")
bc <- st_read(world_gpkg, layer = "states_provinces", quiet = TRUE)
bc <- bc[!is.na(bc[["name"]]) & bc[["name"]] == "British Columbia", ]
assert(nrow(bc) == 1L, "British Columbia polygon not found.")

anchors <- data.frame(
  region = regions,
  lon = c(-123.5, -126.1, -127.7, -130.0),
  lat = c(49.6, 49.4, 52.0, 54.0),
  label_lon = c(-122.9, -127.1, -126.0, -129.2),
  label_lat = c(50.65, 50.30, 52.75, 55.05),
  count_lon = c(-122.8, -127.0, -126.0, -129.2),
  count_lat = c(48.70, 48.35, 51.35, 53.25),
  stringsAsFactors = FALSE)
map_dat <- merge(anchors, region_summary, by = "region", sort = FALSE)
map_dat$role <- ifelse(map_dat$region %in% c("SoG", "WCVI"), "Primary regional frame",
                       "Descriptive context")

p1 <- ggplot() +
  geom_sf(data = bc, fill = "#EEF1EC", colour = "#70808A", linewidth = 0.35) +
  geom_point(data = map_dat, aes(lon, lat, size = eligible_checklists, fill = role),
             shape = 21, colour = ink, stroke = 0.45, alpha = 0.9) +
  geom_point(data = map_dat, aes(lon + 0.35, lat - 0.25), shape = 24, size = 3.4,
             fill = gold, colour = ink, stroke = 0.4) +
  geom_text(data = map_dat, aes(label_lon, label_lat, label = region_label),
            colour = ink, fontface = "bold", size = 3.1) +
  geom_text(data = map_dat,
            aes(count_lon, count_lat,
                label = paste0(format(eligible_checklists, big.mark = ","), " checklists\n",
                               represented_herring_source_events, " recorded events")),
            colour = ink, size = 2.65, lineheight = 0.95) +
  annotate("segment", x = -131.0, xend = -131.0, y = 48.5, yend = 49.35,
           linewidth = 0.65, colour = ink, arrow = arrow(length = unit(0.13, "in"))) +
  annotate("text", x = -131.0, y = 49.55, label = "N", fontface = "bold", size = 3.2) +
  annotate("segment", x = -130.5, xend = -129.0, y = 48.25, yend = 48.25,
           linewidth = 1.2, colour = ink) +
  annotate("text", x = -129.75, y = 47.95, label = "~100 km at 50°N", size = 2.5) +
  scale_size_area(max_size = 16, breaks = c(1000, 10000, 100000),
                  labels = scales::label_number(big.mark = ","), name = "Eligible checklists") +
  scale_fill_manual(values = c("Primary regional frame" = blue_light,
                               "Descriptive context" = "#D9DDD9"), name = NULL) +
  coord_sf(xlim = c(-132.5, -121.5), ylim = c(47.5, 55.5), expand = FALSE) +
  labs(title = "Study regions and broad sampling coverage",
       subtitle = "Circles show privacy-safe region totals; triangles denote recorded herring-event support",
       x = NULL, y = NULL,
       caption = cap(paste("Generalized public coastline (QGIS world map, WGS 84).",
                           "Region anchors are display positions, not checklist or event coordinates."))) +
  theme_mer(10) +
  theme(panel.grid = element_blank(), axis.text = element_blank(), axis.ticks = element_blank())
save_plot(p1, "Figure_1_study_area_map_v3", 7.2, 6.0)

# Figure 2: raw regional prevalence for common or biologically informative taxa.
desc_taxa <- c("Surf Scoter", "Short-billed Gull", "Glaucous-winged Gull",
               "Canada Goose", "Common Merganser", "Red-breasted Merganser",
               "Common Loon", "Black Turnstone", "Black Oystercatcher",
               "Great Blue Heron", "Western Grebe", "Pigeon Guillemot",
               "Bufflehead", "Harlequin Duck")
prev <- species_desc[species_desc$region %in% c("SoG", "WCVI") &
                       species_desc$unit_label %in% desc_taxa, ]
prev$unit_label <- factor(prev$unit_label, levels = rev(desc_taxa))
prev$numeric_availability_among_detections <- num(prev$numeric_availability_among_detections)
p2 <- ggplot(prev, aes(detection_prevalence, unit_label)) +
  geom_segment(aes(x = 0, xend = detection_prevalence, yend = unit_label),
               colour = "#D8E0E3", linewidth = 0.6) +
  geom_point(aes(fill = numeric_availability_among_detections), shape = 21,
             size = 3.1, colour = ink, stroke = 0.35) +
  facet_wrap(~region, nrow = 1, scales = "free_x") +
  scale_x_continuous(labels = scales::label_percent(accuracy = 1), expand = expansion(mult = c(0, .05))) +
  scale_fill_gradient(low = "#F2D7A3", high = blue, limits = c(0.75, 1),
                      oob = scales::squish, labels = scales::label_percent(accuracy = 1),
                      name = "Numeric reports\namong detections") +
  labs(title = "Unadjusted checklist detection prevalence",
       subtitle = "Selected common and ecologically informative taxa; prevalence is not a spawn effect",
       x = "Eligible complete checklists reporting the taxon", y = NULL,
       caption = cap("Complete-checklist omissions are nondetections, not confirmed biological absences.")) +
  theme_mer(10)
save_plot(p2, "Figure_2_descriptive_bird_patterns_v3", 7.2, 6.6)

# Figure 3: transformed focal M02 estimates; active versus omitted other.
focal_plot <- focal[is.finite(focal$ratio), ]
focal_plot$taxon <- factor(focal_plot$unit_label, levels = rev(focal_taxa))
focal_plot$outcome_label <- ifelse(focal_plot$outcome == "detection", "Detection odds ratio",
                                   "Conditional positive-count ratio")
p3 <- ggplot(focal_plot, aes(ratio, taxon, colour = region)) +
  geom_vline(xintercept = 1, colour = grey, linewidth = 0.45, linetype = 2) +
  geom_errorbarh(aes(xmin = ratio_conf_low, xmax = ratio_conf_high),
                 height = 0, linewidth = 0.55, position = position_dodge(width = 0.5)) +
  geom_point(size = 2.25, position = position_dodge(width = 0.5)) +
  facet_wrap(~outcome_label, nrow = 1, scales = "free_x") +
  scale_x_log10() +
  scale_colour_manual(values = c(SoG = blue, WCVI = gold), name = "Region") +
  labs(title = "Adjusted focal-species associations",
       subtitle = "Ratios are exponentiated frozen M02 coefficients with 95% intervals",
       x = "Active-near versus other exposure class (ratio scale)", y = NULL,
       caption = cap(paste("Ratios above 1 indicate higher modeled reporting or conditional positive count.",
                           "The released M02 engine is not component-identifiable; see the v3 estimand audit."))) +
  theme_mer(9.5)
save_plot(p3, "Figure_3_focal_species_effects_v3", 7.2, 7.2)

# Figure 4: event-time coefficients relative to early-pre baseline.
timing_guilds <- c("roe_diving_seaduck", "gull_roe", "piscivore_active_spawn",
                   "intertidal_roe_shorebird")
et <- event_time[event_time$unit_label %in% timing_guilds &
                   event_time$region %in% c("SoG", "WCVI"), ]
for (v in c("estimate", "conf_low", "conf_high")) et[[v]] <- num(et[[v]])
name_map <- c(time_immediate_pre = "Late pre-spawn\n−28 to −1",
              time_spawn_start = "Spawn start\n0 to 3",
              time_early_egg = "Early egg\n4 to 14",
              time_late_egg = "Late egg\n15 to 28",
              time_post = "Post\n29 to 56")
et$window <- unname(name_map[et$contrast])
base <- unique(et[c("region", "unit_label", "unit_class", "outcome")])
base$contrast <- "time_early_pre"
base$estimate <- base$conf_low <- base$conf_high <- 0
base$window <- "Early pre-spawn\n−42 to −29\n(reference)"
etp <- rbind(et[c("region", "unit_label", "unit_class", "outcome", "contrast",
                  "estimate", "conf_low", "conf_high", "window")], base)
window_levels <- c("Early pre-spawn\n−42 to −29\n(reference)", unname(name_map))
etp$window <- factor(etp$window, levels = window_levels)
guild_labels <- setNames(guild_registry$guild_label, guild_registry$guild_id)
etp$guild <- unname(guild_labels[etp$unit_label])
etp$outcome_label <- ifelse(etp$outcome == "detection", "Detection", "Conditional positive count")
p4 <- ggplot(etp, aes(window, estimate, group = guild, colour = guild)) +
  geom_hline(yintercept = 0, colour = grey, linewidth = 0.4, linetype = 2) +
  geom_line(linewidth = 0.55, alpha = 0.85) +
  geom_point(size = 1.7) +
  facet_grid(outcome_label ~ region, scales = "free_y") +
  scale_colour_manual(values = c(blue, gold, rust, "#6F7E3C"), name = "Guild") +
  labs(title = "Registered event windows did not share one trajectory",
       subtitle = "Selected guilds; coefficients are discrete contrasts with early pre-spawn",
       x = NULL, y = "Coefficient on the fitted link scale",
       caption = cap("Lines connect registered discrete windows for readability; they are not a continuous causal event study.")) +
  theme_mer(8.8) +
  theme(axis.text.x = element_text(angle = 35, hjust = 1), legend.position = "bottom")
save_plot(p4, "Figure_4_event_time_v3", 7.2, 6.8)

# Figure 5: M29 comparators in the full SoG species detection distribution.
sog_dist <- effects[effects$model_id == "M02" & effects$region == "SoG" &
                      effects$outcome == "detection" & effects$status == "completed", ]
for (v in c("estimate", "conf_low", "conf_high")) sog_dist[[v]] <- num(sog_dist[[v]])
sog_dist$label <- sog_dist$unit_label
sog_dist$type <- "Support-qualified species"
m29d <- data.frame(unit_label = m29$species, estimate = m29$estimate_log_odds,
                   conf_low = m29$conf_low, conf_high = m29$conf_high,
                   label = m29$species, type = "Specificity comparator")
dist_all <- rbind(sog_dist[c("unit_label", "estimate", "conf_low", "conf_high", "label", "type")], m29d)
dist_all <- dist_all[order(dist_all$estimate), ]
dist_all$rank <- seq_len(nrow(dist_all))
label_taxa <- c("Gadwall", "Northern Shoveler", "Surf Scoter", "Short-billed Gull",
                "Canada Goose", "Common Loon", "Black Turnstone")
lab <- dist_all[dist_all$unit_label %in% label_taxa, ]
p5 <- ggplot(dist_all, aes(rank, estimate)) +
  geom_hline(yintercept = 0, colour = grey, linewidth = 0.45, linetype = 2) +
  geom_linerange(aes(ymin = conf_low, ymax = conf_high, colour = type), linewidth = 0.35, alpha = 0.75) +
  geom_point(aes(fill = type, shape = type), size = 2.2, colour = ink, stroke = 0.35) +
  geom_text(data = lab, aes(label = label), size = 2.6, colour = ink,
            nudge_y = 0.12, check_overlap = TRUE) +
  scale_colour_manual(values = c("Support-qualified species" = blue,
                                 "Specificity comparator" = gold), guide = "none") +
  scale_fill_manual(values = c("Support-qualified species" = blue_light,
                               "Specificity comparator" = gold), name = NULL) +
  scale_shape_manual(values = c("Support-qualified species" = 21,
                                "Specificity comparator" = 24), name = NULL) +
  labs(title = "Specificity comparators fell within the SoG species distribution",
       subtitle = "Detection coefficients for active-near versus the omitted other exposure class",
       x = "Species and comparators ordered by coefficient", y = "Log-odds coefficient",
       caption = cap("The non-null M29 panel limits simple ecological-specificity interpretations; it does not test conditional counts.")) +
  theme_mer(10) + theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())
save_plot(p5, "Figure_5_specificity_distribution_v3", 7.2, 5.0)

# Figure 6: selected cross-region recurrence without calling it replication.
recurrence_taxa <- c("Surf Scoter", "Short-billed Gull", "Common Merganser",
                     "Red-breasted Merganser", "Canada Goose", "Common Loon",
                     "Black Turnstone", "Glaucous-winged Gull")
rec <- focal[focal$unit_label %in% recurrence_taxa, ]
rec$taxon <- factor(rec$unit_label, levels = rev(recurrence_taxa))
rec$outcome_label <- ifelse(rec$outcome == "detection", "Detection", "Conditional positive count")
p6 <- ggplot(rec, aes(ratio, taxon, colour = region)) +
  geom_vline(xintercept = 1, colour = grey, linewidth = 0.4, linetype = 2) +
  geom_errorbarh(aes(xmin = ratio_conf_low, xmax = ratio_conf_high), height = 0,
                 linewidth = 0.5, position = position_dodge(width = 0.48)) +
  geom_point(size = 2.2, position = position_dodge(width = 0.48)) +
  facet_wrap(~outcome_label, nrow = 1, scales = "free_x") +
  scale_x_log10() + scale_colour_manual(values = c(SoG = blue, WCVI = gold), name = "Region") +
  labs(title = "Selected directional recurrence across unequal regional frames",
       subtitle = "SoG had 217,200 eligible checklists; WCVI had 8,584 and greater observer concentration",
       x = "Active-near versus other exposure class (ratio scale)", y = NULL,
       caption = cap("Sign agreement is descriptive cross-region recurrence, not formal replication.")) +
  theme_mer(9.5)
save_plot(p6, "Figure_6_regional_comparison_v3", 7.2, 5.8)

# Supplementary Figure S1: conceptual exposure and traveling-checklist geometry.
schem <- data.frame(xmin = c(0, 5, 20), xmax = c(5, 20, 27),
                    ymin = 0, ymax = 1,
                    class = c("Active-near", "Contemporaneous reference", "Other linked conditions"))
pS1 <- ggplot() +
  geom_rect(data = schem, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = class),
            colour = paper, linewidth = 0.8) +
  geom_vline(xintercept = c(5, 20), colour = ink, linewidth = 0.4) +
  annotate("point", x = 0, y = 0.5, shape = 24, size = 5, fill = gold, colour = ink) +
  annotate("text", x = 0.7, y = 0.72, label = "Recorded spawn\nsource point", hjust = 0, size = 3) +
  annotate("segment", x = 1.1, xend = 4.2, y = 0.25, yend = 0.72,
           linewidth = 1.2, colour = rust, arrow = arrow(length = unit(0.12, "in"))) +
  annotate("text", x = 2.7, y = 0.12, label = "Traveling checklist route\nrepresented by one point coordinate",
           size = 2.8, colour = ink) +
  annotate("text", x = 2.5, y = 0.9, label = "0–5 km\nDays 0–28", fontface = "bold", size = 3.2) +
  annotate("text", x = 12.5, y = 0.5, label = "5–20 km\nDays 0–28\n(if no active-near link)",
           fontface = "bold", size = 3.2) +
  annotate("text", x = 23.5, y = 0.5, label = "Pre/post windows\nor remaining linked\nconditions",
           fontface = "bold", size = 3.0) +
  scale_fill_manual(values = c("Active-near" = blue_light,
                               "Contemporaneous reference" = "#E8D8B8",
                               "Other linked conditions" = "#E4E7E8"), guide = "none") +
  coord_cartesian(xlim = c(-1, 27), ylim = c(-0.2, 1.15), clip = "off") +
  labs(title = "Exposure coding and source-point limitation",
       subtitle = "Active and reference are mutually exclusive; other is the omitted M01/M02 category",
       x = "Schematic distance from a recorded source point (km)", y = NULL,
       caption = cap("All concurrent links were retained additively within one checklist row. Schematic is not geographic.")) +
  theme_mer(10) + theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(),
                        panel.grid = element_blank())
save_plot(pS1, "Figure_S1_exposure_design_v3", 7.2, 4.2)

# Supplementary Figure S2: broad region-level active/reference support map.
map_dat$active_share <- map_dat$active_proportion
map_dat$support_label_lon <- ifelse(map_dat$region == "SoG", -123.8, map_dat$count_lon)
map_dat$support_label_lat <- map_dat$count_lat
pS2 <- ggplot() +
  geom_sf(data = bc, fill = "#EEF1EC", colour = "#70808A", linewidth = 0.35) +
  geom_point(data = map_dat, aes(lon, lat, size = eligible_checklists, fill = active_share),
             shape = 21, colour = ink, stroke = 0.5) +
  geom_text(data = map_dat,
            aes(support_label_lon, support_label_lat,
                label = paste0(region, "\nA ", format(active_checklists, big.mark = ","),
                               " | R ", format(reference_checklists, big.mark = ","))),
            size = 2.8, colour = ink) +
  scale_size_area(max_size = 15, breaks = c(1000, 10000, 100000),
                  labels = scales::label_number(big.mark = ","), name = "Eligible checklists") +
  scale_fill_gradient(low = "#F3E5C7", high = rust, labels = scales::label_percent(accuracy = 1),
                       name = "Active share") +
  guides(fill = guide_colourbar(order = 1, title.position = "top", barwidth = unit(2.2, "in")),
         size = guide_legend(order = 2, title.position = "top", nrow = 1)) +
  coord_sf(xlim = c(-132.5, -121.5), ylim = c(47.5, 55.5), expand = FALSE) +
  labs(title = "Region-level active and reference support",
       subtitle = "A = active-near; R = contemporaneous reference; labels are aggregate counts",
       x = NULL, y = NULL,
       caption = cap("Broad display anchors are not record locations; every displayed regional cell exceeds n = 20.")) +
  theme_mer(10) +
  theme(panel.grid = element_blank(), axis.text = element_blank(), axis.ticks = element_blank(),
        legend.box = "vertical", legend.justification = "center")
save_plot(pS2, "Figure_S2_sampling_support_map_v3", 7.2, 5.8)

# Supplementary Figure S3: complete 49-species coefficient matrix.
mat <- effects[effects$model_id == "M02" & effects$region %in% c("SoG", "WCVI") &
                 effects$outcome %in% c("detection", "positive_count"), ]
mat$estimate <- num(mat$estimate)
mat$q_value <- num(mat$q_value)
mat$panel <- paste(mat$region, ifelse(mat$outcome == "detection", "Detection", "Positive count"))
mat$unit_label <- factor(mat$unit_label, levels = rev(sort(unique(mat$unit_label))))
mat$label <- ifelse(is.finite(mat$estimate), sprintf("%.2f%s", mat$estimate,
                                                     ifelse(mat$q_value < .05, "*", "")), "NA")
pS3 <- ggplot(mat, aes(panel, unit_label, fill = estimate)) +
  geom_tile(colour = paper, linewidth = 0.25) +
  geom_text(aes(label = label), size = 1.7, colour = ink) +
  scale_fill_gradient2(low = "#B65C52", mid = "#F7F5EF", high = "#4C8CA2", midpoint = 0,
                       na.value = "#D8DDDF", name = "Coefficient") +
  labs(title = "All 49 support-qualified species",
       subtitle = "Frozen M02 active-near versus other coefficients; * BH q < 0.05",
       x = NULL, y = NULL,
       caption = cap("One noncompleted component remains NA; no cell is converted to zero.")) +
  theme_mer(7.2) + theme(axis.text.x = element_text(angle = 30, hjust = 1), legend.position = "bottom")
save_plot(pS3, "Figure_S3_complete_species_matrix_v3", 7.2, 10.2)

# Supplementary Figure S4: sparse-engine M01 guild reference.
guild_eff <- sens[sens$model_version_id == "M01_PRIMARY_v2", ]
for (v in c("estimate", "conf_low", "conf_high")) guild_eff[[v]] <- num(guild_eff[[v]])
guild_eff$ratio <- exp(guild_eff$estimate)
guild_eff$lo <- exp(guild_eff$conf_low)
guild_eff$hi <- exp(guild_eff$conf_high)
guild_eff$guild <- unname(guild_labels[guild_eff$unit_label])
guild_eff$guild[guild_eff$unit_label == "falsification"] <- "Specificity guild"
guild_eff$outcome_label <- ifelse(guild_eff$outcome == "detection", "Detection",
                                  "Conditional positive count")
pS4 <- ggplot(guild_eff, aes(ratio, reorder(guild, ratio), colour = region)) +
  geom_vline(xintercept = 1, colour = grey, linewidth = 0.4, linetype = 2) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0, linewidth = 0.5,
                 position = position_dodge(width = .45)) +
  geom_point(size = 2, position = position_dodge(width = .45)) +
  facet_wrap(~outcome_label, nrow = 1, scales = "free_x") +
  scale_x_log10() + scale_colour_manual(values = c(SoG = blue, WCVI = gold), name = "Region") +
  labs(title = "Registered guild synthesis",
       subtitle = "Sparse lme4 M01_PRIMARY_v2 reference; ratios with 95% intervals",
       x = "Active-near versus other exposure class (ratio scale)", y = NULL) +
  theme_mer(9)
save_plot(pS4, "Figure_S4_guild_synthesis_v3", 7.2, 5.5)

# Supplementary Figure S5: matched WCVI sensitivities and shifted placebos.
sp <- sens[sens$model_version_id %in% c("M01_PRIMARY_v2", "S4A12_WCVI_2KM_v2",
                                        "S4A11_WCVI_DOMINANT_OBSERVER_v2", "M27_v2", "M28_v2") &
             sens$region == "WCVI" & sens$outcome == "detection", ]
for (v in c("estimate", "conf_low", "conf_high")) sp[[v]] <- num(sp[[v]])
sp$model <- factor(sp$model_version_id,
                   levels = c("M01_PRIMARY_v2", "S4A12_WCVI_2KM_v2",
                              "S4A11_WCVI_DOMINANT_OBSERVER_v2", "M27_v2", "M28_v2"),
                   labels = c("Matched reference", "2-km cohort", "Dominant-observer holdout",
                              "Date-bundle placebo", "Location-bundle placebo"))
pS5 <- ggplot(sp, aes(estimate, reorder(unit_label, estimate), colour = model)) +
  geom_vline(xintercept = 0, colour = grey, linewidth = 0.4, linetype = 2) +
  geom_errorbarh(aes(xmin = conf_low, xmax = conf_high), height = 0,
                 linewidth = 0.45, position = position_dodge(width = .65)) +
  geom_point(size = 1.6, position = position_dodge(width = .65)) +
  scale_colour_manual(values = c(blue, gold, rust, "#7F8C8D", "#596A8A"), name = NULL) +
  labs(title = "Matched WCVI sensitivities and shifted-exposure placebos",
       subtitle = "Detection components; singular warnings remain in the released diagnostic tables",
       x = "Log-odds coefficient", y = NULL,
       caption = cap("Shifted-exposure placebos and biological specificity comparators target different weaknesses.")) +
  theme_mer(8.7)
save_plot(pS5, "Figure_S5_sensitivities_placebos_v3", 7.2, 6.0)

# Supplementary Figure S6: model completion and diagnostic visibility.
geom_counts <- aggregate(list(components = rep(1L, nrow(model_geometry))),
                         list(status = model_geometry$status,
                              rank_deficient = ifelse(model_geometry$rank_deficient == "TRUE",
                                                      "rank-deficient warning", "ordinary or not assessed")), sum)
sing_n <- nrow(singular)
diag_plot <- rbind(
  data.frame(category = paste(geom_counts$status, geom_counts$rank_deficient, sep = "\n"),
             components = geom_counts$components, family = "Legacy core geometry"),
  data.frame(category = "completed with\nsingular warning", components = sing_n,
             family = "Protected v2 sensitivity")
)
pS6 <- ggplot(diag_plot, aes(components, reorder(category, components), fill = family)) +
  geom_col(width = .68) + geom_text(aes(label = components), hjust = -0.15, size = 3) +
  scale_fill_manual(values = c("Legacy core geometry" = blue, "Protected v2 sensitivity" = gold),
                    name = NULL) +
  scale_x_continuous(expand = expansion(mult = c(0, .12))) +
  labs(title = "Completion and warning states remain visible",
       x = "Released components", y = NULL,
       caption = cap("Warnings are diagnostic states, not automatically invalid coefficient estimates.")) +
  theme_mer(9.5)
save_plot(pS6, "Figure_S6_diagnostics_v3", 7.2, 4.8)

# -------------------------------------------------------------------------
# Temporal coverage table and map-support data used by figures.
# -------------------------------------------------------------------------

ry <- region_year[region_year$region %in% c("SoG", "WCVI") &
                    ((region_year$region == "SoG" & num(region_year$year) >= 2005) |
                     (region_year$region == "WCVI" & num(region_year$year) >= 2015)), ]
write_csv(ry, out_path("tables_v3", "Table_S_temporal_sampling_support_v3.csv"))

message("Built MER v3 descriptive tables and ggplot2 figures from tracked aggregate outputs only.")
