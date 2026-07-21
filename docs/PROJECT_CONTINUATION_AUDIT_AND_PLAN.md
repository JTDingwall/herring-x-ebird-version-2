# Project continuation audit and plan

Status: post-Stage 4A planning document; not an authorization. Stage 4A results were
known when this plan was prepared. Machine-readable gates are in
`metadata/estimand_progression_gate.csv`, `metadata/model_progression_gate.csv`, and
`metadata/project_next_actions.csv`.

## Current scientific state

Stage 3 Phases 1-3 are complete and human-approved. Stage 4A was executed under its
recorded authorization and is pending human interpretation. Its individual estimates
are auditable as descriptive conditional associations, while hierarchical pooling and
several diagnostic/sensitivity implementations require the dispositions in the
post-result audit. Stage 4B is not authorized automatically. M31 and the complete
2026-2028 holdout remain locked.

The 15-estimand gate separates conditional checklist reporting, positive numeric
reported counts, recorded-event contrasts, allocation/interference quantities, DFO
survey-state quantities, observation-process quantities, and prospective confirmation.
The 45-model gate preserves every registered model exactly once and does not promote a
deferred model because Stage 4A was favorable or unfavorable.

## Stage 4B option groups

| Option group | Scientific purpose | Previously registered? | Post-result activation? | Required data/authorization | Selection risk | Expected value |
|---|---|---|---|---|---|---|
| 1. Code/integrity repair | Correct pooling-family definition; optionally reproduce locked diagnostic families | Partly | Yes | Tracked aggregates for pooling; explicit human authorization plus protected 2005-2025 data for model reruns | Medium-high | High because defects are demonstrated |
| 2. Observation-process diagnostics | Separate submission/location choice, effort, observer composition, numeric availability, and reporting | Partly | Yes | An observed choice set and frozen covariates; protected authorization for response-linked fits | High | High only with an identifiable parameter |
| 3. DFO exposure-observation work | Distinguish surveyed positive, surveyed negative, and unmonitored/unknown | No complete implementation | Yes | External DFO effort/method data validated against the new schema | Low | Very high for true no-spawn comparisons |
| 4. Interference/redistribution | Separate local reporting, regional allocation, and regional totals | M08 and related estimands registered | Yes for any new model | Defined movement catchment, unaffected or explicitly affected controls, protected authorization | High | Moderate-high if support exists |
| 5. Timing/geometry sensitivity | Quantify source-point, route-footprint, event-interval, and biological-availability sensitivity | Partly | Yes | Frozen alternative representations; validated coverage; protected authorization | High | Moderate; interpretation-specific |
| 6. Structured external validation | Test transport beyond the development observation system | Broadly anticipated | Yes | Independent exposure/outcome systems or regions with compatible definitions | Medium | High but data-dependent |
| 7. Prospective confirmation preparation | Freeze a small claim hierarchy, controls, power, and one-shot governance | M31 registered | Amendment drafted after results | No holdout responses; human governance approval; complete future releases only at execution | Medium before lock, none after lock | Very high |

No option authorizes opening untracked protected response records. Optional nuisance
features derived from bird responses must be constructed pre-period or cross-fitted and
must never be learned from the prospective holdout.

## DFO survey-effort dependency

True no-spawn comparisons need the minimum fields in
`metadata/dfo_survey_effort_schema.csv`: stable survey-unit and visit identifiers; survey
date/time and spatial support; method/platform/effort; searched components and detection
limits; observed survey state; quality/completeness; and immutable source/version
identity. The validator accepts exactly `surveyed_positive`, `surveyed_negative`, and
`unmonitored_unknown`, forbids treating missing effort as zero, and requires positive
evidence for a surveyed-negative classification. It is tested only on synthetic data.

Work that can proceed before those data arrive includes hash/provenance verification,
human interpretation of individual Stage 4A estimates, aggregate-only pooling-repair
specification, synthetic engineering, a matched-diagnostic repair protocol, prospective
claim/governance design, and response-free power inputs. True-negative exposure models,
DFO method-comparability analyses, and absolute exposure interpretations cannot proceed.

## Critical path

### Can be completed now without protected data

1. Preserve and verify Stage 4A v1 artifacts and publish this audit alongside them.
2. Conduct the human review using `docs/STAGE4A_HUMAN_REVIEW_PACKET.md`.
3. Define, but do not silently execute, a model- and unit-specific aggregate pooling
   repair that excludes duplicate component rows.
4. Finalize synthetic identity, zero-fill, linkage, kernel-truncation, DFO-schema, and
   holdout-sentinel tests.
5. Draft an exact matched-family repair specification and outcome-free power plan.

### Requires human Stage 4A review

6. Decide whether PR #2 is merged as immutable historical execution with limitations.
7. Set the allowed claim level for the specificity and observation-process warnings.
8. Decide whether the pooled synthesis is recomputed in a new aggregate-only artifact.
9. Select any Stage 4B question for a reason independent of observed effect direction.

### Requires human authorization for a protected rerun

10. If justified, run new versioned M27/M28, 2-km, dominant-observer, or clustered
    diagnostic repairs. Use new specs, locks, execution records, directories, and reports.
11. Do not overwrite v1 or combine repaired and original rows without explicit lineage.

### Requires external DFO data

12. Obtain and validate survey coverage, methods, effort, detection limits, and explicit
    positive/negative/unknown states.
13. Audit component comparability and common support before defining any true no-spawn
    or intensity estimand.

### Requires prospective-governance action

14. Human-approve or replace the draft claim hierarchy, controls, placebo rules,
    arbitration thresholds, and confirmable region-guild cells.
15. Select an access mechanism: independent custodian, third-party key, timestamped
    one-shot package, or auditable release controls.
16. Freeze code, inclusion probabilities, nuisance construction, power, and the exact
    supersession record before future response access.

### Must wait for the complete 2026-2028 holdout

17. Execute M31 once under the frozen approved package, with no interim response looks
    and no response-derived taxon, model, threshold, or nuisance selection.

## Explicit continuation answers

1. **Is PR #2 scientifically auditable as the historical Stage 4A execution?** Yes, as
   a reconstructible, internally hashed historical execution, with disclosed
   post-response code repairs and the defects in this audit. It is not independently
   blinded custody.
2. **Is there evidence of a material implementation defect?** Yes. The released
   partial-pooling columns are materially defective. Placebo and two robustness paths
   also violate locked families, but their numerical impact is unknown without a newly
   authorized protected rerun.
3. **Can findings be interpreted?** Individual estimates can be interpreted as
   descriptive/exploratory associations conditional on eligible submitted checklists,
   recorded-event exposure, geography, model family, and support. They do not identify
   occupancy, abundance, movement, biomass, or causation. The pooled columns cannot be
   interpreted.
4. **What should happen to PR #3?** It should not be merged wholesale. Its advice is
   selectively superseded by the crosswalk and annotated disposition; whether the
   original draft PR is closed or rewritten is a repository-owner decision.
5. **What can proceed before DFO effort data?** Provenance, human review,
   aggregate-only pooling specification, synthetic safeguards, diagnostic-repair design,
   response-free power inputs, and prospective governance.
6. **What must be frozen before future development-response access?** The question,
   estimand, population, exposure and timing representation, model/sensitivity families,
   controls, multiplicity/claim hierarchy, support rules, nuisance construction,
   release fields, hashes, and repair lineage.
7. **What precedes prospective confirmation?** Human-approved amendment, credible
   holdout access control, confirmable-cell power/assurance, immutable code/data schemas,
   external-data decisions, complete 2026-2028 release, and a one-shot audit plan.

Recommended immediate stage: human Stage 4A review plus an outcome-free repair-specification
decision. Selected post-result Stage 4B planning may follow, but protected execution and
prospective confirmation remain separately gated.
