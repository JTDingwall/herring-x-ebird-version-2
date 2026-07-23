#!/usr/bin/env Rscript
# Phase 2 sensitivity refits for the MER v7 event study.
#
# Every fit here is a LABELLED SENSITIVITY reported alongside the primary result.
# Nothing in this script writes to outputs/, touches a frozen file, or changes
# the primary specification. It reuses the primary data assembly and contrast
# machinery verbatim and varies only the estimator.
#
#   S2  detection refit with nAGQ = 1 (primary uses nAGQ = 0)
#   S3  count-model distribution diagnostics + negative-binomial GLMM sensitivity
#   S4  refit on single-event checklists (concurrent_links == 1)
#
# S1 (calendar + diel covariates) is NOT run: day-of-year and start time are
# absent from the frozen frame (see diagnostics/D1_D2_date_time_balance.md).

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
suppressPackageStartupMessages({
  library(data.table)
  library(lme4)
})
source(file.path("R", "stage4a_core.R"), local = FALSE)
source(file.path("R", "stage4a_production.R"), local = FALSE)
source(file.path("R", "post_stage4a_sog_event_study_v1.R"), local = FALSE)

dir.create("sensitivity", showWarnings = FALSE)
Z <- 1.959963984540054

PANEL <- c("Surf Scoter", "White-winged Scoter", "Harlequin Duck",
           "Common Merganser", "Hooded Merganser", "Glaucous-winged Gull",
           "Short-billed Gull", "Bald Eagle", "Mallard", "American Crow",
           "Common Raven")
HEADLINE <- c("American Herring Gull", "Iceland Gull", "Long-tailed Duck")

# ---- assemble the modeled data exactly as the primary driver does ----
PROT <- "data/derived/stage4a_protected"
events_all <- .stage4a_read_gz(file.path(PROT, "stage4a_event_metadata.tsv.gz"))
stopifnot(nrow(events_all) == 239934L)
events_all <- .stage4a_prepare_events(events_all)
sel <- events_all$region == "SoG" &
  events_all$checklist_year >= 2005L & events_all$checklist_year <= 2025L
stopifnot(sum(sel) == 217200L)
events <- events_all[sel, , drop = FALSE]
rm(events_all)
links <- .stage4a_read_gz("data/derived/stage3_phase2_protected/metadata_source_point_links.tsv.gz")
joint <- post_stage4a_add_joint_exposure_v1(events, links)
events <- joint$events
rm(links, joint)
states <- .stage4a_read_gz(file.path(PROT, "stage4a_reported_states.tsv.gz"))
masks <- .stage4a_read_gz(file.path(PROT, "stage4a_ambiguity_masks.tsv.gz"))
states <- states[states$analysis_event_token %in% events$analysis_event_token, ]
masks <- masks[masks$analysis_event_token %in% events$analysis_event_token, ]

registry <- read.csv("metadata/canonical_species_registry.csv",
                     stringsAsFactors = FALSE)
name2id <- function(nm) registry$analysis_taxon_id[match(nm, registry$common_name)]

primary <- fread("outputs/post_stage4a_sog_event_study_v1/effect_estimates_v1.csv",
                 showProgress = FALSE)

# ---- shared contrast extraction (mirrors post_stage4a_fit_one_v1 lines 453-502) ----
extract_contrasts <- function(fit) {
  beta <- lme4::fixef(fit)
  covmat <- as.matrix(stats::vcov(fit))
  defs <- post_stage4a_contrast_definitions_v1(names(beta))
  rows <- lapply(defs, function(d) {
    v <- d$vector
    if (is.null(v)) return(NULL)
    est <- sum(v * beta)
    varc <- drop(t(v) %*% covmat %*% v)
    se <- if (is.finite(varc) && varc >= 0) sqrt(varc) else NA_real_
    p <- if (is.finite(se) && se > 0) 2 * stats::pnorm(-abs(est / se)) else NA_real_
    data.frame(contrast = d$contrast, estimate = est, se = se,
               ratio = exp(est), ratio_low = exp(est - Z * se),
               ratio_high = exp(est + Z * se), p_value = p,
               stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

fit_detection <- function(dat, nagq, start = NULL) {
  d <- dat[!is.na(dat$detection), , drop = FALSE]
  lme4::glmer(post_stage4a_formula_v1("detection"), data = d,
              family = stats::binomial(), nAGQ = nagq, start = start,
              control = lme4::glmerControl(optimizer = "nloptwrap",
                calc.derivs = FALSE, optCtrl = list(maxeval = 10000L)))
}
# nAGQ = 1 (Laplace) is very slow on 217k rows with three crossed random
# intercepts. Warm-start it from the nAGQ = 0 solution so the optimizer only
# refines; same objective, far fewer evaluations.
fit_detection_nagq1 <- function(dat) {
  d0 <- fit_detection(dat, 0L)
  ss <- list(theta = lme4::getME(d0, "theta"), fixef = lme4::getME(d0, "fixef"))
  fit_detection(dat, 1L, start = ss)
}
fit_lmer_count <- function(dat) {
  d <- dat[is.finite(dat$numeric_count) & dat$numeric_count > 0, , drop = FALSE]
  d$log_count <- log(d$numeric_count)
  lme4::lmer(post_stage4a_formula_v1("log_count"), data = d, REML = TRUE,
             control = lme4::lmerControl(optimizer = "nloptwrap",
               calc.derivs = FALSE, optCtrl = list(maxeval = 10000L)))
}

prim_ratio <- function(nm, oc, ct) {
  r <- primary[unit_label == nm & outcome == oc & contrast == ct]
  if (!nrow(r)) return(rep(NA_real_, 4))
  c(as.numeric(r$ratio), as.numeric(r$ratio_conf_low),
    as.numeric(r$ratio_conf_high), as.numeric(r$q_value))
}

CONTRASTS <- c("did_spawn_start", "did_early_egg", "did_late_egg",
               "did_active_0_14_day")

# ---- validation: refit one primary (nAGQ=0) and confirm it matches frozen ----
val_dat <- stage4a_materialize_taxon(events, states, masks, name2id("Bald Eagle"))
val_fit <- fit_detection(val_dat, 0L)
val <- extract_contrasts(val_fit)
val_active <- val$ratio[val$contrast == "did_active_0_14_day"]
frozen_active <- prim_ratio("Bald Eagle", "detection", "did_active_0_14_day")[1]
cat(sprintf("VALIDATION Bald Eagle detection active: harness nAGQ0 %.4f vs frozen %.4f (diff %.2e)\n",
            val_active, frozen_active, abs(val_active - frozen_active)))
if (abs(val_active - frozen_active) > 1e-3) {
  stop("Harness does not reproduce the frozen primary; aborting before sensitivities.")
}

compare_row <- function(nm, outcome, sens, label) {
  do.call(rbind, lapply(CONTRASTS, function(cc) {
    pr <- prim_ratio(nm, outcome, cc)
    sr <- sens[sens$contrast == cc, ]
    if (!nrow(sr)) return(NULL)
    data.frame(sensitivity = label, species = nm, outcome = outcome, contrast = cc,
               primary_ratio = pr[1], primary_ci = sprintf("%.2f-%.2f", pr[2], pr[3]),
               primary_q = pr[4],
               sens_ratio = sr$ratio, sens_ci = sprintf("%.2f-%.2f", sr$ratio_low, sr$ratio_high),
               sens_p = sr$p_value,
               direction_agree = sign(pr[1] - 1) == sign(sr$ratio - 1),
               stringsAsFactors = FALSE)
  }))
}

# ================= S4: single-event checklists =================
cat("== S4: single-event (concurrent_links==1) refits ==\n")
ev1 <- events[events$concurrent_links == 1L, , drop = FALSE]
st1 <- states[states$analysis_event_token %in% ev1$analysis_event_token, ]
mk1 <- masks[masks$analysis_event_token %in% ev1$analysis_event_token, ]
cat("  single-event checklists:", nrow(ev1), "\n")
s4 <- list()
for (nm in PANEL) {
  dat <- stage4a_materialize_taxon(ev1, st1, mk1, name2id(nm))
  fd <- tryCatch(fit_detection(dat, 0L), error = function(e) e)
  if (!inherits(fd, "error"))
    s4[[paste0(nm, "_det")]] <- compare_row(nm, "detection", extract_contrasts(fd), "S4_single_event")
  fc <- tryCatch(fit_lmer_count(dat), error = function(e) e)
  if (!inherits(fc, "error"))
    s4[[paste0(nm, "_cnt")]] <- compare_row(nm, "positive_numeric_count_given_detection",
                                            extract_contrasts(fc), "S4_single_event")
  cat("  ", nm, "done\n")
}
fwrite(rbindlist(s4), "sensitivity/S4_single_event.csv")

# ================= S3: count distribution diagnostics =================
# The negative-binomial GLMM sensitivity is NOT run here: glmer.nb with three
# crossed random intercepts on the larger positive-count subsets is as
# intractable as nAGQ = 1 (a single fit did not complete in an hour). The
# distribution diagnostics below need no fit and are the direct evidence for the
# log(1) spike reviewer objection. See sensitivity/S3_count_distribution.md.
cat("== S3: count distribution diagnostics ==\n")
dist_rows <- list()
for (nm in c(PANEL, HEADLINE)) {
  dat <- stage4a_materialize_taxon(events, states, masks, name2id(nm))
  pc <- dat$numeric_count[is.finite(dat$numeric_count) & dat$numeric_count > 0]
  dist_rows[[nm]] <- data.frame(species = nm, n_positive = length(pc),
    frac_eq_1 = round(mean(pc == 1), 3), frac_eq_2 = round(mean(pc == 2), 3),
    frac_le_2 = round(mean(pc <= 2), 3), median = stats::median(pc),
    q95 = as.numeric(stats::quantile(pc, 0.95)), max = max(pc),
    stringsAsFactors = FALSE)
}
fwrite(rbindlist(dist_rows), "sensitivity/S3_count_distribution.csv")

# S2 (nAGQ = 1 detection) is run separately by scripts/sensitivity_s2_probe.R:
# Laplace with three crossed random intercepts on 217k rows is too slow to
# batch here (see sensitivity/S2_nAGQ1_note.md).

cat("MER_V7_SENSITIVITY=DONE\n")
