# Post-Stage 4A adversarial audit

Status: **post-result audit; human scientific decision required**

Audit date: 2026-07-21

Development outcomes known: **yes**

Protected row-level response data reopened for this audit: **no**

2026-2028 response data accessed: **no**

This audit was performed after the Stage 4A aggregate results were available. It does
not amend the Stage 4A v1 authorization, locks, execution record, outputs, or hashes.
It uses tracked code, governance records, tests, and privacy-safe aggregate tables.

## Bottom line

Stage 4A is reconstructible as the historical execution authorized on PR #2, and its
individual model estimates, standard errors, confidence intervals, within-family BH
adjustments, geometry accounting, and validation tables remain usable for descriptive
human review. They estimate reporting or reported-count associations conditional on an
eligible submitted checklist and the recorded-event exposure design. They do not
identify occupancy, abundance, biomass, movement, or causal effects.

One material defect is directly visible without reopening protected data: the two
`partial_pool_*` columns in `effect_estimates.csv` were calculated in families defined
only by region, outcome, and contrast. All 84 families with computed values mix model IDs or unit
classes; active-near families combine guild, species, duplicated M11/M12 component, and
sometimes specificity-panel rows. Those columns, and any synthesis based on them, are
not interpretable as the authorized hierarchical species synthesis. Individual effects
and their model-specific multiplicity columns were calculated separately and are not
changed by this defect.

The false-date, false-location, 2-km, and dominant-observer routines also do not match
their locked matched-family specifications. Their result impact cannot be measured
without a new protected, versioned repair run. M26 does not estimate the registered
exposure-related visitation process. No protected rerun is authorized or performed here.

## Authority, chronology, and branch reconciliation

Authority was applied in this order: signed human records, hashed locks, execution
records, tied code/tests, contemporaneous reports, and then later advisory prose.
`metadata/post_stage4a_branch_reconciliation.yml` records the refreshed state. The
working branch is based on PR #2 head `dae0be997a940c7e95c900f64d81500769c5f836`.
PR #3 head `f887b6895ff4caaf495295443258b784e81d2224` shares main merge base
`3b78aa061a3548bb8f1c3586e506f154ad319f25` and is treated only as an advisory diff.
No PR #3 commit was merged or cherry-picked.

Human Stage 4A authorization and scope-lock versions v1-v4 precede the recorded
protected execution. V4 is the final scope lock; v1-v3 remain preserved as superseded
history. CI run 29798320623 is publicly verifiable as a successful pull-request run at
scope-lock commit `ffb2415a7ed15a41cb602286ea3a13dc40c3c1ee`. The final tracked
`R/stage4a_production.R` hash is
`3da023d351cda7107463f51980aff4f95c9695cd98c75e37a8d14549b3617d97`, matching the
execution record. The execution record discloses post-response implementation repairs,
but it does not separately record a final execution commit field; PR #2 head is therefore
the reconstructible repository state, not evidence of independent custody.

The 45-row model registry is unchanged. M31 is not fitted and remains locked for the
complete 2026-2028 horizon. Aggregate artifacts remain in their original directory and
their manifest is not edited by this audit.

## Actual execution path

The protected C# builder, not the generic R engineering helpers, constructed Stage 4A
analysis frames. Stage 4A did not call `zero_fill_taxa()`, `candidate_event_links()`,
`derive_herring_event_fields()`, or the generic distance-kernel functions. The builder
used hashed analysis-checklist and source identities, filtered the allowed through-2025
period, retained all concurrent source links additively, and emitted one checklist row
rather than treating link rows as independent observations. Stage 4A used frozen source
point rings, not an exponential or Gaussian kernel. Generic PR #3 repairs therefore
cannot have altered the Stage 4A v1 results.

An additive synthetic holdout sentinel test filters by date before an explicit metadata
allow-list, then verifies that a 2026 response sentinel is absent from the returned,
summarized, RDS-cached, and CSV-emitted objects. It proves the behavior of that narrow
helper on synthetic input; it is not evidence of independent custody and does not prove
that every external system or future execution package obeys the same boundary.

Stage 3 event blocks union all source events concurrently linked to a checklist to stop
leakage between folds. They are validation blocks, not claims that chained records form
one biological event complex. PR #3's proposed anti-chaining rule addresses a different
object.

## Specification-conformance matrix

| Requirement | Finding | Evidence/qualification |
|---|---|---|
| Eligible population and start years | Conforms | SoG 2005+, WCVI 2015+, CC/NA 1988-2025; protocol, duration, travel, observer, and complete-checklist gates are in the protected builder. |
| 49 taxa, 8 guilds, specificity panel | Conforms | Frozen registries and production selectors; two panel taxa in SoG/WCVI. |
| Count-state semantics | Conforms on executed path | Numeric positive count, deterministic zero, `X`, lower bound, and ambiguity are distinct. |
| Source-point geometry | Conforms | No shoreline union or alongshore geometry entered Stage 4A. Point distance remains a defined, error-prone representation. |
| Time/ring strata and concurrent links | Conforms | Additive link counts; no checklist duplication. Fine-ring interpretation is limited by route footprint. |
| Registered model families and random effects | Core fits conform | Hurdle detection/lognormal positive-count fits use the registered fixed and random structure; ztNB2 is a visible sensitivity. |
| Four-fold validation | Conforms with qualification | Deterministic event blocks; fixed-effect population-level predictions; unseen fixed-factor levels excluded. Metrics target new validation blocks, not universal spatial transport. |
| Conditional BLUP prohibition | Conforms | Prediction code excludes conditional observer/location BLUPs. |
| Multiplicity | Conforms for individual BH columns | BH is applied within explicit model-region-outcome families. No post-result claim threshold is imposed. |
| Hierarchical partial pooling | **Defective** | Pooling families omit model ID and unit class and include duplicated M11/M12 component evidence. |
| False-date/location diagnostics | **Defective** | Exposure is cyclically shifted globally after token sorting, not within region-year; only `active_near` is shifted; simplified row-level GLMs replace the matched primary family. |
| WCVI 2-km sensitivity | **Defective relative to lock** | Uses a simplified row-level GLM, not the matched primary family. |
| Dominant-observer holdout | **Defective relative to lock** | Uses a simplified row-level GLM, not the matched primary family. |
| M26 visitation diagnostic | **Does not estimate intended process** | Quasi-Poisson event-block counts are fit to year only, with no exposure/visitation coefficient or blocked validation. |
| M32/M40 | Partial descriptive diagnostics | Simplified row-iid diagnostics; M40 covers observer richness only. They show observation structure but do not correct selection. |
| Privacy suppression | Conforms in released artifacts | Cells 1-19 are suppressed; released aggregate files contain no direct identifiers, exact coordinates, comments, or record rows. |
| Checkpoint/failure accounting | Conforms | 460 underlying checkpoints: 441 complete, 3 failed geometry, 13 insufficient support, 3 numerical failures; 28 rank-deficiency warnings remain visible. |

## Numerical and statistical findings

The report's completion counts reconcile to the aggregate tables. The 916 visible
geometry rows include M11/M12 component duplication and are not 916 independent fits;
878 are completed. Of 214 zero-truncated NB2 sensitivities, 210 converged and four CC
fits failed geometry. Rank-deficient, insufficient-support, numerical, and geometry
failures are retained rather than silently counted as successful.

The model fit uses model-based standard errors with random effects for core fits. It is
not a design-based causal estimator and does not eliminate event dependence or
preferential checklist submission. Fold predictions are fixed-effect predictions at
factor levels observed in training. Observer-disjoint folds assess observer-composition
robustness; they do not establish transfer to a new region or observation system.

Partial pooling is the principal aggregate-level failure. An audit found 4,890 released
rows with computed pooling values in 84 historical region-outcome-contrast groups, and
84/84 were cross-model or cross-unit. The error also counts duplicated M02/M11 and
M02/M12 estimates as separate evidence. Correct pooling families and the intended
relationship between primary and component rows require a human-approved repair rule.
No corrected pooled estimate is selected post hoc here.

## Interpretation of the released results

- SoG and WCVI are the registered primary and candidate-primary regions; CC and NA are
  hierarchical/descriptive only. Geographic roles cannot be silently pooled into a
  single confirmatory claim.
- The SoG specificity panel is non-null for 2/2 taxa after BH adjustment. Because the
  panel was not guaranteed biologically inert, it does not prove all focal associations
  are artifacts. It is a strong warning against species-specific causal attribution and
  against treating nominal taxon-level signals as uniquely herring-mediated. The report
  phrase “prevents a species-specific ecological reading” is too absolute if it forbids
  all descriptive ecological discussion, but appropriate if it means a uniquely causal
  species claim is not supported.
- The reported 31/32 null placebo result is not reliable evidence of design specificity
  because the placebos did not follow the locked construction or model family. The one
  WCVI false-location result is likewise not independently interpretable.
- M32 and M40 being non-null shows count-state/observer-reporting structure. M26 cannot
  support a preferential-visitation conclusion because it contains no exposure effect.
- WCVI has a 35.6% dominant-observer share and effective observer replication of 7.4.
  Six of eight guild signs agree in each of the reported dominant-observer and 2-km
  views, but both views require matched-family repair before being used as mandatory
  robustness gates.
- Lognormal versus ztNB2 sign agreement is 90/113 in primary/candidate-primary cells,
  23/41 in CC, and 36/55 in NA. Discordance is part of the result and rules out selective
  family reporting.
- M08 is an active-near versus contemporaneous-recorded-reference association. Under
  interference it is not an identified regional mass-balance or displacement effect.

## Defect-impact register

| Concern | Impact class | Affected released material | Required action |
|---|---|---|---|
| Cross-model partial pooling | `CONFIRMED_MATERIAL_STAGE4A_IMPACT` | `partial_pool_estimate`, `partial_pool_standard_error`, and any synthesis using them, all regions | Preserve v1; human-approve a versioned aggregate-only repair definition. No protected rerun is intrinsically needed. |
| False-date/location implementation | `UNKNOWN_REQUIRES_PROTECTED_RERUN` | 32 M27/M28 diagnostic rows and their interpretation | Approve a versioned matched-family, within-region-year protected diagnostic run or declare the v1 diagnostics unusable. |
| 2-km simplified fit | `UNKNOWN_REQUIRES_PROTECTED_RERUN` | WCVI 2-km sign comparison | Versioned matched-family sensitivity if its gate is retained. |
| Dominant-observer simplified fit | `UNKNOWN_REQUIRES_PROTECTED_RERUN` | WCVI holdout sign comparison | Versioned matched-family sensitivity if its gate is retained. |
| M26 missing exposure estimand | `SENSITIVITY_ONLY` | M26 interpretation, not core estimates | Redesign with an observed choice set/exposure parameter before any new protected fit. |
| M32/M40 row-iid simplification | `SENSITIVITY_ONLY` | Observation-process diagnostic uncertainty | Use only descriptively or approve clustered/matched repair. |
| Generic ingestion/ID/link/kernel defects | `FUTURE_MODEL_ONLY` | No executed Stage 4A model | Hardened additively with synthetic tests. |
| Route footprint versus fine rings | `SENSITIVITY_ONLY` | M05 fine-ring interpretation | Model-specific timing/geometry sensitivity; no blanket exclusion. |

## Gate

Do not overwrite Stage 4A v1 and do not reopen protected response records. Human review
must decide whether to: (1) merge PR #2 as immutable execution history with this audit,
(2) define and authorize an aggregate-only partial-pooling repair, (3) authorize any
protected matched-family diagnostic/sensitivity repair, and (4) permit selected
post-result Stage 4B planning. Passing software tests does not resolve identification.
