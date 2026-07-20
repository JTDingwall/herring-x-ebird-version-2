# eBird checklist methods review and Stage 2 addendum

**Review date:** 2026-07-20  
**Stage gate:** `STOP_DESIGN_IDENTIFICATION_FAILURE`  
**Human scientific decision:** `REVISION_REQUIRED`  
**Response models authorized:** no  
**Candidate grid changed:** no  
**Candidate-grid SHA-256 retained:** `8b9ba99dbded84273cb7860d530e09b6b3d50b09603d082e6013742245127a81`

> SUPPORT_ONLY_NOT_AN_EFFECT_ESTIMATE. This review used published methods and the reported Stage 2 design. It did not inspect exposure-specific bird responses or fit a registered model.

## Relationship to the repaired Stage 2 gate

After this checklist review was added, the Stage 2 scientific-gate repair found that the protected shoreline bundle does not cover the intended coastwide core. The current upstream gate is therefore `STOP_DESIGN_IDENTIFICATION_FAILURE`, not approval-ready. The original 105-option grid and both of its retained hashes remain unchanged.

The repair also implemented several checklist recommendations: one composite analysis event per shared group, exclusion of effort-disagreement groups from the primary frame, a standardized 5–300 minute / ≤5 km / 1–10 observer primary filter, and exclusion of wholly SED-only structural-unknown events from primary zero-filling. Those rules remain subject to human scientific acceptance, but they are no longer merely unimplemented recommendations.

No Stage 3 response model is authorized until the shoreline-coverage failure is resolved and the remaining checklist, estimand, validation and BCCWS-overlap decisions are approved.

## Checklist-methods conclusion

The reported workflow is aligned with the central requirements for using eBird checklists: complete checklists define the denominator, EBD observations are joined to SED sampling events, `X` remains detection-only, detection is separated from positive-count magnitude, taxonomy is versioned, and complete-area protocols remain separate.

The following checklist items still require explicit human approval before Stage 3:

1. accept the implemented composite shared-group and disagreement-exclusion rules;
2. decide whether the ≤2 km travel-distance set is a required spatial-precision sensitivity around the implemented ≤5 km primary;
3. lock the estimand language as checklist reporting and reported conditional count, not true absence, population abundance, or occupancy; and
4. approve event-complex or shoreline-time validation blocks and the BCCWS deduplication boundary.

These recommendations do not add ecological covariates. They clarify the sampling unit, exposure footprint, validation unit, and interpretation.

## What the literature requires

### Independent checklist event

Shared eBird checklists are duplicate accounts of one birding event. Cornell's `auk_unique()` documentation states that grouped copies are collapsed using `GROUP IDENTIFIER`; the default implementation selects the component record with the lowest checklist identifier and retains the contributing checklist and observer identifiers.

The Stage 2 repair now constructs one composite event per shared group, excludes effort-disagreement groups from the primary frame, and retains disagreement rows as a registered sensitivity. Human review must confirm this rule before response access. The analysis frame must retain one row per independent checklist event × species.

Primary sources:

- [Best Practices for Using eBird Data: shared checklists](https://ebird.github.io/ebird-best-practices/ebird.html#shared-checklists)
- [`auk_unique()` reference](https://cornelllabofornithology.github.io/auk/reference/auk_unique.html)
- [`auk_zerofill()` reference](https://cornelllabofornithology.github.io/auk/reference/auk_zerofill.html)

### Zero-filling and count state

An unreported focal species can be converted to an inferred checklist-level non-detection only when the checklist is complete and the analysis event is otherwise eligible. The repaired audit classifies wholly SED-only events as structural unknowns and excludes them from primary zero-filling; within retained eligible events, an unreported focal species can still be zero-filled. A zero means not reported or detected on that eligible checklist; it does not prove ecological absence.

`X` means detected but not numerically counted. It must map to detection = 1 and numeric count = missing. The project's separate detection, numeric, `X`, lower-bound and ambiguity states are therefore retained.

Primary source: [Best Practices for Using eBird Data: zero-filling and count handling](https://ebird.github.io/ebird-best-practices/ebird.html#zero-filling).

### Effort and spatial footprint

Cornell's current worked guidance filters stationary and traveling checklists to at most 6 hours, 10 km and 10 observers for a weekly 3 km product, and explicitly recommends stricter travel-distance filtering when finer spatial precision is required. The public EBD/SED supplies one checklist coordinate, not the public route geometry. A hotspot point may also differ from the observer's exact survey position.

The repaired Stage 2 gate now treats 5–300 minutes, up to 5 km and 1–10 observers as the standardized candidate primary and the wider set as broad sensitivity. Because the herring design contains a 2 km local exposure threshold, the following outcome-blind recommendation remains for human decision:

- candidate primary already implemented: complete stationary/traveling checklists, 5–300 minutes, traveling distance at most 5 km, 1–10 observers;
- spatial-precision sensitivity: stationary and traveling checklists at most 2 km;
- broad sensitivity: the frozen 1–360 minute, at most 10 km set; cap observers at 10 unless reviewers approve evidence for 11–20;
- complete-area protocols remain separate.

This is a scientific-gate amendment layered on the unchanged candidate grid; it does not rewrite the original freeze.

Primary source: [Best Practices for Using eBird Data: effort and spatial precision](https://ebird.github.io/ebird-best-practices/ebird.html#accounting-for-variation-in-effort).

### Estimands and occupancy language

The defensible primary quantities are:

- `P(species reported | eligible complete checklist, exposure, modeled observation process)`; and
- `E(reported numeric count | detected, numeric count available, eligible checklist)`.

The second quantity is a relative reported-count index, not a census. Standard occupancy language requires repeat visits and closure assumptions. Hochachka, Ruiz-Gutierrez and Johnston (2023) show that pseudo-repeat construction from eBird can be biased when observer-selected sites are not representative and that adding single visits can worsen occupancy bias when detection is low.

Primary sources:

- [Cornell eBird relative-abundance guidance](https://ebird.github.io/ebird-best-practices/abundance.html)
- [Hochachka et al. 2023](https://doi.org/10.1093/ornithology/ukad035)

### Preferential sampling and validation

Birders may preferentially visit conspicuous spawn events. Complete-checklist filtering and effort adjustment do not make checklist locations random. Before response access, produce a metadata-only support table containing eligible checklist counts and unique observers by region × event-time × distance × protocol, plus duration, distance, observer-number and start-time-availability summaries. Do not add these summaries as automatic biological covariates.

Train/test splits must hold out whole herring event complexes or shoreline-time blocks. Random checklist-row splits can leak closely related events, sites or observers across train and test data.

Supporting sources:

- [Johnston et al. 2021](https://doi.org/10.1111/ddi.13271)
- [Tang et al. 2021](https://doi.org/10.1007/s10651-021-00508-1)
- [Grade et al. 2022](https://doi.org/10.1371/journal.pone.0277223)
- [Stuber et al. 2022](https://doi.org/10.1016/j.biocon.2022.109556)

## British Columbia Coastal Waterbird Survey overlap

Birds Canada documents that NatureCounts users can enable automatic export of app-entered checklists to eBird. Because BCCWS is a NatureCounts checklist protocol, some BCCWS records may also occur in EBD. Public documentation does not establish the fraction exported or provide a universal public crosswalk.

Published BCCWS analyses remain valid background literature. Raw BCCWS and eBird records must not be pooled as independent samples unless checklist-level identifiers or a deterministic crosswalk can remove overlap. Otherwise BCCWS may be used only as a separate external validation stream with the potential overlap acknowledged.

Source: [Birds Canada: NatureCounts and eBird](https://learn.birdscanada.org/additional-resources/naturecounts/naturecountsapp/naturecounts-and-ebird/).

## Machine-readable gate

`metadata/ebird_checklist_handling_gate.csv` defines the aligned, implemented-pending-acceptance, verification and human-decision items. Blocking items and the upstream shoreline gate must pass before a Stage 3 response model is opened.

The complete interactive review is in `reports/ebird_checklist_methods_audit.html`; the expanded evidence map is in `reports/herring_ebird_broad_literature_survey.html` with its source table in `metadata/herring_ebird_literature_matrix.csv`.

## Review limitation

This addendum assesses the reported design and current methodological literature. It does not independently prove that protected-data code executed each rule. The executable invariants in the gate table and Stage 3 plan provide that verification path without consulting exposure-specific bird responses.
