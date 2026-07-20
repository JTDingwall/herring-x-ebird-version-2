suppressPackageStartupMessages({
  library(data.table)
  library(jsonlite)
  library(yaml)
})

out_dir <- "outputs/stage2_design_lock"
support <- fread(file.path(out_dir, "species_support_summary.csv"), na.strings = c("", "NA"))
taxonomy <- fread(file.path(out_dir, "species_taxonomy_reconciliation.csv"), na.strings = c("", "NA"))
decisions <- fread(file.path(out_dir, "decision_recommendations.csv"), na.strings = c("", "NA"))
complexes <- fread(file.path(out_dir, "event_complex_audit.csv"), na.strings = c("", "NA"))
geometry <- fread(file.path(out_dir, "event_geometry_audit.csv"), na.strings = c("", "NA"))
regions <- fread(file.path(out_dir, "region_period_recommendations.csv"), na.strings = c("", "NA"))
access <- fread(file.path(out_dir, "response_column_access_audit.csv"), na.strings = c("", "NA"))
count_sim <- fread(file.path(out_dir, "count_family_simulation_summary.csv"), na.strings = c("", "NA"))
mult <- fread("metadata/hypothesis_model_multiplicity_registry.csv", na.strings = c("", "NA"))
grid_hash_lines <- readLines("metadata/stage2_candidate_design_grid.sha256", warn = FALSE)
grid_hash <- strsplit(grid_hash_lines[1L], "[[:space:]]+")[[1L]][1L]
grid_time <- sub("^# frozen_at_utc: ", "", grid_hash_lines[2L])
prospective_hash <- strsplit(readLines("metadata/prospective_confirmation_spec.sha256", warn = FALSE)[1L], "[[:space:]]+")[[1L]][1L]
gate <- fromJSON(file.path(out_dir, "stage_gate.json"))

escape_md <- function(x) gsub("\\|", "\\\\|", ifelse(is.na(x), "", as.character(x)))
md_table <- function(x, cols, labels = cols) {
  x <- as.data.table(x)[, ..cols]
  lines <- c(
    paste0("| ", paste(labels, collapse = " | "), " |"),
    paste0("| ", paste(rep("---", length(cols)), collapse = " | "), " |")
  )
  rows <- apply(x, 1L, function(z) paste0("| ", paste(escape_md(z), collapse = " | "), " |"))
  c(lines, rows)
}

html_escape <- function(x) {
  x <- ifelse(is.na(x), "", as.character(x))
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub('"', "&quot;", x, fixed = TRUE)
}
html_table <- function(x, cols, labels = cols, class = "") {
  z <- as.data.table(x)[, ..cols]
  head <- paste0("<tr>", paste0("<th>", html_escape(labels), "</th>", collapse = ""), "</tr>")
  body <- apply(z, 1L, function(r) paste0("<tr>", paste0("<td>", html_escape(r), "</td>", collapse = ""), "</tr>"))
  paste0("<div class='table-wrap'><table class='", class, "'><thead>", head, "</thead><tbody>", paste(body, collapse = ""), "</tbody></table></div>")
}

disposition <- merge(
  taxonomy[, .(analysis_taxon_id, common_name, taxonomy_disposition = recommended_taxonomy_disposition)],
  support[, .(analysis_taxon_id, named_species_recommendation, guild_recommendation, community_recommendation,
              count_recommendation, cooccurrence_recommendation, recommendation_reason)],
  by = "analysis_taxon_id", all = TRUE, sort = FALSE
)
setorder(disposition, common_name)

region_primary <- regions[candidate_start_year == recommended_primary_start_year |
                            (is.na(recommended_primary_start_year) & candidate_start_year == 2005L),
                          .(region, recommended_primary_start_year, recommendation)]
region_primary[, recommended_primary_start_year := as.character(recommended_primary_start_year)]
region_primary[is.na(recommended_primary_start_year), recommended_primary_start_year := "none"]

raw_ebd_columns <- access[record_type == "response_column_access" & dataset == "EBD", column_name]
prohibited <- access[record_type == "prohibited_statistic_check", column_name]
classification <- gate$classification
validation <- gate$validation_status

md <- c(
  "# Stage 2 outcome-blind design lock",
  "",
  paste0("**Stage gate:** `", classification, "`"),
  paste0("**Validation:** `", validation, "`"),
  paste0("**Candidate-grid SHA-256:** `", grid_hash, "`"),
  paste0("**Frozen at:** `", grid_time, "`"),
  "",
  "> SUPPORT_ONLY_NOT_AN_EFFECT_ESTIMATE. Current analyses remain exploratory and estimand-refining until prospective confirmation.",
  "",
  "## Outcome boundary and executive conclusion",
  "",
  "Lay summary: The design choices were frozen before any bird detection or numeric-count value was accessed. This stage measured whether the data can support later analyses; it did not estimate whether birds respond to herring spawning.",
  "",
  paste0("The frozen grid contains 105 options. Its hash was independently verified before support-only outcome access. The exact EBD fields read were: `", paste(raw_ebd_columns, collapse = "`, `"), "`. Comments were not read. All 2026 and later outcomes remained frozen."),
  "",
  paste0("The audit explicitly checked noncomputation of: ", paste(prohibited, collapse = ", "), ". No biological response plot was created and none of the 45 registered herring-bird response models was fitted."),
  "",
  "## Ten design decisions",
  "",
  "Lay summary: Each recommendation is outcome-blind and remains subject to human scientific approval.",
  "",
  md_table(decisions, c("decision_id", "decision", "recommendation", "sensitivity"), c("ID", "Decision", "Recommendation", "Sensitivity")),
  "",
  "## Taxonomy and support disposition for all 58 taxa",
  "",
  "Lay summary: Sparse taxa were retained rather than deleted. Gadwall and Northern Shoveler remain a separate falsification panel.",
  "",
  md_table(disposition, c("common_name", "taxonomy_disposition", "named_species_recommendation", "guild_recommendation", "count_recommendation", "cooccurrence_recommendation"),
           c("Taxon", "Taxonomy", "Named-species role", "Guild role", "Count role", "Co-occurrence role")),
  "",
  "Technical note: The complete pooled support metrics and explicit threshold reasons are in `outputs/stage2_design_lock/species_support_summary.csv`; all 6,090 taxon-by-candidate support rows are in `species_support_by_design_cell.csv`. These are support counts only, never effect estimates.",
  "",
  "## Event-complex recommendation",
  "",
  "Lay summary: Keep the source record immutable. Use the 2 km / 7 day complex as the candidate primary after manual review of its flagged long-span cases; retain 1 km / 3 day and source-record alternatives, with 5 km / 14 day broad sensitivity only.",
  "",
  md_table(complexes, c("definition", "complexes", "members_q90", "members_max", "temporal_span_days_max", "spatial_diameter_km_max", "complexes_over_21_days", "complexes_over_25_km"),
           c("Definition", "Complexes", "Members p90", "Members max", "Max days", "Max km", ">21 days", ">25 km")),
  "",
  "Every source record is retained in the hashed crosswalk. Merges never cross stock-assessment Region; StatisticalArea crossings are flagged. The 100-case generalized map review contains no eBird coordinates.",
  "",
  "## Geometry and quality tiers",
  "",
  "Lay summary: Source-point and observed-Length alongshore geometries remain parallel core design families because they answer different proximity questions. Width and complex-union geometries are sensitivities.",
  "",
  md_table(geometry, c("geometry_definition", "candidate_role", "construction_successes", "construction_failures", "tier_A_records", "tier_B_records", "tier_C_records"),
           c("Geometry", "Role", "Success", "Failure", "Tier A", "Tier B", "Tier C")),
  "",
  "Technical note: EPSG:3005 is mandatory. Missing Length or Width is never inferred. Section polygons and centroids are not event footprints. The complete hashed geometry crosswalk releases snap-distance bands, not exact coordinates. Human review must confirm the provider meaning of shoreline EDGE_TYPE 100 and 150.",
  "",
  "## Regions, periods, protocols, and effort",
  "",
  "Lay summary: Use all BC hierarchically without forcing one coastwide effect. The response-free coverage rule selects 2005 for supported regions; A27 and A2W remain descriptive or hierarchically pooled until their structural support is approved.",
  "",
  md_table(region_primary, c("region", "recommended_primary_start_year", "recommendation"), c("Region", "Primary start", "Role")),
  "",
  "Broad candidate primary: complete Stationary and Traveling checklists, duration 1-360 minutes, Traveling distance at most 10 km, 1-20 observers. Standardized sensitivity: 5-300 minutes, at most 5 km, 1-10 observers. Complete area protocols remain separate.",
  "",
  "## Count tails and likelihood family",
  "",
  "Lay summary: Keep detection separate from positive reported flock size. Use a hurdle lognormal as the candidate primary positive-count family and a hurdle truncated NB2 as a parallel sensitivity; keep high counts in the primary analysis.",
  "",
  "Selection is based only on synthetic recovery, block-held-out log score, calibration, tail behavior, numerical stability, and the one-standard-error rule. `X` is detection-only, lower bounds enter a bounded sensitivity, and ambiguity remains distinct. All simulation rows are labelled SYNTHETIC.",
  "",
  "## Multispecies latent-factor procedure",
  "",
  "No observed biological JSDM/GLLVM was fitted. The future hash-identical detection-first pilot compares 2, 3, 4, and 5 factors plus no-factor and no-pooling comparators. Selection uses held-out predictive score, convergence/posterior geometry, synthetic residual-association recovery, and a one-standard-error rule. No factor count is selected at Stage 2.",
  "",
  "## Behaviour and comment privacy",
  "",
  "Structured behaviour codes may be used only as aggregate supporting evidence with released cells of at least 20. Free-text comments were not read and the comment audit is deferred unless local-only processing, a versioned dictionary, rare-string scanning, and path-leakage tests are approved.",
  "",
  "## Multiplicity and evidence synthesis",
  "",
  "The registry keeps local aggregation, event-time/distance, redistribution, community/co-occurrence, spawn dose, and phenology as separate ecological families. Species estimates remain visible; hierarchical synthesis is primary; Benjamini-Hochberg applies only within coherent species families; no omnibus Holm adjustment spans all 45 models. Diagnostics and falsification do not compete with primary ecological models.",
  "",
  "## Prospective confirmation",
  "",
  paste0("The confirmation specification SHA-256 is `", prospective_hash, "`. All 2026+ outcomes and events are frozen. Evaluation requires complete/versioned eBird and herring releases and unchanged code, species, guilds, geometry, windows, distance functions, and decision thresholds. No refitting or selection may occur before the primary evaluation."),
  "",
  "## QA, privacy, and join cardinality",
  "",
  "Every join declares and tests cardinality. Concurrent event links are additive exposure memberships and never independent checklist rows. Detection, numeric, X, lower-bound, ambiguity, and missingness remain distinct. Missing herring components remain missing, and relative spawn index is never called absolute biomass.",
  "",
  paste0("Validation status: `", validation, "`. Detailed checks are recorded in the stage gate and repository test outputs."),
  "",
  "## Questions requiring human scientific approval",
  "",
  "1. Approve the 58 taxonomy/support dispositions and the nearby-threshold sensitivity policy.",
  "2. Approve 2 km / 7 day as candidate primary after reviewing all flagged long-span cases and the 100-case map packet.",
  "3. Confirm the marine shoreline EDGE_TYPE dictionary and the 2 km candidate snap limit.",
  "4. Approve region-period coverage rules, including descriptive/hierarchical treatment of A27 and A2W.",
  "5. Approve hurdle lognormal primary and truncated NB2 parallel sensitivity before any herring-effect fit.",
  "6. Approve the latent-factor pilot, behaviour-code boundary, multiplicity registry, and signed prospective protocol.",
  "",
  "No Stage 3 model may open or fit until this gate receives human scientific approval."
)
writeLines(md, "docs/09_STAGE2_OUTCOME_BLIND_DESIGN_LOCK.md", useBytes = TRUE)

css <- "body{font-family:system-ui,-apple-system,Segoe UI,sans-serif;max-width:1180px;margin:0 auto;padding:28px;color:#17221d;line-height:1.48}h1,h2{color:#123d32}h2{border-top:1px solid #ccd8d3;padding-top:22px}.banner{background:#eef7f1;border-left:5px solid #2f7d5b;padding:14px;margin:18px 0}.lay{background:#f7f2df;padding:12px;border-radius:6px}.table-wrap{overflow:auto;margin:12px 0 24px}table{border-collapse:collapse;width:100%;font-size:13px}th,td{border:1px solid #ccd8d3;padding:7px;vertical-align:top}th{background:#e7f0ec;position:sticky;top:0}code{background:#eef1ef;padding:2px 4px}small{color:#53645d}.status{font-weight:700;color:#145a3f}"
sections_html <- c(
  "<h1>Stage 2 outcome-blind design lock</h1>",
  paste0("<div class='banner'><div class='status'>", html_escape(classification), "</div><div>Validation: ", html_escape(validation), "</div><div>Candidate-grid SHA-256: <code>", grid_hash, "</code></div><div>Frozen: ", html_escape(grid_time), "</div><div>SUPPORT_ONLY_NOT_AN_EFFECT_ESTIMATE</div></div>"),
  "<h2>Outcome boundary and executive conclusion</h2><p class='lay'>The design was frozen before any bird detection or numeric-count value was accessed. This stage checks analytical support; it does not estimate a biological response.</p>",
  paste0("<p>Exact EBD fields read: <code>", paste(html_escape(raw_ebd_columns), collapse = "</code>, <code>"), "</code>. Comments were not read, 2026+ outcomes remained frozen, and none of the 45 response models was fitted.</p>"),
  "<h2>Ten design decisions</h2><p class='lay'>All recommendations remain subject to human scientific approval.</p>",
  html_table(decisions, c("decision_id", "decision", "recommendation", "sensitivity"), c("ID", "Decision", "Recommendation", "Sensitivity")),
  "<h2>Taxonomy and support disposition for all 58 taxa</h2><p class='lay'>All taxa remain visible; sparse taxa are retained and the two falsification taxa remain separate.</p>",
  html_table(disposition, c("common_name", "taxonomy_disposition", "named_species_recommendation", "guild_recommendation", "count_recommendation", "cooccurrence_recommendation"), c("Taxon", "Taxonomy", "Named role", "Guild role", "Count role", "Co-occurrence role")),
  "<h2>Event complexes</h2><p class='lay'>Candidate primary: 2 km / 7 day after manual review; source record and 1 km / 3 day remain core alternatives; 5 km / 14 day is broad sensitivity.</p>",
  html_table(complexes, c("definition", "complexes", "members_q90", "members_max", "temporal_span_days_max", "spatial_diameter_km_max", "complexes_over_21_days", "complexes_over_25_km"), c("Definition", "Complexes", "Members p90", "Members max", "Max days", "Max km", ">21 days", ">25 km")),
  "<h2>Geometry and quality</h2><p class='lay'>Source point and observed-Length alongshore footprint are parallel core families. Width and complex unions are sensitivities.</p>",
  html_table(geometry, c("geometry_definition", "candidate_role", "construction_successes", "construction_failures", "tier_A_records", "tier_B_records", "tier_C_records"), c("Geometry", "Role", "Success", "Failure", "Tier A", "Tier B", "Tier C")),
  "<p>EPSG:3005 is mandatory. Missing extents are not inferred. Human review must confirm shoreline EDGE_TYPE 100/150 and the candidate 2 km snap limit.</p>",
  "<h2>Regions, periods, protocol, and effort</h2><p class='lay'>All BC is retained hierarchically without forcing one pooled coastwide effect.</p>",
  html_table(region_primary, c("region", "recommended_primary_start_year", "recommendation"), c("Region", "Primary start", "Role")),
  "<p>Broad primary candidate: complete Stationary/Traveling, 1-360 minutes, Traveling ≤10 km, 1-20 observers. Standardized sensitivity: 5-300 minutes, ≤5 km, 1-10 observers. Complete area remains separate.</p>",
  "<h2>Count-family simulation</h2><p class='lay'>Detection remains separate. Hurdle lognormal is candidate primary for positive counts; truncated NB2 is parallel sensitivity. High counts stay in the primary analysis.</p><p>All simulation evidence is synthetic and uses no herring-effect term.</p>",
  "<h2>Latent-factor procedure</h2><p class='lay'>No biological community model was fitted and no factor count was selected.</p><p>The hash-identical future pilot compares 2-5 factors plus no-factor and no-pooling comparators using predictive score, geometry/convergence, synthetic recovery, and a one-standard-error rule.</p>",
  "<h2>Behaviour/comments, multiplicity, and confirmation</h2><p class='lay'>Structured codes may support aggregate cells ≥20. Comments were not read. Evidence families remain separate, and the 2026+ holdout remains frozen.</p>",
  paste0("<p>Prospective specification SHA-256: <code>", prospective_hash, "</code>. BH applies only within coherent species families; there is no omnibus Holm correction over 45 models.</p>"),
  "<h2>Human approval questions</h2><ol><li>Taxonomy/support dispositions and thresholds.</li><li>2 km / 7 day complex after map review.</li><li>Shoreline classes and snap limit.</li><li>Region-period criteria, including A27/A2W handling.</li><li>Count family and latent pilot.</li><li>Behaviour privacy, multiplicity, and prospective protocol.</li></ol>",
  "<div class='banner'>Stop here. Do not open or fit a Version 2 herring-bird response model before human scientific approval.</div>"
)
html <- paste0("<!doctype html><html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>Stage 2 outcome-blind design lock</title><style>", css, "</style></head><body>", paste(sections_html, collapse = "\n"), "</body></html>")
writeLines(html, "reports/stage2_outcome_blind_design_lock.html", useBytes = TRUE)

cases <- fread(file.path(out_dir, "event_complex_map_review_cases.csv"), na.strings = c("", "NA"))
xx <- cases$generalized_easting_10km; yy <- cases$generalized_northing_10km
sx <- ifelse(is.finite(xx), 30 + 920 * (xx - min(xx, na.rm = TRUE)) / max(1, diff(range(xx, na.rm = TRUE))), NA)
sy <- ifelse(is.finite(yy), 620 - 570 * (yy - min(yy, na.rm = TRUE)) / max(1, diff(range(yy, na.rm = TRUE))), NA)
cols <- c(source_record = "#6b7f78", complex_1km_3d = "#2f7d5b", complex_2km_7d = "#d08c32", complex_5km_14d = "#8b4f78")
circles <- paste0("<circle cx='", round(sx, 1), "' cy='", round(sy, 1), "' r='4' fill='", unname(cols[cases$definition]), "' opacity='.65'><title>", html_escape(cases$definition), " | ", html_escape(cases$complex_id), " | members ", cases$source_records, "</title></circle>")
map_html <- paste0("<!doctype html><html><head><meta charset='utf-8'><title>Stage 2 event-complex generalized map review</title><style>", css, "svg{width:100%;height:auto;background:#eef3f0;border:1px solid #bccbc5}</style></head><body><h1>Stage 2 event-complex generalized map review</h1><div class='banner'>Herring metadata only. Generalized 10 km coordinates. No eBird checklist coordinates.</div><svg viewBox='0 0 980 650' role='img' aria-label='Generalized herring complex review locations'>", paste(circles[is.finite(sx) & is.finite(sy)], collapse = ""), "</svg>", html_table(cases, c("definition", "complex_id", "source_records", "region", "temporal_span_days", "spatial_bbox_diameter_km", "generalized_easting_10km", "generalized_northing_10km"), c("Definition", "Hashed complex", "Records", "Region", "Days", "BBox km", "Easting 10km", "Northing 10km")), "</body></html>")
writeLines(map_html, "reports/stage2_event_map_review.html", useBytes = TRUE)

cat("Stage 2 Markdown, main HTML, and generalized map-review HTML written.\n")
