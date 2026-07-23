#!/usr/bin/env Rscript
# Phase 1 read-only diagnostics over the frozen protected inputs.
#
# Reads only the same protected inputs the event-study fit consumes, computes
# privacy-safe aggregates (suppression threshold 20 applied to released counts),
# and writes CSV artifacts under diagnostics/. It refits nothing, changes no
# frozen output, and writes no row-level protected value.
#
# Covers D3 (X / non-numeric selection), D4 (multi-cell occupancy + VIF),
# D5 (per-species support and prevalence), D6 (travelling boundary exposure),
# D7 (annual detection counts for the split-affected gulls), and records the
# frame-subset resolution for the reconciliation.

suppressPackageStartupMessages(library(data.table))

SCRATCH <- Sys.getenv(
  "MER_DIAG_SCRATCH",
  file.path(tempdir(), "mer_v7_diag")
)
dir.create(SCRATCH, recursive = TRUE, showWarnings = FALSE)
dir.create("diagnostics", showWarnings = FALSE)
THRESH <- 20L

# Portable pure-R gunzip: fread's gzip handling shells out and is flaky on
# Windows. Decompress to a session-local scratch file, read, then remove it.
read_protected <- function(gz) {
  out <- file.path(SCRATCH, sub("\\.gz$", "", basename(gz)))
  con <- gzfile(gz, "rb"); on.exit(close(con), add = TRUE)
  oc <- file(out, "wb")
  repeat {
    b <- readBin(con, "raw", 8e7)
    if (length(b) == 0L) break
    writeBin(b, oc)
  }
  close(oc)
  dt <- fread(out, showProgress = FALSE)
  unlink(out)
  dt
}

supp <- function(x) ifelse(x < THRESH, NA_integer_, as.integer(x))

PROT <- "data/derived/stage4a_protected"
LINKP <- "data/derived/stage3_phase2_protected/metadata_source_point_links.tsv.gz"

frame_all <- read_protected(file.path(PROT, "stage4a_event_metadata.tsv.gz"))
links <- read_protected(LINKP)
states <- read_protected(file.path(PROT, "stage4a_reported_states.tsv.gz"))

# The modeled population is the SoG, 2005-2025 subset of the frame: 217,200
# checklists (R/post_stage4a_sog_event_study_v1.R lines 665-671). Restrict every
# diagnostic to exactly that set so denominators match the fitted models.
frame <- frame_all[region == "SoG" & checklist_year >= 2005 & checklist_year <= 2025]
stopifnot(nrow(frame) == 217200L)
elig <- frame$analysis_event_token

# taxon id -> common name, from the released (non-protected) effect estimates
eff <- fread("outputs/post_stage4a_sog_event_study_v1/effect_estimates_v1.csv",
             showProgress = FALSE)
taxmap <- unique(eff[, .(analysis_taxon_id, unit_label)])

# ---- restrict links and states to the modeled population ----
links <- links[analysis_event_token %in% elig]
states <- states[analysis_event_token %in% elig]
links[, period := fifelse(event_day >= -28 & event_day <= -15, "baseline",
              fifelse(event_day >= -14 & event_day <= -8,  "early_pre",
              fifelse(event_day >= -7  & event_day <= -1,  "immediate_pre",
              fifelse(event_day >= 0   & event_day <= 3,   "spawn_start",
              fifelse(event_day >= 4   & event_day <= 14,  "early_egg",
              fifelse(event_day >= 15  & event_day <= 28,  "late_egg", NA_character_))))))]
links[, zone := fifelse(distance_km < 5, "near",
              fifelse(distance_km >= 5 & distance_km <= 20, "reference", NA_character_))]
modeled <- links[!is.na(period) & !is.na(zone)]

# ---- frame-subset resolution: which 217,200 does the manuscript mean? ----
tok_modeled <- unique(modeled$analysis_event_token)
frame_resolution <- data.table(
  quantity = c("event_metadata rows (full file)",
               "SoG, 2005-2025 modeled population (= manuscript n)",
               "of which: checklists with >=1 modeled-period-and-zone link",
               "of which: checklists with no modeled-window link (all-zero exposure)",
               "manuscript eligible_checklists"),
  value = c(nrow(frame_all), nrow(frame), length(tok_modeled),
            nrow(frame) - length(tok_modeled), 217200L)
)
fwrite(frame_resolution, "diagnostics/D12_frame_resolution.csv")

# ---- build 12-cell link-count matrix per checklist (D4) ----
cell <- modeled[, .(n = .N), by = .(analysis_event_token, period, zone)]
cell[, cellname := paste(period, zone, sep = "_")]
wide <- dcast(cell, analysis_event_token ~ cellname, value.var = "n", fill = 0)
cellcols <- setdiff(names(wide), "analysis_event_token")
periods6 <- c("baseline","early_pre","immediate_pre","spawn_start","early_egg","late_egg")
want <- as.vector(outer(periods6, c("near","reference"), paste, sep = "_"))
for (w in want) if (!w %in% names(wide)) wide[, (w) := 0L]
setcolorder(wide, c("analysis_event_token", want))
M <- as.matrix(wide[, ..want])

# D4a: occupancy distribution
occ <- rowSums(M > 0)
occ_tab <- as.data.table(table(occupancy = occ))
setnames(occ_tab, c("cells_occupied", "checklists"))
occ_tab[, checklists := supp(as.integer(checklists))]
fwrite(occ_tab, "diagnostics/D4_occupancy_distribution.csv")

# D4b: baseline-and-active co-occupancy
base_cols <- c("baseline_near", "baseline_reference")
active_cols <- c("spawn_start_near","spawn_start_reference","early_egg_near","early_egg_reference")
in_base <- rowSums(M[, base_cols, drop = FALSE]) > 0
in_active <- rowSums(M[, active_cols, drop = FALSE]) > 0
co <- data.table(
  quantity = c("checklists in >=1 baseline cell",
               "checklists in >=1 active cell",
               "checklists in baseline AND active (via different events)",
               "total checklists with modeled exposure"),
  count = c(sum(in_base), sum(in_active), sum(in_base & in_active), nrow(M))
)
co[, fraction_of_modeled := round(count / nrow(M), 4)]
co[, count := supp(count)]
fwrite(co, "diagnostics/D4_baseline_active_cooccupancy.csv")

# D4c: correlation + VIF of the 12 count predictors
cormat <- cor(M)
fwrite(as.data.table(round(cormat, 3), keep.rownames = "cell"),
       "diagnostics/D4_predictor_correlation.csv")
vif <- sapply(seq_len(ncol(M)), function(j) {
  r2 <- summary(lm(M[, j] ~ M[, -j]))$r.squared
  1 / (1 - r2)
})
fwrite(data.table(cell = colnames(M), VIF = round(vif, 2)),
       "diagnostics/D4_predictor_vif.csv")

# ---- checklist zone membership for D3 and D6 ----
memb <- unique(modeled[, .(analysis_event_token, period, zone)])
memb[, active := period %in% c("spawn_start", "early_egg")]
memb[, base := period == "baseline"]
by_tok <- memb[, .(
  near_base = any(zone == "near" & base),
  near_active = any(zone == "near" & active),
  ref_base = any(zone == "reference" & base),
  ref_active = any(zone == "reference" & active),
  any_near = any(zone == "near"),
  any_ref = any(zone == "reference")
), by = analysis_event_token]

# ---- D6: travelling-checklist boundary exposure ----
fr <- frame[, .(analysis_event_token, protocol, effort_distance_km)]
d6base <- merge(by_tok, fr, by = "analysis_event_token")
d6 <- rbindlist(lapply(c("any_near", "any_ref"), function(zc) {
  sub <- d6base[get(zc) == TRUE]
  n <- nrow(sub)
  trav <- sub[protocol == "traveling"]
  data.table(
    zone = ifelse(zc == "any_near", "near", "reference"),
    checklists = supp(n),
    traveling = supp(nrow(trav)),
    frac_traveling = round(nrow(trav) / n, 3),
    frac_travel_gt_1km = round(sum(trav$effort_distance_km > 1) / n, 3),
    frac_travel_gt_2p5km = round(sum(trav$effort_distance_km > 2.5) / n, 3),
    frac_travel_gt_4km = round(sum(trav$effort_distance_km > 4) / n, 3)
  )
}))
fwrite(d6, "diagnostics/D6_travelling_boundary_exposure.csv")

# ---- D3: non-numeric / X detection selection by zone x period stratum ----
states[, numeric_ok := is.finite(numeric_count) & numeric_count > 0]
det <- states[detection == 1]
# X specifically, if count_type marks it; otherwise "non-numeric" = detection
# without a usable positive count (the exact exclusion the count model applies).
ct <- tolower(as.character(det$count_type))
det[, is_X := grepl("^x$|unquantified|present", ct)]
det[, is_nonnumeric := !numeric_ok]
strata <- list(
  near_base = by_tok[near_base == TRUE, analysis_event_token],
  near_active = by_tok[near_active == TRUE, analysis_event_token],
  ref_base = by_tok[ref_base == TRUE, analysis_event_token],
  ref_active = by_tok[ref_active == TRUE, analysis_event_token]
)
d3rows <- rbindlist(lapply(names(strata), function(s) {
  sub <- det[analysis_event_token %in% strata[[s]]]
  g <- sub[, .(
    detections = .N,
    n_X = sum(is_X),
    n_nonnumeric = sum(is_nonnumeric)
  ), by = analysis_taxon_id]
  g[, stratum := s]
  g
}))
d3rows <- merge(d3rows, taxmap, by = "analysis_taxon_id", all.x = TRUE)
d3rows[, frac_nonnumeric := round(n_nonnumeric / detections, 4)]
d3rows[, frac_X := round(n_X / detections, 4)]
d3rows[, detections_rel := supp(detections)]
d3wide <- dcast(d3rows, unit_label + analysis_taxon_id ~ stratum,
                value.var = "frac_nonnumeric")
# DiD of non-numeric fraction, only where all four strata had >=THRESH detections
support <- dcast(d3rows, analysis_taxon_id ~ stratum, value.var = "detections")
setnames(support, setdiff(names(support), "analysis_taxon_id"),
         paste0("n_", setdiff(names(support), "analysis_taxon_id")))
d3wide <- merge(d3wide, support, by = "analysis_taxon_id", all.x = TRUE)
ok <- with(d3wide, pmin(n_near_base, n_near_active, n_ref_base, n_ref_active) >= THRESH)
d3wide[, did_nonnumeric := ifelse(ok,
  round((near_active - near_base) - (ref_active - ref_base), 4), NA_real_)]
setcolorder(d3wide, c("unit_label", "analysis_taxon_id",
  "near_base", "near_active", "ref_base", "ref_active", "did_nonnumeric"))
fwrite(d3wide[order(-abs(did_nonnumeric))],
       "diagnostics/D3_nonnumeric_selection.csv")

# ---- D5: per-species detection prevalence and positive-count support ----
n_frame <- nrow(frame)
d5 <- states[, .(
  detections = sum(detection),
  positive_numeric = sum(numeric_ok)
), by = analysis_taxon_id]
d5 <- merge(d5, taxmap, by = "analysis_taxon_id", all.x = TRUE)
d5[, prevalence := round(detections / n_frame, 5)]
d5[, detections := supp(detections)]
d5[, positive_numeric := supp(positive_numeric)]
setcolorder(d5, c("unit_label", "analysis_taxon_id", "detections",
                  "positive_numeric", "prevalence"))
fwrite(d5[order(-prevalence)], "diagnostics/D5_species_support_prevalence.csv")

# ---- D7: annual detection counts for the split-affected gulls ----
gull_names <- c("American Herring Gull", "Short-billed Gull", "Iceland Gull")
gull_ids <- taxmap[unit_label %in% gull_names]
yr <- frame[, .(analysis_event_token, checklist_year)]
detyr <- merge(states[detection == 1 & analysis_taxon_id %in% gull_ids$analysis_taxon_id],
               yr, by = "analysis_event_token")
detyr <- merge(detyr, taxmap, by = "analysis_taxon_id")
d7 <- detyr[, .(detections = supp(.N)), by = .(unit_label, checklist_year)]
d7 <- dcast(d7, checklist_year ~ unit_label, value.var = "detections")
fwrite(d7[order(checklist_year)], "diagnostics/D7_gull_annual_detection_counts.csv")

cat("MER_V7_PROTECTED_DIAGNOSTICS=PASS\n")
cat("frame rows:", nrow(frame), " modeled checklists:", length(tok_modeled), "\n")
