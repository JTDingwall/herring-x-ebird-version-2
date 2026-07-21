# eBird methods for discrete point/pulse events: synthesis and application

Outcome-blind synthesis of how comparable eBird analyses link opportunistic checklist data
to a discrete, localized environmental event — a "point/pulse event" like our herring spawn —
and application of that logic to this design. Method and design only; nothing here computes or
depends on bird outcomes. Items feed the remediation register (`docs/14`) and plan (`docs/15`).

## 1. How comparable analyses are conducted

| Event (point/pulse) | What they did | Source |
|---|---|---|
| Wildfire smoke (PM2.5) | Joined a local, time-varying exposure surface (PM2.5) to complete checklists and modeled the probability of *observing* each species vs exposure and effort; smoke changed observation probability for ~65–70% of species. | Wildfire-smoke / NY State |
| Extreme winter weather (polar vortex) | Used 14 years of eBird for 7 waterfowl species to build a multi-year baseline, then measured event-relative distribution deviation during the perturbation. | Waterfowl / polar vortex |
| Periodical cicada emergence (resource pulse) | Measured community-level shifts in avian foraging and composition during the pulse, comparing emergence (brood) areas to habitat-matched non-emergence areas. | Cicada / Science 2024 |
| eBird occurrence (general best practice) | Complete checklists, zero-fill from sampling-event data, standard-effort filtering, effort covariates, spatiotemporal subsampling, observer-expertise covariate. | Johnston et al. 2021; eBird Best Practices |
| Spatially biased effort | Modeled checklist locations as a point process and effort as a surface, then tested formally for preferential sampling (effort correlated with the ecological process). | Preferential-sampling / eBird effort |
| Presence-only exposure | Corrected effort-driven spatial bias with target-group background (background points drawn from the sampling footprint of similarly surveyed records) and spatial thinning. | Target-group background |
| BACI critique | Showed control-site BACI assumptions are frequently violated and a design relating the outcome directly to a continuous intensity ("fusion") had ~3× the power. | BACI / fusion design |
| eBird trend estimation | Controlled the three observer-bias channels explicitly: site selection, search effort, and search efficiency. | Causal eBird trends |

## 2. The transferable logic

- **A. Event = local time-varying exposure surface on complete checklists.** The pulse is
  attached to each checklist by space and time, and the outcome is modeled against that
  surface plus effort. Our additive kernel `E_{it}(λ,τ)` is exactly this construct.
- **B. Name the outcome "probability of reporting," not "occurrence."** The wildfire study is
  explicit that the exposure acts on *observation*, which blends true occurrence with
  detectability and observer behavior. Interpretation is bounded accordingly.
- **C. Multi-year baseline + event-relative deviation, with habitat/space matching.** Establish
  the expectation across many years, then test the event window; match treated to comparison
  units on habitat and latitude, not just calendar.
- **D. Formal preferential-sampling test.** Jointly model the checklist-intensity surface and
  the response and test whether effort correlates with the exposure — the formal version of
  "birders chase the spawn."
- **E. Target-group background + thinning for presence-only exposure.** Contrast presence
  against the *surveyed footprint*, not against unmonitored space; thin heavily-visited cells.
- **F. Control the three observer channels by name:** site selection (visitation model),
  search effort (effort covariates), search efficiency (observer-expertise covariate).
- **G. Prefer continuous exposure-response over control-site BACI/DiD** where the control is a
  weak counterfactual.

## 3. Application to our methods

Our design already implements A (additive kernel), B (E01 is "probability of reporting on a
complete checklist"), the complete-checklist/zero-fill/effort-filter core, block cross-
validation, and a visitation diagnostic. The literature adds five concrete methods we do not
yet have, registered below as proposals (specific parameters left open per the standing
decision policy). These strengthen the Tier-1 confounding items R2 (shared effort–exposure)
and R3 (presence-only exposure) and the detectability item R11.

| New item | Method (from logic) | Satisfies / augments |
|---|---|---|
| R20 | **Spatiotemporal subsampling** as a registered primary or sensitivity: overlay an equal-area grid × event-relative-time bin and subsample detections and non-detections separately per cell, to reduce spatial and observer bias and class imbalance — complementing (not replacing) partial pooling. | R2 |
| R21 | **Observer-expertise / checklist-calibration covariate** (the "search efficiency" channel): add a per-observer expertise index (e.g., species-accumulation-based) beyond prior-checklist count, so detectability variation is absorbed rather than confounded with exposure. | R2, R11, H8 |
| R22 | **Formal preferential-sampling diagnostic**: elevate the visitation model (M26) to a joint or shared-latent test of whether the checklist-intensity surface correlates with the herring exposure surface, and report a preferential-sampling coefficient beside every biological estimand. | R2, H8 |
| R23 | **Target-group background for the presence-only exposure**: build a DFO survey-effort / target-group background (surveyed sections × years) so "no recorded active event" is contrasted against the surveyed footprint, with unmonitored shoreline treated as missing, plus spatial thinning of over-birded spawn sites. | R3 |
| R24 | **Continuous exposure-response as the primary, control-site DiD as sensitivity** (the "fusion" logic): make the continuous additive-kernel / intensity response (Designs A, J) primary for redistribution and dose questions, retaining the calendar-matched DiD (Designs G, H) as a registered sensitivity given its weak counterfactual. | R2, R3 |

Community-level pulse response (H7) is directly supported by the cicada precedent: composition
and diversity shifts as a response to a discrete pulse, with habitat/space-matched comparison —
reinforcing our Design F/G matching rather than changing it.

## 4. Parameters left open (human decision)

The method adoptions above are recommended; the numeric parameters are not fixed here:
subsampling grid size and temporal bin (R20), the specific expertise index (R21), the
joint-model form for the preferential-sampling test (R22), and the target-group definition and
thinning radius (R23). These are registered as proposals pending sign-off, consistent with the
open-decisions policy in `docs/15`.

## 5. Sources

- Wildfire smoke alters observations of breeding birds, NY State — https://link.springer.com/article/10.1007/s10531-026-03406-9
- Citizen science reveals waterfowl responses to extreme winter weather — https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9545755/
- Periodical cicadas disrupt trophic dynamics through community-level shifts in avian foraging (Science 2024) — https://www.science.org/doi/10.1126/science.adi7426
- Johnston et al. 2021, Analytical guidelines to increase the value of community science data (eBird SDM) — https://onlinelibrary.wiley.com/doi/10.1111/ddi.13271
- Best Practices for Using eBird Data — https://ebird.github.io/ebird-best-practices/
- Modeling spatially biased citizen science effort through the eBird database — https://link.springer.com/article/10.1007/s10651-021-00508-1
- Bias in presence-only niche models; background point selection (target-group background) — https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0232078
- Beyond BACI: direct-intensity fusion design for bird risk assessment — https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8668741/

Full bibliographic details for the newly cited sources should be verified and formalized into
`references/references.bib` before Phase 4.
