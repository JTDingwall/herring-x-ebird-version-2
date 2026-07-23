# Primary estimand and model-engine audit (v3)

**Audit date:** 2026-07-22

**Scope:** tracked specifications, executed code, and released aggregate artifacts only

**Protected data or model objects opened:** none

**Response models fitted or refitted:** none

## Conclusion

The primary M01/M02 coefficient named `active_near` is **not** an active-versus-contemporaneous-reference contrast. The executed design uses two mutually exclusive indicators and omits an `other` exposure class. Therefore:

- the M01/M02 `active_near` coefficient compares active-near checklists with the omitted other class, conditional on the other model terms;
- the `contemporaneous_reference` coefficient compares contemporaneous-reference checklists with the omitted other class; and
- M08 is the direct active-minus-reference contrast, calculated as the difference between those two fitted coefficients.

This reconstruction is complete. `STOP_PRIMARY_ESTIMAND_UNRESOLVED` is not triggered.

## Executed exposure construction

The Stage 3 builder first assigns each checklist one primary reporting region. It then considers links in that region and applies the following priority rule:

1. `active` when at least one link is 0--28 days from the recorded event and less than 5 km from the recorded source point;
2. otherwise `reference` when at least one link is 0--28 days from the recorded event and 5--20 km from the recorded source point; and
3. otherwise `other`.

If one checklist has both an active-near and a contemporaneous-reference link, `active` takes priority. All concurrent links remain represented in the additive time- and distance-stratum count covariates; the checklist remains one analytical row.

Evidence: `scripts/Stage3Phase3BlockedValidation.cs` (`ClassifyChecklist`, lines 483--505; `TimeStratum`, lines 1165--1173; `DistanceStratum`, lines 1176--1186) and `scripts/Stage4AProtectedBuilder.cs` (`AddLink`, lines 154--166).

## Exact coding table

| `active_reference_class` | Executed condition | `active_near` (A) | `contemporaneous_reference` (R) | M01/M02 role |
|---|---|---:|---:|---|
| active | any regional link at day 0--28 and distance <5 km | 1 | 0 | coefficient of interest versus `other` |
| reference | no active link, and any regional link at day 0--28 and distance >=5 and <=20 km | 0 | 1 | explicit coefficient versus `other` |
| other | neither active nor reference condition | 0 | 0 | omitted exposure category |

The high-precision 2-km analysis is a matched WCVI sensitivity cohort restriction; it does not redefine the primary 5-km indicator.

## Contrast algebra

For a fitted component with link function or linear predictor `g`, the executed fixed portion can be written as:

`eta = beta_0 + beta_A A + beta_R R + beta_T T + beta_D D + beta_X X`,

with random intercepts added by engines that successfully fit the registered mixed structure. Here `T` is the vector of nonbaseline event-window link counts, `D` is the vector of nonbaseline distance-ring link counts, and `X` contains year, protocol, log duration, log traveled distance, and observer count.

At common values of `T`, `D`, `X`, and any conditioning random effects:

- active versus other: `eta(A=1,R=0) - eta(A=0,R=0) = beta_A`;
- reference versus other: `eta(A=0,R=1) - eta(A=0,R=0) = beta_R`; and
- active versus reference: `eta(A=1,R=0) - eta(A=0,R=1) = beta_A - beta_R`.

M01/M02 release `beta_A` as `contrast=active_near`. M08 explicitly computes `beta_A - beta_R` and its covariance-based standard error as `sqrt[var(beta_A) + var(beta_R) - 2 cov(beta_A,beta_R)]` (`R/stage4a_production.R`, M08 construction).

For detection, exponentiating `beta_A` gives the active-versus-other checklist detection odds ratio. For the log positive-count component, exponentiating `beta_A` gives the active-versus-other conditional geometric-mean count ratio under the fitted log-count model. Neither is a population-abundance or causal ratio.

## Executed event windows

The prose label **late pre-spawn** is used for the month-long `immediate_pre` code. No frozen label or bound is changed.

| Code | Ecological prose label | Inclusive day bounds | Model role |
|---|---|---:|---|
| `early_pre` | early pre-spawn | -42 to -29 | omitted temporal category |
| `immediate_pre` | late pre-spawn / pre-spawn month | -28 to -1 | fitted link-count covariate |
| `spawn_start` | spawn start | 0 to 3 | fitted link-count covariate |
| `early_egg` | early egg | 4 to 14 | fitted link-count covariate |
| `late_egg` | late egg | 15 to 28 | fitted link-count covariate |
| `post` | post-spawn | 29 to 56 | fitted link-count covariate |

The release contains coefficients for five nonbaseline windows; the analysis nevertheless has six windows because early pre-spawn is the reference.

## Executed distance rings

| Code | Bounds (km) | Model role |
|---|---:|---|
| `ring_0_0p5` | 0 <= d < 0.5 | fitted link-count covariate |
| `ring_0p5_1` | 0.5 <= d < 1 | fitted link-count covariate |
| `ring_1_2` | 1 <= d < 2 | fitted link-count covariate |
| `ring_2_3` | 2 <= d < 3 | fitted link-count covariate |
| `ring_3_4` | 3 <= d < 4 | fitted link-count covariate |
| `ring_4_5` | 4 <= d < 5 | fitted link-count covariate |
| `ring_5_10` | 5 <= d < 10 | fitted link-count covariate |
| `ring_10_20` | 10 <= d <= 20.0001 | omitted spatial category |

The `20.0001` upper tolerance is the executed builder value. Ecological prose may call this the 10--20 km ring but should not claim a different computational bound.

## Model engine by released result family

| Result family | Determinable executed engine | Fallback status | v3 manuscript treatment |
|---|---|---|---|
| `M01_PRIMARY_v2` guild reference | detection: `lme4::glmer`, binomial-logit, `nAGQ=0`; positive count: REML `lme4::lmer` on log count | simplified GLM/LM fallback prohibited | may be called a sparse mixed-model reference |
| M27/M28 matched shifted-exposure placebos | same sparse `lme4` engines and formula as `M01_PRIMARY_v2` | no simplified fallback | call matched sparse mixed-model diagnostics |
| WCVI 2-km and dominant-observer sensitivities | same sparse `lme4` engines and formula as `M01_PRIMARY_v2` | no simplified fallback | call matched sparse mixed-model sensitivities; retain singular warnings |
| Legacy M01 release in `outputs/stage4a_results` | code attempted `mgcv::bam`; on error it silently used fixed-effect `glm`/`lm` | allowed in executed code; engine not recorded by component | do not use legacy M01 as the v3 guild reference |
| M02 species coefficients | code attempted `mgcv::bam`; on error it silently used fixed-effect `glm`/`lm` | allowed; aggregate output and geometry table contain no engine field | describe as released adjusted M02 coefficients, not uniformly as mixed-model coefficients |
| M05 event-window coefficients | extracted from the same legacy M01/M02 fit objects | inherits the unidentified legacy path | describe as released registered event-window coefficients; do not assert a common engine |
| M08 active-minus-reference | algebraic contrast from the same legacy M01/M02 fit objects | inherits the unidentified legacy path | contrast definition is verified; per-component engine remains unidentified |
| M29 specificity comparators | executed through the same legacy taxon fitting function as M02 | inherits the unidentified legacy path | describe as adjusted released M29 coefficients; do not assert a mixed engine |
| Zero-truncated NB2 sensitivity | custom truncated NB2 likelihood after a `MASS::glm.nb` starting fit | explicit engine/support and numerical failure states | supplementary sensitivity only |

Evidence for the final sparse engine: `metadata/stage4a_publication_sensitivity_spec_v2.yml`, `docs/18_STAGE4A_PUBLICATION_SENSITIVITY_SPEC_V2.md`, `R/stage4a_publication_sensitivity_v2.R`, and `outputs/stage4a_publication_sensitivity_v2/execution_record_v2.yml`.

The tracked release is sufficient to identify the engine for the v2 guild reference and matched sensitivities, but not for each legacy M02/M05/M08/M29 component. Determining those component engines would require an engine field in a release artifact or inspection of protected checkpoints. Neither action was authorized for v3 manuscript assembly.

## Manuscript statements requiring correction

1. Replace every statement that M01/M02 compares active-near with contemporaneous reference. The correct baseline is `other`.
2. Reserve “active versus contemporaneous reference” for M08 or for a statement that explicitly uses `beta_A - beta_R`.
3. Replace “five windows” with “six windows, of which early pre-spawn is the omitted reference and five coefficients are displayed.”
4. Replace “immediate pre-spawn” in ecological prose with “late pre-spawn” or “pre-spawn month,” while retaining the code name in technical tables.
5. Do not describe all M02, M05, M08, or M29 results as mixed-model estimates. Their per-component engine is not identifiable from the public release.
6. Explain that time and distance predictors are additive concurrent-link counts, not one mutually exclusive window and ring per checklist.

## Statements unaffected by the baseline issue

- The outcomes remain checklist detection and finite positive numeric count conditional on detection.
- The analytical population remains eligible submitted complete checklists, not birds or a probability sample of sites.
- Signs, coefficients, standard errors, confidence intervals, p-values, q-values, component sample sizes, fit statuses, singular warnings, and rank warnings are unchanged.
- The non-null M29 values and their proportional interpretation are unchanged; only the baseline wording is corrected.
- The conclusion that no common event-window trajectory emerged is unchanged.
- The privacy, 2025 response-year ceiling, concurrent-link preservation, missingness, and DFO relative-index boundaries are unchanged.

## Unresolved questions for human scientific review

1. Should the journal main text retain legacy M02 species coefficients as primary biological evidence despite the component-level engine provenance gap, or describe them as secondary until an explicitly authorized engine-identification release is produced?
2. Should a future authorized, outcome-blind process append an `engine_used` field to legacy aggregate geometry without refitting models?
3. M08 is the exact active-minus-reference contrast but is not currently the principal species display. The author should decide whether the title/abstract should foreground active-versus-other (current release) or reserve a stronger reference-zone framing for a future fully audited M08 presentation.
