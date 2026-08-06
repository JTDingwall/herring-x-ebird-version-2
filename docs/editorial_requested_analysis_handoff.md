# Editorial-requested analysis handoff

Status: post-result exploratory refinement requested during editorial review; frozen before these fits; **not a preregistration**.

## Answer-first findings

The verified analysis population contains 217,200 eligible Strait of Georgia checklists (2005–2025), 1,120 source herring events grouped into 58 event blocks, 29,248 observer clusters, 22,980 generalized locations, and 49 support-qualified species.

For the formal A14 timing contrast—duration-weighted active (0–14 d) minus duration-weighted pre-onset (−14 to −1 d), after the same baseline-adjusted near/reference construction—checklist reporting was estimable for 48 species. 13 were BH-significant at q<0.05, all in the positive direction; the median link-scale estimate was 0.022 (IQR -0.039 to 0.133).

Conditional positive numeric count was estimable for 46 species. 18 A14 contrasts were BH-significant, all positive; the median link-scale estimate was 0.070 (IQR 0.021 to 0.129). These are conditional associations among quantified reports, not flock-size or abundance effects.

The finite-numeric-versus-X observation-process model was estimable for 41 species. No A14 contrast survived the separate 49-species BH family (minimum q approximately 0.545); 30 completed fits carried singular warnings. This does not establish a known direction of selection bias.

Absolute standardization makes the ratios less dramatic. For example, the observed-covariate A14 contrast was 3.34 units in the modeled conditional arithmetic-mean numeric count for Short-billed Gull (95% CI 2.59 to 4.09), and 2.00 percentage points for Glaucous-winged Gull checklist reporting (95% CI 1.10 to 2.91). These set all random intercepts and nonselected link predictors to zero before averaging over the observed adjustment distribution.

## Scientific interpretation

The direct A14 results support wording that active-period event-linked associations often exceeded pre-onset associations for reporting and conditional numeric count. They do not identify causal herring effects, abundance change, consumption, or movement. The estimates share checklists, event blocks, observers, and locations; no independence-based meta-analysis or combined-p-value claim is made.

Observed summaries are unadjusted and their period-zone cells are nonexclusive because different source-event links can place one checklist in multiple cells. Model-based predictions are population-level fixed-effect predictions for eligible 2005–2025 checklists, with all random intercepts set to zero.

## Implementation reconciliation

Each herring source event remains atomic. Concurrent source events connected through checklist memberships were unioned into 58 validation/event-block components. Every checklist is one model row, all concurrent source links contribute additively to its 12 joint period-by-zone counts, and the checklist receives the single event-block token of its connected component. The same biological source event or connected block can contribute both near and reference observations; 850 source events and 51 blocks do so.

The fitted implementation matches the manuscript’s one-checklist-row, additive-link description. The repository map’s “239,935 lines” refers to 239,934 data records plus the header and is a documentation line-count convention, not an analytical cardinality discrepancy. Event blocks are leakage-control components, not inferred biological spawning complexes.

## Sensitivity and validation status

`binary_any_link` / `checklist_reporting`: 35/48 finite estimates retained the primary sign; median absolute link-scale change 0.081.

`binary_any_link` / `conditional_positive_numeric_count`: 40/46 finite estimates retained the primary sign; median absolute link-scale change 0.077.

The `glmmTMB_binomial_logit_Laplace` validation for Iceland Gull completed with A14 estimate 0.298 versus 0.255 under the primary engine; the direction was concordant.

The `glmmTMB_zero_truncated_nbinom2` validation for Glaucous-winged Gull completed with A14 estimate 0.224 versus 0.157 under the primary engine; the direction was concordant.

A warm-started Iceland Gull nAGQ=1 probe already exceeded roughly one hour without an estimate, so the frozen 30-minute representative-fit budget classifies that engine as infeasible here. Representative `glmmTMB` validation remains partial because the frozen set contains three species per outcome and each fit has a 30-minute wall-time cap. A fixed-effect-only truncated count model is not treated as equivalent.

No alternative event-study radius was frozen before response inspection, so none was invented. A shifted-onset placebo could not be placed within the frozen ±28-day link window without overlapping the real active window or risking contamination by concurrent known spawning. It is recorded infeasible rather than forced.

Event-block support and influence potential are reported, but leave-one-block-out and the prespecified 999-resample dependence-preserving bootstrap were not completed after higher-priority computation. Therefore no nominal family-level or bootstrap interval is reported.

## Failures and warnings

- Surfbird — conditional_positive_numeric_count: `failed_insufficient_support`.
- Rhinoceros Auklet — conditional_positive_numeric_count: `failed_insufficient_support`.
- Glaucous Gull — checklist_reporting: `failed_numerical_fit_no_fallback`.
- Glaucous Gull — conditional_positive_numeric_count: `failed_insufficient_support`.
- Red-throated Loon — finite_numeric_vs_x: `failed_insufficient_support`.
- Surfbird — finite_numeric_vs_x: `failed_insufficient_support`.
- Western Gull — finite_numeric_vs_x: `failed_insufficient_support`.
- Rhinoceros Auklet — finite_numeric_vs_x: `failed_insufficient_support`.
- Common Goldeneye — finite_numeric_vs_x: `failed_numerical_fit_no_fallback`.
- Marbled Murrelet — finite_numeric_vs_x: `failed_insufficient_support`.
- Western Grebe — finite_numeric_vs_x: `failed_insufficient_support`.
- Glaucous Gull — finite_numeric_vs_x: `failed_insufficient_support`.

Additional warnings: 30 finite-versus-X fits and 1 conditional-count fit(s) were singular; one Pacific Loon count fit completed with optimizer code 0 but retained a gradient warning. All warning rows remain in the released tables and multiplicity families.

## What belongs in the manuscript versus Supplement

- Main-text candidates: verified population/support; formal A14 family results; cautious absolute-scale examples; explicit observation-process result; engine and dependence limitations.
- Supplement: complete 49-species A14/A7 tables, all observed cells, prediction configurations, diagnostics, finite-versus-X family, link-count support, sensitivity comparisons, and failure logs.
- Do not call checklist reporting occupancy or detection probability, do not call conditional numeric count flock size, and do not describe this work as preregistered.

## Release QA

The expanded numerical gate passed all 30 checks, including checkpoint agreement for core estimates and predictions, auxiliary-table key and algebra checks, positive-definite alternative-engine Hessians, privacy-safe columns, and zero reads of 2026+ holdout records. The complete repository fixture suite, repository privacy scan, and 315-field dictionary missing-field gate also passed. The recursive SHA-256 output manifest was regenerated after all release artifacts.

## Reproducibility and locations

- Frozen specification: `docs/editorial_requested_analysis_spec.md` (commit `a0c4ef5`).
- Results: `outputs/editorial_requested_analysis_v1/`.
- Status: `outputs/editorial_requested_analysis_v1/analysis_status.csv`.
- Field dictionary: `docs/editorial_requested_analysis_data_dictionary.md`.
- Reproducibility record: `docs/editorial_requested_analysis_reproducibility.md`.
- Figures: `outputs/editorial_requested_analysis_v1/figures/`.
