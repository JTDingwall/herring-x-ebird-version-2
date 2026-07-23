#!/usr/bin/env Rscript
# S2 single-species probe: nAGQ = 1 (Laplace) detection refit for one rare gull,
# warm-started from nAGQ = 0. Batching all 14 species is computationally
# impractical in the frozen environment (Laplace with three crossed random
# intercepts on 217,200 rows is >10 min per fit even warm-started, and no faster
# Laplace engine such as glmmTMB is available). This runs the single most
# important rare-gull effect to completion as a decisive check.

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
suppressPackageStartupMessages({ library(data.table); library(lme4) })
source("R/stage4a_core.R"); source("R/stage4a_production.R")
source("R/post_stage4a_sog_event_study_v1.R")
Z <- 1.959963984540054
SPECIES <- Sys.getenv("S2_SPECIES", "Iceland Gull")

PROT <- "data/derived/stage4a_protected"
ev <- .stage4a_prepare_events(.stage4a_read_gz(file.path(PROT, "stage4a_event_metadata.tsv.gz")))
ev <- ev[ev$region == "SoG" & ev$checklist_year >= 2005 & ev$checklist_year <= 2025, , drop = FALSE]
lk <- .stage4a_read_gz("data/derived/stage3_phase2_protected/metadata_source_point_links.tsv.gz")
ev <- post_stage4a_add_joint_exposure_v1(ev, lk)$events; rm(lk)
st <- .stage4a_read_gz(file.path(PROT, "stage4a_reported_states.tsv.gz"))
mk <- .stage4a_read_gz(file.path(PROT, "stage4a_ambiguity_masks.tsv.gz"))
st <- st[st$analysis_event_token %in% ev$analysis_event_token, ]
mk <- mk[mk$analysis_event_token %in% ev$analysis_event_token, ]
reg <- read.csv("metadata/canonical_species_registry.csv", stringsAsFactors = FALSE)
primary <- fread("outputs/post_stage4a_sog_event_study_v1/effect_estimates_v1.csv", showProgress = FALSE)

id <- reg$analysis_taxon_id[match(SPECIES, reg$common_name)]
dat <- stage4a_materialize_taxon(ev, st, mk, id)
d <- dat[!is.na(dat$detection), , drop = FALSE]
ctrl <- lme4::glmerControl(optimizer = "nloptwrap", calc.derivs = FALSE,
                           optCtrl = list(maxeval = 10000L))
f <- post_stage4a_formula_v1("detection")

t0 <- proc.time()[["elapsed"]]
d0 <- lme4::glmer(f, data = d, family = binomial(), nAGQ = 0L, control = ctrl)
cat(sprintf("nAGQ=0 done (%.0fs)\n", proc.time()[["elapsed"]] - t0)); flush.console()
ss <- list(theta = lme4::getME(d0, "theta"), fixef = lme4::getME(d0, "fixef"))
t1 <- proc.time()[["elapsed"]]
d1 <- lme4::glmer(f, data = d, family = binomial(), nAGQ = 1L, start = ss, control = ctrl)
cat(sprintf("nAGQ=1 done (%.0fs)\n", proc.time()[["elapsed"]] - t1)); flush.console()

extract <- function(fit) {
  beta <- lme4::fixef(fit); covmat <- as.matrix(stats::vcov(fit))
  defs <- post_stage4a_contrast_definitions_v1(names(beta))
  do.call(rbind, lapply(defs, function(dd) {
    v <- dd$vector; if (is.null(v)) return(NULL)
    est <- sum(v * beta); se <- sqrt(drop(t(v) %*% covmat %*% v))
    data.frame(contrast = dd$contrast, ratio = exp(est),
               low = exp(est - Z * se), high = exp(est + Z * se),
               p = 2 * stats::pnorm(-abs(est / se)), stringsAsFactors = FALSE)
  }))
}
e0 <- extract(d0); e1 <- extract(d1)
keep <- c("did_spawn_start", "did_early_egg", "did_late_egg", "did_active_0_14_day")
out <- do.call(rbind, lapply(keep, function(cc) {
  pr <- primary[unit_label == SPECIES & outcome == "detection" & contrast == cc]
  r0 <- e0[e0$contrast == cc, ]; r1 <- e1[e1$contrast == cc, ]
  data.frame(species = SPECIES, contrast = cc,
             primary_nAGQ0 = as.numeric(pr$ratio),
             harness_nAGQ0 = r0$ratio, harness_nAGQ1 = r1$ratio,
             nAGQ1_ci = sprintf("%.2f-%.2f", r1$low, r1$high),
             nAGQ1_p = r1$p, stringsAsFactors = FALSE)
}))
fwrite(out, sprintf("sensitivity/S2_probe_%s.csv", gsub(" ", "_", SPECIES)))
print(out)
cat("S2_PROBE_DONE\n")
