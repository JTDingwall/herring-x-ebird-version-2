suppressPackageStartupMessages({
  library(data.table)
  library(jsonlite)
  library(yaml)
})

out_dir <- "outputs/stage2_design_lock"
read_artifact <- function(name) fread(file.path(out_dir, name), na.strings = c("", "NA"))
support <- read_artifact("species_support_summary.csv")
taxonomy <- read_artifact("species_taxonomy_reconciliation.csv")
decisions <- read_artifact("decision_recommendations.csv")
complexes <- read_artifact("event_complex_audit.csv")
geometry <- read_artifact("event_geometry_audit.csv")
geometry_region <- read_artifact("event_geometry_region_diagnostics.csv")
geometry_eligibility <- read_artifact("geometry_representation_eligibility.csv")
regions <- read_artifact("region_period_recommendations.csv")
membership <- read_artifact("ebd_sed_membership_audit.csv")
protocol <- read_artifact("protocol_effort_amendment.csv")
shared <- read_artifact("shared_checklist_aggregate_audit.csv")
access <- read_artifact("response_column_access_audit.csv")
mult <- fread("metadata/hypothesis_model_multiplicity_registry.csv", na.strings = c("", "NA"))
gate <- fromJSON(file.path(out_dir, "stage_gate.json"))
prospective <- read_yaml("metadata/prospective_confirmation_spec.yml")

hash_value <- function(path) strsplit(readLines(path, warn = FALSE)[1L], "[[:space:]]+")[[1L]][1L]
grid_hash_lines <- readLines("metadata/stage2_candidate_design_grid.sha256", warn = FALSE)
grid_hash <- hash_value("metadata/stage2_candidate_design_grid.sha256")
grid_time <- sub("^# frozen_at_utc: ", "", grid_hash_lines[2L])
prior_grid_hash <- sub("^# prior_windows_crlf_sha256: ", "", grid_hash_lines[4L])
amendment_hash <- hash_value("metadata/stage2_scientific_gate_amendment_v1.sha256")
approval_hash <- hash_value("metadata/stage2_human_scientific_approval_v1.sha256")
approval <- read_yaml("metadata/stage2_human_scientific_approval_v1.yml")
authorization_hash <- hash_value("metadata/stage3_phases1_3_authorization_v1.sha256")
authorization <- read_yaml("metadata/stage3_phases1_3_authorization_v1.yml")
prospective_hash <- hash_value("metadata/prospective_confirmation_spec.sha256")

escape_md <- function(x) gsub("\\|", "\\\\|", ifelse(is.na(x), "", as.character(x)))
md_table <- function(x, cols, labels = cols) {
  z <- as.data.table(x)[, ..cols]
  c(paste0("| ", paste(labels, collapse = " | "), " |"),
    paste0("| ", paste(rep("---", length(cols)), collapse = " | "), " |"),
    apply(z, 1L, function(row) paste0("| ", paste(escape_md(row), collapse = " | "), " |")))
}
html_escape <- function(x) {
  x <- ifelse(is.na(x), "", as.character(x))
  x <- gsub("&", "&amp;", x, fixed = TRUE); x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE); gsub('"', "&quot;", x, fixed = TRUE)
}
html_table <- function(x, cols, labels = cols) {
  z <- as.data.table(x)[, ..cols]
  head <- paste0("<tr>", paste0("<th>", html_escape(labels), "</th>", collapse = ""), "</tr>")
  body <- apply(z, 1L, function(row) paste0("<tr>", paste0("<td>", html_escape(row), "</td>", collapse = ""), "</tr>"))
  paste0("<div class='table-wrap'><table><thead>", head, "</thead><tbody>", paste(body, collapse = ""), "</tbody></table></div>")
}

disposition <- merge(
  taxonomy[, .(analysis_taxon_id, common_name, taxonomy_disposition = recommended_taxonomy_disposition)],
  support[, .(analysis_taxon_id, named_species_recommendation, guild_recommendation,
              count_recommendation, cooccurrence_recommendation)],
  by = "analysis_taxon_id", all = TRUE, sort = FALSE)
setorder(disposition, common_name)
region_primary <- regions[recommendation == "candidate_primary_period" |
                            (candidate_start_year == 2005L & !region %in% c("SoG", "WCVI")),
                          .(region, candidate_start_year, passing_years, years_assessed,
                            maximum_consecutive_failing_years, recommendation)]
setorder(region_primary, region)
raw_ebd_columns <- access[record_type == "response_column_access" & dataset == "EBD", column_name]
prohibited <- access[record_type == "prohibited_statistic_check", column_name]
latent <- mult[model_id %in% c("M21", "M35"),
               .(model_id, model_role, latent_pilot_choice_group, independent_evidence_object_count)]

md <- c(
  "# Stage 2 outcome-blind design lock — scientific-gate repair report", "",
  paste0("**Stage gate:** `", gate$classification, "`"),
  paste0("**Human scientific decision:** `", gate$human_scientific_decision, "`"),
  paste0("**Validation:** `", gate$validation_status, "`"), "",
  "> SUPPORT_ONLY_NOT_AN_EFFECT_ESTIMATE. Current analyses remain exploratory and estimand-refining until prospective confirmation.", "",
  "## Executive conclusion", "",
  "Human scientific authorization permits Stage 3 Phases 1–3 only. Immutable source points are the only registered analysis geometry. Shoreline classes and derived alongshore geometry remain audit provenance only and are not registered sensitivities. Response summaries, response models, Phase 4, and the 2026–2028 holdout remain unauthorized.", "",
  "No herring–bird response model was fitted. No exposure-specific bird summary, contrast, coefficient, p-value, interval, posterior summary, spawn-phase co-occurrence change, or biological response plot was calculated or displayed. Free-text comments were not read.", "",
  "## Design freeze and amendment chain", "",
  paste0("The original candidate grid remains unchanged: canonical-LF SHA-256 `", grid_hash,
         "`, original Windows-CRLF SHA-256 `", prior_grid_hash, "`, frozen `", grid_time,
         "`. The scientific-gate amendment SHA-256 is `", amendment_hash,
         "`; the human-approval record SHA-256 is `", approval_hash,
         "`; the Stage 3 Phases 1–3 authorization SHA-256 is `", authorization_hash,
         "`; the prospective specification SHA-256 is `", prospective_hash, "`."), "",
  "The candidate grid was frozen and hashed before any species detection or numeric-count values were read. The repair amendment preserves those original timestamps and hashes and records its implementation-only YAML correction history.", "",
  "## Repair resolution 1 — EBD/SED membership and zero filling", "",
  md_table(membership, c("ebd_rows", "ebd_unique_keys", "sed_unique_keys", "ebd_keys_unmatched_to_sed",
                         "sed_keys_without_ebd", "sed_only_1988_2025", "sed_only_2026_plus",
                         "primary_zero_fill_eligible", "scientific_treatment"),
           c("EBD rows", "EBD keys", "SED keys", "EBD-only", "SED-only", "SED-only ≤2025",
             "SED-only ≥2026", "Primary zero-fill", "Treatment")), "",
  "SED-only checklists are structural unknowns, never observed absences. They are excluded from primary zero filling and retained only for an explicit non-zero-filled eligibility sensitivity.", "",
  "## Repair resolution 2 — shoreline and actual geometry", "",
  md_table(geometry, c("geometry_definition", "candidate_role", "all_available_records", "common_eligible_records",
                       "edge100_snap_q50_m", "edge100_snap_q90_m", "edge100_snap_over_2km",
                       "actual_alongshore_geometry_verified", "geometry_gate"),
           c("Geometry", "Role", "Available", "Common set", "EDGE100 median m", "EDGE100 p90 m",
             ">2 km", "Actual line built", "Gate")), "",
  md_table(geometry_region, c("region", "valid_source_points", "inside_bundle_bbox_share", "edge100_snap_q50_km",
                              "edge100_snap_over_2km", "core_eligible", "bundle_coverage_status"),
           c("Region", "Valid source points", "Inside-bundle share", "Median snap km", ">2 km", "Core eligible", "Coverage")), "",
  md_table(geometry_eligibility, c("representation", "comparison_sample", "eligible_events", "comparison_interpretation"),
           c("Representation", "Sample", "Eligible events", "Interpretation")), "",
  "The human-approved primary representation is the immutable source point, available for 13,208 source records. EDGE_TYPE 100, EDGE_TYPE 150 and derived alongshore geometry are retained only as audit provenance. No shoreline or alongshore sensitivity is registered. Large snap distances continue to document the incomplete bundle but have no analysis role.", "",
  "## Repair resolution 3 — event complexes and review packet", "",
  md_table(complexes, c("definition", "complexes", "members_max", "temporal_span_days_max", "spatial_diameter_km_max",
                        "complexes_over_21_days", "complexes_over_25_km", "review_packet_rows", "candidate_role"),
           c("Definition", "Complexes", "Members max", "Max days", "Max km", ">21 days", ">25 km", "Flagged", "Role")), "",
  "The immutable source record is the safe primary. The original 2 km / 7 day connected-component rule remains provisional because chaining produces two complexes over 21 days, including a 66-day maximum. The deterministic anti-chain sensitivity caps temporal span at 21 days and spatial diameter at 25 km without crossing Region. Every flagged complex—not a sample—is included in the generalized review packet.", "",
  "## Repair resolution 4 — sustained region-year support", "",
  md_table(region_primary, c("region", "candidate_start_year", "passing_years", "years_assessed",
                             "maximum_consecutive_failing_years", "recommendation"),
           c("Region", "Start", "Passing years", "Assessed years", "Max fail run", "Role")), "",
  "The response-free sustained rule supports SoG from 2005 and WCVI from 2015. All other regions, including A27 and A2W, remain descriptive or hierarchical-only because no candidate start passes the frozen year-by-year rule.", "",
  "## Repair resolution 5 — protocol, effort, and shared checklists", "",
  md_table(protocol, c("definition", "protocols", "duration_minutes", "traveling_distance_km_max", "observers", "candidate_role"),
           c("Definition", "Protocols", "Minutes", "Travel km max", "Observers", "Role")), "",
  md_table(shared, c("source_rows", "analysis_checklists", "shared_analysis_checklists", "disagreement_groups",
                     "disagreement_groups_with_ebd", "wholly_sed_only_analysis_groups", "primary_analysis_checklists",
                     "observer_effect_rule", "disagreement_primary_rule"),
           c("Source rows", "Analysis checklists", "Shared", "Disagreements", "Disagreements with EBD",
             "Wholly SED-only", "Primary", "Observer rule", "Primary rule")), "",
  "Standardized complete Stationary/Traveling effort is primary; broader effort is a sensitivity and Complete Area remains separate. Shared groups use a composite observer cluster. Effort-disagreement groups are excluded from the primary and retained as a registered sensitivity with fieldwise ranges and missing consensus values.", "",
  "## Repair resolution 6 — registry and specificity panel", "",
  md_table(latent, c("model_id", "model_role", "latent_pilot_choice_group", "independent_evidence_object_count"),
           c("Model", "Role", "Choice group", "Evidence objects")), "",
  "M21 and M35 are mutually exclusive primary alternatives selected by one detection-first latent pilot and contribute one evidence object, not two. Gadwall and Northern Shoveler are a specificity/falsification panel; they are not asserted to be guaranteed biological nonresponders. All 45 models remain registered and unfitted.", "",
  "## Repair resolution 7 — prospective integrity", "",
  paste0("The confirmation horizon is fixed at complete ", prospective$prospective_horizon$start_year, "–",
         prospective$prospective_horizon$end_year, " releases, with one evaluation after the complete horizon, no interim response looks, and no early stopping. The prior mechanical scan is disclosed. The precise claim is: `",
         prospective$development_access_statement$current_claim, "`. Repaired extraction filters observation date before selecting or persisting response fields."), "",
  "## Repair resolution 8 — bookkeeping, QA, and privacy", "",
  "The parent successful GitHub Actions reference is run #10; run #9 is explicitly superseded as incorrect. The substantive repair commit passed GitHub Actions run #15 (run ID 29761640213). Every join declares and tests cardinality. Concurrent event memberships remain additive exposure links and never duplicate checklists as independent rows. Detection, numeric, X, lower-bound, and ambiguity states remain distinct; missing herring components are not zero and relative spawn index is not absolute biomass.", "",
  paste0("The response-access audit lists these EBD fields: `", paste(raw_ebd_columns, collapse = "`, `"), "`. It asserts noncomputation of: ", paste(prohibited, collapse = ", "), "."), "",
  "## Taxonomy and outcome-blind support dispositions", "",
  md_table(disposition, c("common_name", "taxonomy_disposition", "named_species_recommendation", "guild_recommendation",
                          "count_recommendation", "cooccurrence_recommendation"),
           c("Taxon", "Taxonomy", "Named role", "Guild role", "Count role", "Co-occurrence role")), "",
  "## Stage 3 Phases 1–3 authorization and next gate", "",
  paste0("Authorization record `", authorization$authorization_version, "` permits checklist-denominator construction, metadata-only support auditing and blocked-validation implementation. Its SHA-256 is `", authorization_hash, "`."), "",
  "Source point is the only registered analysis geometry. Shoreline and alongshore products remain audit provenance only.", "",
  "Stop after each authorized phase for its required review. Phase 4, response summaries, response models and 2026–2028 data remain prohibited until a separate explicit authorization."
)
writeLines(md, "docs/09_STAGE2_OUTCOME_BLIND_DESIGN_LOCK.md", useBytes = TRUE)

css <- "body{font-family:system-ui,-apple-system,Segoe UI,sans-serif;max-width:1180px;margin:0 auto;padding:28px;color:#17221d;line-height:1.48}h1,h2{color:#123d32}h2{border-top:1px solid #ccd8d3;padding-top:22px}.banner{background:#edf8f1;border-left:5px solid #267148;padding:14px;margin:18px 0}.lay{background:#f7f2df;padding:12px;border-radius:6px}.table-wrap{overflow:auto;margin:12px 0 24px}table{border-collapse:collapse;width:100%;font-size:13px}th,td{border:1px solid #ccd8d3;padding:7px;vertical-align:top}th{background:#e7f0ec;position:sticky;top:0}code{background:#eef1ef;padding:2px 4px}.status{font-weight:700;color:#225f3d}"
sections <- c(
  "<h1>Stage 2 outcome-blind design lock — repair report</h1>",
  paste0("<div class='banner'><div class='status'>", html_escape(gate$classification), "</div><div>Human decision: ", html_escape(gate$human_scientific_decision), "</div><div>Validation: ", html_escape(gate$validation_status), "</div><div>Grid SHA-256: <code>", grid_hash, "</code></div><div>Amendment SHA-256: <code>", amendment_hash, "</code></div><div>SUPPORT_ONLY_NOT_AN_EFFECT_ESTIMATE</div></div>"),
  "<h2>Executive conclusion</h2><p class='lay'>Stage 3 Phases 1–3 are authorized. Immutable source point is the only registered analysis geometry; shoreline products are audit-only. Response summaries and response models remain unauthorized.</p>",
  "<h2>Ten repaired design decisions</h2>", html_table(decisions, c("decision_id", "decision", "recommendation", "sensitivity"), c("ID", "Decision", "Recommendation", "Sensitivity")),
  "<h2>EBD/SED membership</h2><p>SED-only keys are structural unknowns and are excluded from primary zero filling.</p>", html_table(membership, c("ebd_unique_keys", "sed_unique_keys", "ebd_keys_unmatched_to_sed", "sed_keys_without_ebd", "primary_zero_fill_eligible", "scientific_treatment"), c("EBD keys", "SED keys", "EBD-only", "SED-only", "Zero-fill", "Treatment")),
  "<h2>Approved source-point-only geometry</h2><p>Immutable source point is the only registered analysis geometry. Shoreline and alongshore products are retained only as audit provenance.</p>", html_table(geometry_region, c("region", "valid_source_points", "inside_bundle_bbox_share", "edge100_snap_q50_km", "core_eligible", "bundle_coverage_status"), c("Region", "Valid points", "In extent", "Median snap km", "Core eligible", "Coverage")),
  "<h2>Event complex repair</h2><p>The source record is safe primary; every flagged complex is in the generalized packet.</p>", html_table(complexes, c("definition", "complexes", "temporal_span_days_max", "spatial_diameter_km_max", "review_packet_rows", "candidate_role"), c("Definition", "Complexes", "Max days", "Max km", "Flagged", "Role")),
  "<h2>Region periods</h2><p>SoG passes from 2005 and WCVI from 2015; all other regions are descriptive/hierarchical-only.</p>", html_table(region_primary, c("region", "candidate_start_year", "passing_years", "years_assessed", "maximum_consecutive_failing_years", "recommendation"), c("Region", "Start", "Pass years", "Years", "Max fail run", "Role")),
  "<h2>Protocol and shared-checklist rules</h2>", html_table(protocol, c("definition", "protocols", "duration_minutes", "traveling_distance_km_max", "observers", "candidate_role"), c("Definition", "Protocols", "Minutes", "Travel km", "Observers", "Role")),
  "<h2>Registry and prospective integrity</h2><p>M21/M35 are mutually exclusive and contribute one evidence object. Confirmation occurs once after complete 2026–2028 releases, without interim looks or early stopping.</p>", html_table(latent, c("model_id", "model_role", "latent_pilot_choice_group", "independent_evidence_object_count"), c("Model", "Role", "Choice group", "Evidence objects")),
  "<h2>Taxonomy and support dispositions</h2>", html_table(disposition, c("common_name", "taxonomy_disposition", "named_species_recommendation", "guild_recommendation", "count_recommendation", "cooccurrence_recommendation"), c("Taxon", "Taxonomy", "Named role", "Guild role", "Count role", "Co-occurrence role")),
  paste0("<h2>Stage 3 Phases 1–3 authorization</h2><p>Authorization record <code>", html_escape(authorization$authorization_version), "</code> permits denominator construction, metadata-only support auditing and blocked-validation implementation.</p><ul><li>Source point is the only registered geometry.</li><li>Shoreline products are audit provenance only.</li><li>Response summaries, Phase 4 and response models remain prohibited.</li></ul><div class='banner'>Stop after each authorized phase for human review.</div>")
)
writeLines(paste0("<!doctype html><html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>Stage 2 repair report</title><style>", css, "</style></head><body>", paste(sections, collapse = "\n"), "</body></html>"), "reports/stage2_outcome_blind_design_lock.html", useBytes = TRUE)

cases <- read_artifact("event_complex_map_review_cases.csv")
xx <- cases$generalized_easting_10km; yy <- cases$generalized_northing_10km
sx <- ifelse(is.finite(xx), 30 + 920 * (xx - min(xx, na.rm = TRUE)) / max(1, diff(range(xx, na.rm = TRUE))), NA)
sy <- ifelse(is.finite(yy), 620 - 570 * (yy - min(yy, na.rm = TRUE)) / max(1, diff(range(yy, na.rm = TRUE))), NA)
cols <- c(source_record = "#6b7f78", complex_1km_3d = "#2f7d5b", complex_2km_7d = "#d08c32",
          complex_2km_7d_antichain = "#356f9f", complex_5km_14d = "#8b4f78")
circles <- paste0("<circle cx='", round(sx, 1), "' cy='", round(sy, 1), "' r='3' fill='",
                  unname(cols[cases$definition]), "' opacity='.5'><title>", html_escape(cases$definition), " | ",
                  html_escape(cases$complex_id), " | members ", cases$source_records, " | ", html_escape(cases$review_reason), "</title></circle>")
map_table <- html_table(cases, c("definition", "complex_id", "source_records", "region", "temporal_span_days",
                                 "spatial_bbox_diameter_km", "review_reason", "generalized_easting_10km", "generalized_northing_10km"),
                        c("Definition", "Hashed complex", "Records", "Region", "Days", "BBox km", "Flag", "Easting 10km", "Northing 10km"))
map_html <- paste0("<!doctype html><html><head><meta charset='utf-8'><title>Stage 2 generalized event review</title><style>", css, "svg{width:100%;height:auto;background:#eef3f0;border:1px solid #bccbc5}</style></head><body><h1>All flagged event complexes</h1><div class='banner'>Herring metadata only. Coordinates are generalized to 10 km. No eBird checklist coordinates.</div><svg viewBox='0 0 980 650' role='img' aria-label='Generalized flagged herring complex locations'>", paste(circles[is.finite(sx) & is.finite(sy)], collapse = ""), "</svg>", map_table, "</body></html>")
writeLines(map_html, "reports/stage2_event_map_review.html", useBytes = TRUE)

cat("Stage 2 repaired Markdown, HTML, and all-flagged generalized map report written.\n")
