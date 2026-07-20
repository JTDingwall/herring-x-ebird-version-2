# Stage 3 entry plan

**Status:** `STAGE3_PHASES_1_TO_3_AUTHORIZED`  
**Current gate:** `PASS_STAGE3_PHASES_1_TO_3_AUTHORIZED`  
**Response models authorized:** no  
**Prospective 2026+ holdout:** frozen  
**Stage 2 design grid:** unchanged

## Purpose

This plan incorporates the post-freeze eBird checklist-methods review into the project workflow. Human authorization permits Stage 3 Phases 1–3. Immutable source points are the only registered analysis geometry. Shoreline classes and derived alongshore products remain audit provenance only. Phase 4 and all response models remain unauthorized.

## Phase −1 — completed geometry decision

Human approval selects immutable source points as the only registered analysis representation across valid source records. EDGE_TYPE 100, EDGE_TYPE 150 and derived alongshore products remain audit provenance only and do not enter any sensitivity. Missing extents are never inferred.

**Exit criterion:** completed by the versioned human-approval record. Incomplete shoreline coverage remains a documented sensitivity limitation rather than a primary-identification failure.

## Recorded human decisions

The versioned approval record confirms the following choices:

| Decision | Recommended choice | Alternatives retained | Approval effect |
| --- | --- | --- | --- |
| Independent checklist event | accept implemented composite event per `GROUP IDENTIFIER`; sampling-event ID otherwise | retained private component crosswalk | confirms the repaired implementation |
| Primary effort set | accept implemented 5–300 minutes, traveling ≤5 km, 1–10 observers | ≤2 km spatial-precision and frozen ≤10 km broad sensitivities | resolves mismatch between local exposure and route footprint |
| Shared-count reconciliation | accept primary exclusion of effort-disagreement groups | registered disagreement sensitivity | prevents outcome-dependent selection among group copies |
| Estimand language | checklist reporting probability and reported conditional count | justified repeat-visit occupancy only as separate future work | controls scientific claims |
| Validation unit | event-complex or source-point spatial–time blocks | stricter observer/event grouping when feasible | prevents train/test leakage |
| Raw BCCWS integration | do not pool without deterministic crosswalk | separate external validation with overlap caveat | prevents duplicate data streams |

Approval must be versioned and linked to the exact branch commit. Approval does not authorize access to the 2026+ prospective holdout.

## Phase 0 — approval recorded

1. Human decision recorded in `metadata/stage2_human_scientific_approval_v1.yml` with a matching SHA-256 file.
2. Selected geometry, event, effort, checklist, estimand, validation, registry and prospective rules are versioned.
3. The Stage 2 candidate grid and both retained hashes remain unchanged.
4. Response models and Stage 3 entry implementation remain unauthorized.

**Exit criterion:** completed. Stage 3 Phases 1–3 are authorized under the hashed authorization record.

## Phase 1 — authorized: construct the independent checklist denominator

1. Verify EBD and SED release and taxonomy identity.
2. Apply the accepted-record predicate.
3. Collapse shared checklists to one analysis event before zero-filling.
4. Preserve private component checklist and observer identifiers for audit only.
5. Zero-fill only eligible complete checklists.
6. Map `X` to detection = 1 and numeric count = missing.
7. Set stationary distance to zero before distance/speed handling.
8. Enforce uniqueness of analysis checklist event × species.

**Exit criterion:** Q01–Q09 in the checklist audit pass on fixtures and protected local data.

## Phase 2 — authorized: outcome-blind sampling-support audit

Using only SED, herring metadata and identifiers needed for independence checks, report:

- eligible checklist events and unique observers;
- protocol, duration, travel distance, party size and start-time availability;
- support by region × event-time × distance cell;
- repeated observer, locality and event-complex concentration;
- exposure classification by travel-distance stratum;
- support for the ≤2 km, ≤5 km and ≤10 km sets.

Do not calculate species detection rates, bird counts by exposure, effects, intervals or response plots.

**Exit criterion:** reviewers confirm adequate overlap and effective replication or narrow the eligible-checklist population using only frozen candidate rules.

## Phase 3 — authorized: implement validation and estimand safeguards

1. Split train/test data by complete event complex or source-point spatial–time block.
2. Keep one grouped checklist and all associated event links on one side of a split.
3. Model or cluster repeated observer/site dependence using already registered observation structure.
4. Label detection output as reporting on an eligible complete checklist.
5. Label count output as a reported relative index conditional on detection and numeric availability.
6. Evaluate hurdle lognormal against truncated NB2 using blocked predictive checks and posterior/predictive tail diagnostics.

**Exit criterion:** Q10–Q12 pass and report templates cannot emit absolute-abundance, true-absence or unjustified occupancy claims.

## Phase 4 — not authorized: exploratory response analysis

Do not run. Only after Phases 1–3 pass and a separate explicit human authorization:

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
