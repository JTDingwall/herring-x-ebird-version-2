# Codex master prompt — Herring × eBird Version 2

Work inside this repository. Read `AGENTS.md`, all files in `docs/`, and every metadata
registry before changing code.

## Objective

Implement the Version 2 analysis from authoritative raw eBird EBD/SED and DFO herring
inputs. The scientific target is a triangulated assessment of whether herring spawn is
associated with more birds close to spawn, changes in flock size and community structure,
and reduced spatial allocation to simultaneous farther shorelines.

## First command sequence

1. Run `scripts/00_setup.R`.
2. Run `scripts/01_validate_input_metadata.R` with checksum mode off for a fast header/size audit.
3. Run it again with `HERRING_EBIRD_V2_VERIFY_INPUT_SHA256=true` before any derived data are trusted.
4. Run `scripts/02_validate_registries.R` and the tests.
5. Stop and report all metadata discrepancies before writing processing/model code.

## Required implementation order

1. taxonomy and support audit;
2. herring quality tiers and event complexes;
3. streamed eBird processing and shared-checklist resolution;
4. zero-filled species and guild outcomes;
5. all-event exposure table and event-day-zone table;
6. outcome-blind support/visitation gates;
7. M01–M10 core models;
8. registered supporting/diagnostic models;
9. cross-model evidence report.

## Statistical requirements

- Count models are co-primary with spatial allocation; encounter is not a proxy for flock
  size.
- Fit hurdle models with separate detection and positive-count components.
- Preserve `X`, lower-bound, ambiguous, and missing counts; never invent a number.
- Use distance rings, supported distance-time surfaces, and cumulative multi-event
  exposure.
- For redistribution, model near/far allocation conditional on regional totals and also
  model near, far, and total counts jointly.
- Treat herring source records and event complexes as alternative measurement models.
- Treat Surface, Macrocystis, Understory, Length, Width, and component completeness
  separately before any composite/latent intensity model.
- Model observer/checklist allocation separately and report it beside biological models.
- Use event-level resampling or hierarchical event uncertainty; do not use row-iid standard
  errors.
- Use species-specific nuisance structure. Do not recreate the failed shared rank-one
  random-effect structure from Version 1.
- Every fit must map to one model-registry row and write config/data/model hashes.

## Reviewer-mandated constraints (2026 review)

Follow `docs/14_SCIENTIFIC_REVIEW_AND_REMEDIATION.md`. In particular:

- Do not assume any taxon responds. `expected_direction` is a hypothesis label, never a
  prior or an inclusion criterion. "Most species respond" is a prediction tested against a
  strengthened control panel, not an assumption.
- Report the visitation/allocation diagnostic beside every biological estimand; cap claims
  at "recorded-event vs no-recorded-active-event, conditional on observed sampling." Treat
  DFO records as presence-only, never as confirmed absence.
- Placebo shifts must exceed the maximum egg-availability kernel; the +/-14-day shift is a
  spillover probe, not a null control.
- Fix the primary event-complex rule before any clustered standard error or bootstrap; port
  the Stage-2 anti-chaining cap into the Phase-3 event-block union-find.
- Register a nearest-point-on-spawn-line geometry sensitivity for H2 and H5.
- Do not fit any Phase-4 response model until every S2 remediation item is resolved, or make
  any confirmatory claim until every S1 item is resolved.

## Stop conditions

Stop rather than silently simplify when:

- source checksum/header/schema differs;
- a join changes cardinality unexpectedly, or the checklist-to-event spatial join runs
  without an explicit cardinality assertion on stable ids;
- privacy fields would enter tracked output;
- event/ring/period support is below the frozen threshold;
- `zero_fill_eligible` is absent (fail loud; never fail open) or an `event_id` natural key is
  non-unique;
- calendar and event timing are not distinguishable in the supported risk set;
- a count family fails simulation/residual/influence diagnostics;
- a result requires extrapolation beyond observed support;
- a proposed change is motivated only by a favorable outcome, or by an assumed response
  direction.

## Deliverables for each stage

- tested functions under `R/`;
- a `targets` subgraph;
- aggregate QA tables and a human-readable review packet;
- explicit retained/excluded row accounting;
- one decision-log entry for every scientific choice;
- no raw/restricted data in Git.
