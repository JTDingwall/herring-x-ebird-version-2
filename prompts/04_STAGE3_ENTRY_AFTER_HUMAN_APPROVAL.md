# Codex Stage 3 entry prompt — run only after human scientific approval

## Hard stop

Do not run this prompt until every blocking decision in
`metadata/ebird_checklist_handling_gate.csv` has a versioned human approval
record and `metadata/stage3_entry_plan.yml` has been updated from pending to the
approved choices.

Do not modify `metadata/stage2_candidate_design_grid.csv` or either retained
Stage 2 hash. Do not access any 2026-or-later herring or bird response record.

## Purpose

Implement the independent checklist denominator, zero-fill invariants,
metadata-only sampling-support audit and blocked validation design described in
`docs/10_EBIRD_CHECKLIST_METHODS_REVIEW.md` and
`docs/11_STAGE3_ENTRY_PLAN.md`.

This prompt does not authorize a biological response fit until Phases 0–3 of
the Stage 3 entry plan pass.

## Required implementation order

1. Verify exact EBD/SED release and taxonomy identity and the accepted-record
   predicate.
2. Collapse shared submissions to one independent checklist event using the
   approved `GROUP IDENTIFIER` rule before zero-filling.
3. Preserve contributing checklist/observer IDs only in the protected local
   audit crosswalk; never release them.
4. Generate zeros only from eligible complete checklists, including complete
   SED events with no focal EBD row.
5. Preserve detection, numeric count, `X`, lower-bound and ambiguity states.
6. Set stationary distance to zero before distance and speed handling.
7. Enforce one row per independent checklist event × species.
8. Produce the response-blind sampling-support report for the approved primary,
   ≤2 km precision and ≤10 km broad sets.
9. Build event-complex or shoreline-time blocked train/test assignments without
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
- Do not split random checklist rows across train and test when they share an
  event complex or approved blocking unit.
