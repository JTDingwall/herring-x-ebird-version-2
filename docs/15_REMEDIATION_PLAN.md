# Remediation plan (sequenced and gated)

Execution plan for the findings in `docs/14_SCIENTIFIC_REVIEW_AND_REMEDIATION.md`. The
register says *what* to fix; this document says *in what order*, *what blocks what*, and
*which gate each item clears*. It computes nothing from bird outcomes.

Gates (from `docs/14`): **S1** items block any confirmatory claim; **S2** items block Phase 4
response-model fitting; **S3** items are code-integrity fixes.

## Wave 0 — Immediate, no scientific judgment (this pass)

These are coherence and code-integrity fixes that embed no study parameter and need no data.

| Item | Change | Status |
|------|--------|--------|
| R7 | Placebo date shifts must exceed the maximum registered egg-availability kernel; shifts inside the window are relabeled spillover probes, not null controls (`docs/02`). | done |
| R5 (rule) | Prespecified decision rule for a non-null falsification result added to `docs/04`. | done |
| R14 | `zero_fill_taxa` fails loud when the eligibility column is absent instead of failing open (`R/ebird_ingestion.R`). | done |
| R15 (mechanism) | `derive_herring_event_fields` gains an opt-in `require_unique_event_id` guard so a hard stop can be wired once one-row-per-event semantics are confirmed (`R/herring_event_engineering.R`). | done |
| R16 | `candidate_event_links` gains an optional truncation-weight guard that warns when the candidate radius leaves non-negligible kernel weight at the cutoff (`R/spatial_linkage.R`). | done |
| R13 (mechanism) | `candidate_event_links` can carry stable `sampling_event_identifier`/`event_id` columns so the downstream join does not rely on row order; relationship documented as many-to-many by design (`R/spatial_linkage.R`). | done |
| R17 | `egg_thickness` parameter renamed to `intensity_index` to reflect what it actually carries (`R/herring_event_engineering.R`). | done |
| R19 | Guild richness vs guild-count-lower divergence documented in code (`R/ebird_ingestion.R`). | done |

## Wave 1 — Open scientific decisions (blocked on human sign-off)

Per the standing instruction, these are laid out as options and **decided by the project
owner**, not drafted with values here. Each becomes a hashed decision record once chosen.

- **D1 — Primary event-complex rule (R8).** Choose the primary among `complex_1km_3d`,
  `complex_2km_7d`, `complex_5km_14d`. This defines the event, which is the clustering unit
  for every standard error and bootstrap, so it must be fixed before Wave 2 R4 and before any
  clustered inference. Options differ in how aggressively nearby records merge; the wider the
  rule, the fewer independent event clusters and the lower the effective sample size.
- **D2 — Evidence thresholds (R10).** Set the numeric definition of "agreement across two
  independent design families" and "biologically meaningful magnitude" for the six-level
  evidence ladder, plus the cross-family (not only within-species) multiplicity handling.
  Options range from a fixed effect-size floor with a posterior-probability agreement rule to
  a fully hierarchical shrinkage criterion.
- **D3 — Negative-control panel composition (R5).** Enlarge and diversify the falsification
  panel beyond the two `surface_vegetation_roe`-adjacent dabblers. Options: add taxa from
  ecologically distant guilds (e.g., open-country or forest species with no shoreline
  mechanism) so the control is not contaminated by a weak roe/vegetation pathway.
- **D4 — Multi-guild membership (R18).** Decide whether functionally multi-modal taxa (e.g.,
  Bald Eagle: piscivore and scavenger) receive registered multi-guild membership, or whether
  H6 is explicitly scoped to single-guild taxa. Current code enforces single membership.
- **D5 — Geometry re-registration for H2/H5 (R6).** Decide whether to register a
  nearest-point-on-spawn-line geometry sensitivity. Depends on shoreline-coverage
  availability (see Wave 2 R3), since the shoreline bundle currently does not cover the
  coastwide core — which is why source-point became the sole registered geometry.

## Wave 2 — Blocked on external action or data

- **R1 — External confirmatory custody.** Register the frozen models, estimands, and (once
  D2 is set) numeric thresholds on OSF or as a Registered Report, and place the 2026+ and any
  external-region response data under an independent custodian who is not the analyst.
- **R3 — DFO survey-effort surface.** Obtain or reconstruct where DFO surveyed and found no
  spawn, so unmonitored shoreline is treated as missing rather than as confirmed absence.
- **R4 — Prospective power analysis.** Using design metadata only, estimate the
  minimum-detectable effect per guild×region for 2026–2028 and pre-declare which cells are
  adequately powered for confirmation. Requires D1 (event definition) first.

## Wave 3 — Post-decision engineering (before Phase 4)

Executed once the relevant Wave 1 decision is recorded:

- Implement the chosen event-complex rule and port the Stage-2 anti-chaining cap into the
  Phase-3 event-block union-find; audit the block-size distribution (R8).
- Wire the `require_unique_event_id` stop into the pipeline once one-row-per-event semantics
  are confirmed (R15).
- Make the relative spawn index comparable by modeling component availability or restricting
  dose-response to component/method-matched subsets (R9).
- Add species-specific detectability treatment for confusable/hard-to-detect guilds and
  assess exposure-correlated misclassification (R11).
- Restrict fine inner-ring inference (0–0.5, 0.5–1 km) to stationary/short-travel subsets
  (R12).
- Implement the geometry sensitivity if D5 is approved (R6).

## Critical path

D1 (event definition) is the earliest binding decision: it gates R4 (power) and all
clustered inference. R1/R3 are the long-lead external items and should start in parallel now.
No Phase 4 model is fit until every S2 item (R6–R12) is resolved; no confirmatory claim is
made until every S1 item (R1–R5) is resolved.
