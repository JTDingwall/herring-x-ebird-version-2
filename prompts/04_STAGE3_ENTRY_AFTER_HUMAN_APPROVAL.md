# Codex Stage 3 entry prompt — run only after human scientific approval

## Authorized scope and hard stops

`metadata/stage3_phases1_3_authorization_v1.yml` authorizes this prompt for
Phases 1–3 only. Stop after each phase for its registered review. Phase 4,
response summaries, response-direction diagnostics and response models remain
prohibited.

Immutable source point is the only registered analysis geometry. EDGE_TYPE 100,
EDGE_TYPE 150 and all derived alongshore products are audit provenance only and
must not enter an analysis or sensitivity. Never infer missing event extents.

Do not modify `metadata/stage2_candidate_design_grid.csv` or either retained
Stage 2 hash. Do not access any 2026-or-later herring or bird response record.

## Purpose

Implement the independent checklist denominator, zero-fill invariants,
metadata-only sampling-support audit and blocked validation design described in
`docs/10_EBIRD_CHECKLIST_METHODS_REVIEW.md` and
`docs/11_STAGE3_ENTRY_PLAN.md`.

This prompt does not authorize a biological response fit. Passing Phases 1–3
creates a new human gate; Phase 4 requires a separate explicit authorization.

## Required implementation order

1. Verify exact EBD/SED release and taxonomy identity and the accepted-record
   predicate.
2. Collapse shared submissions to one independent checklist event using the
   approved `GROUP IDENTIFIER` rule before zero-filling.
3. Preserve contributing checklist/observer IDs only in the protected local
   audit crosswalk; never release them.
4. Generate zeros only from eligible complete analysis events. Do not zero-fill
   incomplete lists or wholly SED-only structural-unknown events whose checklist
   identity cannot be verified from the protected release.
5. Preserve detection, numeric count, `X`, lower-bound and ambiguity states.
6. Set stationary distance to zero before distance and speed handling.
7. Enforce one row per independent checklist event × species.
8. Produce the response-blind sampling-support report for the source-point
   primary and the approved ≤2 km precision and ≤10 km checklist-travel subsets.
9. Build event-complex or source-point spatial–time blocked train/test assignments without
   releasing exact identifiers or coordinates.
10. Run checklist fixtures, privacy scan, `git diff --check`, and CI. Stop for
    human review before fitting any registered response model.

## Prohibited shortcuts

- Do not treat shared checklist copies as independent observations.
- Do not convert an incomplete checklist omission to zero.
- Do not invent a numeric count for `X`.
- Do not call checklist non-detection true absence.
- Do not call reported counts absolute abundance.
- Do not construct occupancy pseudo-repeats without a separately approved
  closure and representativeness audit.
- Do not pool raw BCCWS and eBird records without a deterministic crosswalk.
- Do not add new primary ecological covariates in this entry stage.
- Do not use shoreline class, shoreline snap, derived alongshore length, or
  alongshore union as an exposure, analysis, or sensitivity.
- Do not split random checklist rows across train and test when they share an
  event complex or approved blocking unit.
