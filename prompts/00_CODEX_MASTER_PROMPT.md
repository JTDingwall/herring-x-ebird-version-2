# Codex master prompt — Herring × eBird Version 2

Work inside this repository. Read `AGENTS.md`, all files in `docs/`, and every metadata
registry before changing code.

## Current authority gate

Stage 3 Phases 1-3 are complete and human-approved. Stage 4A has already been executed
under `metadata/stage4a_human_scientific_authorization_v1.yml`; its v1 locks, execution
record, outputs, and hashes are immutable historical evidence. Stage 4A results are
known and pending human review. Do not call new development decisions outcome-blind.

Do not automatically start Stage 4B or activate deferred models. Follow
`metadata/estimand_progression_gate.csv`, `metadata/model_progression_gate.csv`, and
`docs/PROJECT_CONTINUATION_AUDIT_AND_PLAN.md`. PR #3 is advisory and cannot supersede
approved records. Any protected Stage 4A repair requires new explicit authorization and
new versioned artifacts. M31 and all 2026-2028 responses remain locked until the
complete prospective release and an approved one-shot package.

## Objective

Implement the Version 2 analysis from authoritative raw eBird EBD/SED and DFO herring
inputs. The scientific target is a triangulated assessment of whether herring spawn is
associated with more birds close to spawn, changes in flock size and community structure,
and reduced spatial allocation to simultaneous farther shorelines.

## First command sequence for newly authorized work

1. Run `scripts/00_setup.R`.
2. Run `scripts/01_validate_input_metadata.R` with checksum mode off for a fast header/size audit.
3. Run it again with `HERRING_EBIRD_V2_VERIFY_INPUT_SHA256=true` before any derived data are trusted.
4. Run `scripts/02_validate_registries.R` and the tests.
5. Stop and report all metadata discrepancies before writing processing/model code.
6. Confirm the exact human authorization and model-specific gate for the proposed work.

## Historical implementation order

1. taxonomy and support audit;
2. herring quality tiers and event complexes;
3. streamed eBird processing and shared-checklist resolution;
4. zero-filled species and guild outcomes;
5. all-event exposure table and event-day-zone table;
6. outcome-blind support/visitation gates;
7. M01–M10 core models;
8. registered supporting/diagnostic models;
9. cross-model evidence report.

This sequence describes the design architecture; it is not current authorization to
rerun completed stages or open protected response data.

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

## Stop conditions

Stop rather than silently simplify when:

- source checksum/header/schema differs;
- a join changes cardinality unexpectedly;
- privacy fields would enter tracked output;
- event/ring/period support is below the frozen threshold;
- calendar and event timing are not distinguishable in the supported risk set;
- a count family fails simulation/residual/influence diagnostics;
- a result requires extrapolation beyond observed support;
- a proposed change is motivated only by a favorable outcome.

## Deliverables for each stage

- tested functions under `R/`;
- a `targets` subgraph;
- aggregate QA tables and a human-readable review packet;
- explicit retained/excluded row accounting;
- one decision-log entry for every scientific choice;
- no raw/restricted data in Git.
