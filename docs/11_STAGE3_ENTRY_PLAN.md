# Stage 3 entry plan

**Status:** `BLOCKED_BY_STAGE2_DESIGN_IDENTIFICATION_FAILURE`  
**Stage 2 gate:** `STOP_DESIGN_IDENTIFICATION_FAILURE`  
**Response models authorized:** no  
**Prospective 2026+ holdout:** frozen  
**Stage 2 design grid:** unchanged

## Purpose

This plan incorporates the post-freeze eBird checklist-methods review into the project workflow. It adds data-handling and interpretation gates without adding a large adjustment set or examining biological response contrasts. Stage 3 cannot begin until the incomplete shoreline-bundle coverage identified by the repaired Stage 2 gate is resolved.

## Phase −1 — resolve the upstream geometry failure

The protected shoreline bundle provides candidate coverage for Strait of Georgia, West Coast Vancouver Island and North Area, but does not support the intended coastwide core. Human reviewers must choose and document one scientifically defensible path:

1. obtain and verify a coastwide marine shoreline bundle, then rerun the outcome-blind geometry audit and repair report; or
2. approve a geographically scoped primary design limited to regions with validated shoreline support, with other regions explicitly descriptive or deferred; or
3. approve another source-geometry design only after its estimand and limitations are fully specified and the repaired gate is rerun.

The choice must be made without examining herring–bird response contrasts. The current `STOP_DESIGN_IDENTIFICATION_FAILURE` classification remains until the rerun produces a reviewable gate.

**Exit criterion:** shoreline coverage and geometry identification pass for the approved primary geography and representation.

## Required human decisions

The scientific approver must record all of the following before Stage 3 begins:

| Decision | Recommended choice | Alternatives retained | Approval effect |
| --- | --- | --- | --- |
| Independent checklist event | accept implemented composite event per `GROUP IDENTIFIER`; sampling-event ID otherwise | retained private component crosswalk | confirms the repaired implementation |
| Primary effort set | accept implemented 5–300 minutes, traveling ≤5 km, 1–10 observers | ≤2 km spatial-precision and frozen ≤10 km broad sensitivities | resolves mismatch between local exposure and route footprint |
| Shared-count reconciliation | accept primary exclusion of effort-disagreement groups | registered disagreement sensitivity | prevents outcome-dependent selection among group copies |
| Estimand language | checklist reporting probability and reported conditional count | justified repeat-visit occupancy only as separate future work | controls scientific claims |
| Validation unit | event-complex or shoreline-time blocks | stricter observer/event grouping when feasible | prevents train/test leakage |
| Raw BCCWS integration | do not pool without deterministic crosswalk | separate external validation with overlap caveat | prevents duplicate data streams |

Approval must be versioned and linked to the exact branch commit. Approval does not authorize access to the 2026+ prospective holdout.

## Phase 0 — record approval

1. Confirm that Phase −1 has passed and complete the human decision record for every pending or implemented-pending-acceptance item in `metadata/ebird_checklist_handling_gate.csv`.
2. Record approver, UTC timestamp, selected options, branch commit and retained alternatives.
3. Recompute and record the hash of the approved Stage 3 entry specification.
4. Keep the Stage 2 candidate-grid file and its two retained hashes unchanged.

**Exit criterion:** every severity `block` item is approved or verified and no response model is yet fitted.

## Phase 1 — construct the independent checklist denominator

1. Verify EBD and SED release and taxonomy identity.
2. Apply the accepted-record predicate.
3. Collapse shared checklists to one analysis event before zero-filling.
4. Preserve private component checklist and observer identifiers for audit only.
5. Zero-fill only eligible complete checklists.
6. Map `X` to detection = 1 and numeric count = missing.
7. Set stationary distance to zero before distance/speed handling.
8. Enforce uniqueness of analysis checklist event × species.

**Exit criterion:** Q01–Q09 in the checklist audit pass on fixtures and protected local data.

## Phase 2 — outcome-blind sampling-support audit

Using only SED, herring metadata and identifiers needed for independence checks, report:

- eligible checklist events and unique observers;
- protocol, duration, travel distance, party size and start-time availability;
- support by region × event-time × distance cell;
- repeated observer, locality and event-complex concentration;
- exposure classification by travel-distance stratum;
- support for the ≤2 km, ≤5 km and ≤10 km sets.

Do not calculate species detection rates, bird counts by exposure, effects, intervals or response plots.

**Exit criterion:** reviewers confirm adequate overlap and effective replication or narrow the eligible-checklist population using only frozen candidate rules.

## Phase 3 — implement validation and estimand safeguards

1. Split train/test data by complete event complex or shoreline-time block.
2. Keep one grouped checklist and all associated event links on one side of a split.
3. Model or cluster repeated observer/site dependence using already registered observation structure.
4. Label detection output as reporting on an eligible complete checklist.
5. Label count output as a reported relative index conditional on detection and numeric availability.
6. Evaluate hurdle lognormal against truncated NB2 using blocked predictive checks and posterior/predictive tail diagnostics.

**Exit criterion:** Q10–Q12 pass and report templates cannot emit absolute-abundance, true-absence or unjustified occupancy claims.

## Phase 4 — exploratory response analysis

Only after Phases 0–3 pass:

1. run the hash-identical latent-factor pilot under the registered selection rule;
2. fit the registered exploratory model families in their frozen roles;
3. retain the ≤2 km and ≤10 km analyses as spatial sensitivities around the approved primary set;
4. report all registered primary/supporting results regardless of direction;
5. keep 2026+ releases frozen and inaccessible.

Current analyses remain exploratory and estimand-refining until prospective confirmation.

## Scope control

The checklist review does not require weather, tide, vessel traffic, habitat, prey, or other new primary covariates. Such variables may be discussed as limitations or proposed for a separately powered follow-up. The current priority is correct sampling-unit construction, compatible spatial support, transparent estimands and independent validation.

## Planned repository deliverables

- checklist construction and zero-fill fixtures;
- independent-event crosswalk audit with no released identifiers;
- metadata-only sampling-support report;
- blocked split manifest containing hashed/generalized group labels only;
- completed checklist gate and signed Stage 3 entry specification;
- updated rendered analysis-plan and methods-flow reports.
