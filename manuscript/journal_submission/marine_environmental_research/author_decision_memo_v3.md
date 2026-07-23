# Author decision memo (v3)

**Date:** 2026-07-22

**Target:** Marine Environmental Research, Full-length Article

## Manuscript-only corrections

- Corrected the primary M01/M02/M29 baseline from “active versus reference” to **active-near versus omitted other**.
- Reserved active-versus-contemporaneous-reference language for M08 (`beta_active - beta_reference`).
- Corrected the timing description from five windows to six windows with early pre-spawn as the omitted reference.
- Renamed the 28-day `immediate_pre` interval “late pre-spawn” in ecological prose.
- Replaced blanket “mixed model” language for legacy M02/M05/M08/M29 results with “released adjusted coefficients” because the public aggregate does not record the per-component engine after an attempted `bam` fit and permitted fixed-effect fallback.
- Organized predictions as P1–P4 and crosswalked them to the registered H1–H8 framework.
- Led Results with study coverage and raw descriptive support before adjusted coefficients.
- Made individual species primary and guilds complementary.
- Kept current-data claims associational and within the eligible submitted-checklist population.

## New privacy-safe descriptive summaries

- Region totals for eligible checklists, active/reference/other exposure, recorded source events, event blocks, both-period events, observer concentration, and effective replication.
- Region-specific 49-species detection prevalence, complete-checklist nondetections, positive numeric reports, numeric availability, structural unknowns, and fit status.
- Pooled response-free X, ambiguity, flock-size quantile, year, event, observer, location, and concentration support, explicitly labeled as pooled.
- Region-by-guild prevalence and transparent member lists.
- Event-window and distance-ring support with nonexclusive concurrent-link warnings.
- Generalized region-level checklist/event map, broad active/reference support map, and nongeographic exposure schematic.

## Existing adjusted results retained unchanged

- All M02 species coefficients and complete all-species visibility.
- Sparse `M01_PRIMARY_v2` guild reference.
- All M05 event-time coefficients.
- M29 Gadwall and Northern Shoveler specificity values.
- M27/M28 shifted-bundle placebos.
- WCVI 2-km and dominant-observer matched sensitivities.
- All singular, rank-deficient, failed, and non-estimable states.
- Zero-truncated NB2 sensitivity, validation, and compatible-family pooling repair.

No coefficient, standard error, interval, p-value, q-value, sample size, pooling assignment, exclusion decision, fit status, or robustness classification was changed.

## Items requiring protected aggregate authorization

- Region-specific positive-count quartiles and tails.
- Region-specific X/lower-bound/ambiguity summaries.
- Raw taxon detection prevalence and median positive count by active/reference/other class.
- Per-checklist guild richness and guild count distributions.
- Event-date, checklists-per-event, and concurrent-link distributions.
- Fine-grid or hexagonal checklist/event density maps.
- A non-refit `engine_used` release from legacy protected checkpoints.

These items were not approximated and no protected cache was opened.

## Questions reserved for future work

- Formal distance decay and prey-footprint models.
- Redistribution and contemporaneous nonspawn-area declines.
- Spawn intensity, extent, depth, substrate, and local egg availability.
- Community composition and co-occurrence.
- Explicit birder-visitation models.
- Stationary-only and route-level geometry analyses.
- Prospective one-shot confirmation.

## Unresolved submission placeholders

1. Full University of Victoria postal affiliation.
2. Corresponding-author telephone number, if the submission system requires it.
3. Author confirmation of the generative-AI disclosure wording.
4. Final human decision on whether legacy M02 engine provenance is acceptable for species-centered primary presentation or should be resolved through a separately authorized non-refit engine audit.
5. Final human approval of the neutral v3 title.

## Recommended human decisions

- Retain the species-centered paper: it directly answers the author’s priority and displays common shore and sea birds without literature-based selection.
- Keep Surf Scoter and Short-billed Gull as the clearest focal examples, with other taxa used to demonstrate component and regional heterogeneity.
- Retain M29 prominently as a central specificity result, not as proof that all focal results are spurious.
- Treat the legacy engine-identification gap as a disclosed provenance limitation unless a narrow aggregate-only audit is separately authorized.
- Do not characterize the v3 package as submission-ready until scientific and author review is complete.

**Recommended final gate:** `PASS_PENDING_HUMAN_SCIENTIFIC_REVIEW`
