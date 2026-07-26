# Referee reads report: Parts 1 and 2

Part 1 reference commit: `1186d8eaaa29fba3a97da85c7a38298190592f05`.

Part 2 execution code commit:
`ef5e3e5176e1b36c51323943af63b873d890deed`.

This combined report treats all analyses as post-result, exploratory estimand
refinement. Part 1 comprises ten checks that required no response-model refit.
Part 2 records the subsequently authorized versioned primary refit and the
full-family Laplace feasibility attempt. Neither part altered the frozen v1
release, changed the 49-species core family, or inspected the 2026-2028
holdout.

## Part 1: checks requiring no response-model refit

## Disagreements

1. At the Part 1 audit, `outputs/post_stage4a_sog_event_study_v1_1/` was absent from both the working tree and the worktree at the reference commit. The requested prior results were instead present in `outputs/editorial_requested_analysis_v1/` at the reference commit. Part 2 subsequently created the versioned `_v1_1` release described below.
2. The separately described `figures_ggplot2/05_supp_pretrend_and_tables.R` was not attached and does not occur in the working tree, any branch, the reflog, the attachment directory, or unreachable Git blobs. I therefore could not reproduce that exact script run. I reconstructed its four requested products from the frozen release with `scripts/build_referee_reads_part1.R`; the numerical pre-trend statements reproduce.
3. The earlier 850-source-event/51-block statement was described as an unsupported literal. Direct computation now reproduces both numbers exactly: 850 of 1,120 source events and 51 of 58 blocks have target-window links in both zones.

No other requested numerical claim failed to reproduce. Where a displayed value differs only by rounding, both values are given below.

## 1. Linearity check and binary any-link exposure

### Search result

I searched the working tree, all local and remote branches, all reflog entries, the existing worktree at the reference commit, ignored output directories, attachments, and unreachable Git blobs.

A completed binary-any-link sensitivity exists:

- Results: `outputs/editorial_requested_analysis_v1/sensitivity_comparisons.csv` at commit `5e66f8a2048965f4671fc3af30a40ac07de8d81c`.
- Execution: `outputs/editorial_requested_analysis_v1/sensitivity_execution_record.yml`, executed `2026-07-24T03:26:41Z`, code commit `6a91018`.
- Specification: all 12 additive period-by-zone link-count predictors were replaced by 0/1 any-link indicators. All 217,200 eligible checklists were retained.
- Comparison: binary A14 active-minus-pre-onset estimates against the primary additive-link A14 estimates.

The completed “linearity” release is descriptive rather than a nonlinear model:

- `outputs/editorial_requested_analysis_v1/link_count_outcome_support.csv`
- `outputs/editorial_requested_analysis_v1/event_link_distribution.csv`
- `outputs/editorial_requested_analysis_v1/linearity_execution_record.yml`, executed `2026-07-24T03:30:00Z`, code commit `f561815`.

The code declares a capped encoding (`cap_8`), but no capped result was released. I found no fitted spline, quadratic, factor-coded link count, saturation curve, or other nonlinear link-count model. Thus the binary robustness question is answerable, while functional-form linearity remains untested by a fitted nonlinear alternative.

### Binary comparison

| Outcome | Paired estimable | Same direction | Primary q < 0.05 | Direction retained among primary-significant | Still q < 0.05 under binary | Both retained |
|---|---:|---:|---:|---:|---:|---:|
| Checklist reporting | 48 | 35 | 13 | 13 | 9 | 9 |
| Reported number | 46 | 40 | 18 | 18 | 17 | 17 |

The binary encoding is therefore directionally less stable over the full family for reporting (35/48) than for reported number (40/46), but it retains the direction of every primary adjusted-significant result. Four reporting results and one count result lose BH significance.

Requested species values are ratios for binary A14 active-minus-pre-onset, with 95% CIs and binary-family q-values:

| Species | Outcome | Primary ratio | Binary ratio (95% CI) | Binary q | Direction agrees |
|---|---|---:|---:|---:|---|
| Bonaparte's Gull | Reporting | 1.4809 | 2.0947 (1.4409, 3.0451) | 0.00103 | Yes |
| American Herring Gull | Reporting | 1.3906 | 1.6075 (1.1478, 2.2514) | 0.02122 | Yes |
| California Gull | Reporting | 1.3154 | 1.5457 (1.2610, 1.8946) | 0.000330 | Yes |
| Long-tailed Duck | Reported number | 1.4321 | 3.5138 (2.5176, 4.9041) | 1.72e-12 | Yes |
| Surf Scoter | Reported number | 1.3038 | 2.2442 (1.8844, 2.6727) | 5.67e-18 | Yes |
| Short-billed Gull | Reported number | 1.2998 | 1.7955 (1.5722, 2.0504) | 1.30e-16 | Yes |

Source: `outputs/editorial_requested_analysis_v1/sensitivity_comparisons.csv`.

### Link counts within period-by-zone cells

The proportions below use exposed checklists within each cell as the denominator. A checklist is one row; all concurrent links assigned to that term are counted additively.

| Period | Zone | Exposed checklists | Exactly 1 | Exactly 2 | 3 or more | Maximum |
|---|---|---:|---:|---:|---:|---:|
| Baseline | Near | 8,077 | 59.6% | 21.7% | 18.7% | 9 |
| Baseline | Reference | 25,992 | 56.4% | 15.6% | 28.0% | 20 |
| Early pre | Near | 4,512 | 69.9% | 14.8% | 15.3% | 10 |
| Early pre | Reference | 15,467 | 64.6% | 12.0% | 23.4% | 19 |
| Immediate pre | Near | 4,587 | 71.4% | 13.7% | 14.9% | 10 |
| Immediate pre | Reference | 15,169 | 64.2% | 11.5% | 24.3% | 20 |
| Spawn start | Near | 2,992 | 68.2% | 15.7% | 16.1% | 8 |
| Spawn start | Reference | 9,759 | 65.0% | 12.6% | 22.5% | 18 |
| Early egg | Near | 7,018 | 63.1% | 18.2% | 18.7% | 11 |
| Early egg | Reference | 22,927 | 59.8% | 13.7% | 26.5% | 20 |
| Late egg | Near | 8,712 | 59.3% | 22.0% | 18.7% | 10 |
| Late egg | Reference | 28,655 | 55.8% | 16.9% | 27.3% | 23 |

Source: the hash-verified through-2025 event metadata and source-link inventory. Released aggregate: `outputs/referee_reads_v1/item1_period_zone_link_distribution.csv`.

Multiple-link exposure is not rare: 28.6%-44.2% of exposed checklists have at least two links, depending on the cell. The additive-link functional-form assumption is therefore consequential and not close to untestable.

## 2. Specificity comparators

The manuscript's six-value series is the raw within-period near/reference ratio, not a baseline-referenced `did_` series. The column is `ratio` on rows where `contrast_type == "near_minus_reference"` and `contrast == "near_minus_reference_<period>"`. Consequently, the baseline ratios need not equal 1.00.

Standard errors below are on the fitted link scale; intervals are ratios on the natural scale.

| Species | Period | Near/reference ratio | Link-scale SE | Ratio 95% CI |
|---|---|---:|---:|---:|
| Gadwall | Baseline | 0.8838 | 0.0491 | 0.8027-0.9731 |
| Gadwall | Early pre | 0.8022 | 0.0695 | 0.7001-0.9192 |
| Gadwall | Immediate pre | 0.8557 | 0.0716 | 0.7437-0.9846 |
| Gadwall | Spawn start | 0.8995 | 0.0827 | 0.7649-1.0576 |
| Gadwall | Early egg | 0.9093 | 0.0561 | 0.8147-1.0150 |
| Gadwall | Late egg | 0.9245 | 0.0476 | 0.8422-1.0148 |
| Northern Shoveler | Baseline | 0.9965 | 0.0548 | 0.8950-1.1095 |
| Northern Shoveler | Early pre | 1.0063 | 0.0880 | 0.8469-1.1957 |
| Northern Shoveler | Immediate pre | 1.1271 | 0.0789 | 0.9657-1.3154 |
| Northern Shoveler | Spawn start | 1.2311 | 0.0908 | 1.0304-1.4708 |
| Northern Shoveler | Early egg | 1.2412 | 0.0557 | 1.1129-1.3844 |
| Northern Shoveler | Late egg | 1.2619 | 0.0482 | 1.1481-1.3870 |

The requested baseline-referenced contrasts are:

| Species | Contrast | Ratio | Link-scale SE | Ratio 95% CI | q |
|---|---|---:|---:|---:|---:|
| Gadwall | `did_active_0_14_day` | 1.0259 | 0.0673 | 0.8992-1.1705 | 0.7037 |
| Gadwall | `did_late_egg` | 1.0460 | 0.0676 | 0.9162-1.1942 | 0.5059 |
| Northern Shoveler | `did_active_0_14_day` | 1.2429 | 0.0728 | 1.0776-1.4334 | 0.00564 |
| Northern Shoveler | `did_late_egg` | 1.2663 | 0.0731 | 1.0974-1.4613 | 0.00246 |

Thus 1.2663 is Northern Shoveler's `did_late_egg`, and 1.2429 is its `did_active_0_14_day`. The source file already carries standard errors and 95% intervals, so covariance recovery was unnecessary for this item.

Source: `outputs/post_stage4a_sog_event_study_v1/specificity_comparators_v1.csv`.

## 3. Checklist prevalence for named species

Reporting prevalence uses 217,200 eligible checklists as the denominator. “Quantified positive” preserves the finite positive numeric state and does not include `X`, lower-bound, or ambiguity-affected records. No named-species count falls below the suppression threshold of 20.

| Species | Reporting prevalence | Quantified positive reports |
|---|---:|---:|
| Bonaparte's Gull | 1.902% | 4,025 |
| American Herring Gull | 0.901% | 1,851 |
| California Gull | 3.240% | 6,644 |
| Iceland Gull | 2.193% | 4,317 |
| Glaucous-winged Gull | 41.232% | 85,053 |
| Short-billed Gull | 10.698% | 22,003 |
| Western Gull | 0.335% | 712 |
| Glaucous Gull | 0.087% | 185 |
| Long-tailed Duck | 1.413% | 2,946 |
| Surf Scoter | 7.904% | 16,632 |
| White-winged Scoter | 2.272% | 4,706 |
| Harlequin Duck | 5.627% | 12,030 |
| Barrow's Goldeneye | 5.172% | 10,960 |
| Bufflehead | 23.623% | 50,039 |
| Common Goldeneye | 10.014% | 21,195 |
| Greater Scaup | 2.168% | 4,514 |
| Common Merganser | 12.976% | 27,776 |
| Red-breasted Merganser | 6.276% | 13,364 |
| Common Loon | 7.174% | 15,359 |
| Pacific Loon | 2.846% | 6,049 |
| Double-crested Cormorant | 13.564% | 29,011 |
| Bald Eagle | 38.775% | 83,359 |
| Great Blue Heron | 23.489% | 50,285 |
| Mallard | 39.548% | 81,526 |
| American Wigeon | 16.854% | 34,665 |
| Northern Pintail | 7.054% | 14,278 |
| Brant | 1.803% | 3,796 |
| Surfbird | 0.497% | 1,063 |
| Rhinoceros Auklet | 0.844% | 1,816 |
| Gadwall | 6.393% | 13,337 |
| Northern Shoveler | 5.233% | 10,662 |

Source: `diagnostics/D5_species_support_prevalence.csv`. Released selection: `outputs/referee_reads_v1/item3_named_species_prevalence.csv`.

## 4. Western Gull singular fit

The collapsed component is the event-block random intercept:

- Event-block variance: **0**
- Observer variance: 0.061364
- Generalized-location variance: 0.002041
- Residual variance: 0.074802

The active-minus-pre-onset point estimate is 0.07014 on the link scale, or a ratio of 1.0727 (95% CI 0.9931-1.1586), with q = 0.1488. It is **not** among the 18 adjusted-significant reported-number contrasts.

Sources: `outputs/editorial_requested_analysis_v1/model_diagnostics.csv` and `active_minus_pre_contrasts.csv`.

## 5. Event and block representation across zones

Join cardinalities were declared and checked:

- Event metadata: one row per `analysis_event_token`.
- Source links to event metadata: many-to-one.
- Each checklist to `event_block_token`: many-to-one, with one block token per checklist because blocks are connected components.

Results:

- **850 of 1,120 source events** contributed at least one target-window near link and at least one target-window reference link.
- **51 of 58 event blocks** did the same.
- There were 93,342 checklists exposed in at least one of the six period-by-zone cells. **93,152 (99.796%)** belonged to a block represented in both zones.

The exact fraction of coefficient-identifying variation that is within-block is not uniquely recoverable as a scalar from the persisted fit summaries because the primary contrast is a multi-term, covariate-adjusted mixed-model contrast. The requested fallback checklist-support share is therefore reported.

The denominators include all 1,120 source events and all 58 blocks in the frozen inventory. Of these, 1,104 events and 57 blocks contribute at least one link to the six modeled event-time periods; the both-zone counts remain 850 and 51.

Source: hash-verified through-2025 event metadata/source links. Released aggregate: `outputs/referee_reads_v1/item5_event_block_zone_representation.csv`.

## 6. Baselines for standardized predictions

These are the `observed_covariate_standardization` predictions with random intercepts set to zero. To make “each side” unambiguous, both zone-specific natural-scale predictions and the baseline-adjusted pre/active sides are shown.

### Glaucous-winged Gull reporting

- Pre-onset near: 21.55% (95% CI 18.48%-24.62%); reference: 20.78% (17.83%-23.74%).
- Active near: 22.56% (19.40%-25.72%); reference: 19.79% (16.94%-22.65%).
- Baseline-adjusted pre side: -0.30 percentage points (-1.22 to 0.62).
- Baseline-adjusted active side: 1.70 percentage points (0.79 to 2.60).
- Active minus pre: **2.00 percentage points** (1.10 to 2.91).

### Short-billed Gull reported number

- Pre-onset near: 10.67 (9.58-11.76); reference: 10.79 (9.74-11.84).
- Active near: 14.52 (13.06-15.98); reference: 11.30 (10.20-12.39).
- Baseline-adjusted pre side: 0.45 (-0.17 to 1.07).
- Baseline-adjusted active side: 3.79 (3.04-4.55).
- Active minus pre: **3.34 birds** (2.59-4.09).

### Surf Scoter reported number

- Pre-onset near: 34.22 (27.56-40.89); reference: 33.01 (26.71-39.31).
- Active near: 46.72 (37.61-55.83); reference: 34.56 (27.97-41.16).
- Baseline-adjusted pre side: -1.48 (-3.86 to 0.90).
- Baseline-adjusted active side: 9.47 (6.11-12.83).
- Active minus pre: **10.94 birds** (7.43-14.46).

Source: `outputs/editorial_requested_analysis_v1/absolute_predictions.csv`, released selection `outputs/referee_reads_v1/item6_absolute_predictions.csv`. All three manuscript values have traceable provenance.

## 7. Supplementary tables and pre-trend statements

Because the separately described source script was absent, I reconstructed the requested products from the frozen release without fitting a model:

- `figures_out/tableS_primary_contrast_49x2.csv`: 98 rows, exactly 49 species x 2 outcomes; contains species, outcome, ratio, CI, q-value, n, and status. Failed components remain explicit statuses.
- `figures_out/tableS_species_support.csv`: 49 rows with detections, quantified positive reports, prevalence, and both fit statuses.
- `figures_out/tableS_pretrend_summary.csv`: four outcome-by-pre-window rows.
- `figures_out/figS_pretrend.png` and `.pdf`.

All four §3.6 statements reproduce:

1. Checklist reporting: zero BH-significant pre-trends in days -14 to -8 and zero in days -7 to -1.
2. The largest median ratio over either pre-window and either outcome is reported number during days -7 to -1: 1.021071, displayed as 1.021.
3. Great Blue Heron reported number during days -7 to -1 is 1.0660 (95% CI 1.0289-1.1045).
4. Iceland Gull reported number during days -7 to -1 is 1.2529 (1.1069-1.4181). Both have q = 0.009436, displayed as q = 0.009.

Sources: `outputs/post_stage4a_sog_event_study_v1/effect_estimates_v1.csv`, `outputs/editorial_requested_analysis_v1/active_minus_pre_contrasts.csv`, and `diagnostics/D5_species_support_prevalence.csv`.

## 8. Paired outcome-asymmetry comparison

The two outcome tables were joined one-to-one by `analysis_taxon_id`. All 46 species with an estimable reported-number model had an estimable reporting model.

| | Reported number positive | Reported number negative |
|---|---:|---:|
| Reporting positive | 28 | 1 |
| Reporting negative | 11 | 6 |

- Positive in both: 28
- Positive in reported number only: 11
- Positive in reporting only: 1
- Negative in both: 6
- Exact two-sided McNemar test on 12 discordant pairs: **p = 0.00634765625**
- Reporting-positive marginal: 29/46 = **63.0%**
- Reported-number-positive marginal: 39/46 = **84.8%**

This replaces neither the manuscript proportions nor the caution about dependence across species. It only corrects the within-species pairing error in the former Fisher test.

A permutation respecting shared checklists, event blocks, observers, and locations is not straightforward from released species-level coefficients. It would require a prespecified row-level permutation and repeated response-model fits, so it was not run.

Source: `outputs/post_stage4a_sog_event_study_v1/effect_estimates_v1.csv`. Released aggregate: `outputs/referee_reads_v1/item8_paired_outcome_asymmetry.csv`.

## 9. Effort covariates as possible post-exposure variables

Cells are checklist-level and nonexclusive where a checklist has qualifying links in more than one zone/window. Values are mean and median [IQR].

| Zone | Window | Variable | Checklists | Mean | Median [IQR] |
|---|---|---|---:|---:|---:|
| Near | Days -14 to -1 | Duration, min | 8,160 | 53.098 | 40 [20, 70] |
| Near | Days -14 to -1 | Travel distance, km | 8,160 | 1.027 | 0.561 [0, 1.679] |
| Near | Days -14 to -1 | Observers | 8,160 | 1.377 | 1 [1, 2] |
| Near | Days 0 to 14 | Duration, min | 9,143 | 54.715 | 41 [20, 73] |
| Near | Days 0 to 14 | Travel distance, km | 9,143 | 1.032 | 0.600 [0, 1.674] |
| Near | Days 0 to 14 | Observers | 9,143 | 1.410 | 1 [1, 2] |
| Reference | Days -14 to -1 | Duration, min | 26,544 | 54.924 | 41 [20, 75] |
| Reference | Days -14 to -1 | Travel distance, km | 26,544 | 1.085 | 0.600 [0, 1.796] |
| Reference | Days -14 to -1 | Observers | 26,544 | 1.360 | 1 [1, 2] |
| Reference | Days 0 to 14 | Duration, min | 28,855 | 56.370 | 44 [20, 76] |
| Reference | Days 0 to 14 | Travel distance, km | 28,855 | 1.111 | 0.656 [0, 1.870] |
| Reference | Days 0 to 14 | Observers | 28,855 | 1.393 | 1 [1, 2] |

Near-zone travel distance changes little: mean +0.004 km and median +0.039 km from pre-onset to active. The reference zone changes somewhat more: mean +0.026 km and median +0.056 km. Duration increases in both zones, and observer-count medians/IQRs are unchanged. These descriptive summaries do not show a distinctive near-zone route-distance shift after onset, but they do not establish that the covariates are pre-exposure or remove post-treatment-bias concerns.

Source: hash-verified through-2025 event metadata/source links. Released aggregate: `outputs/referee_reads_v1/item9_effort_descriptives.csv`.

## 10. Timing heterogeneity without response-model refitting

### Registry timing and method

Guild assignments were taken without alteration from `metadata/canonical_species_registry.csv`, column `guild_ids`. They first appear at commit `80f0b52ab5529716d7007b800536ebc042d74779` on **2026-07-19 20:02:06 -07:00**. All 58 assignments are unchanged in the 2026-07-20 denominator-repair commit. The event-study results first appear at commit `46b154ceeaf78bde301196021088fa4840e96ca1` on **2026-07-23 00:29:09 -07:00**. The guild assignments therefore predate the event-link results.

For each species and outcome, the timing contrast is:

`did_spawn_start - did_early_egg`

Positive values mean a larger near/reference contrast at spawn start than during early egg. All 48 reporting-estimable species and all 46 reported-number-estimable species were retained; none was dropped.

The persisted event-study checkpoints contain released effects and standard errors but not the fitted coefficient covariance matrix. Accordingly, variance was computed as `SE_spawn_start^2 + SE_early_egg^2`, equivalent to setting their covariance to zero. This is the archived-SE approximation requested when exact covariance is unavailable; it must not be described as exact.

### Inverse-variance weighted guild means

Means and 95% CIs are on the link scale; the final column exponentiates the mean.

| Outcome | Guild | Species | Mean timing contrast (95% CI) | Ratio |
|---|---|---:|---:|---:|
| Reporting | `alcid_piscivore` | 4 | -0.0614 (-0.2094, 0.0866) | 0.9405 |
| Reporting | `gull_roe` | 8 | 0.0633 (0.0049, 0.1216) | 1.0653 |
| Reporting | `intertidal_roe_shorebird` | 5 | -0.0623 (-0.1562, 0.0316) | 0.9396 |
| Reporting | `piscivore_active_spawn` | 12 | -0.0005 (-0.0445, 0.0434) | 0.9995 |
| Reporting | `roe_diving_seaduck` | 10 | 0.0182 (-0.0294, 0.0658) | 1.0183 |
| Reporting | `shoreline_scavenger` | 4 | 0.0644 (0.0189, 0.1099) | 1.0666 |
| Reporting | `surface_vegetation_roe` | 5 | 0.0056 (-0.0478, 0.0589) | 1.0056 |
| Reported number | `alcid_piscivore` | 3 | -0.0621 (-0.1715, 0.0473) | 0.9398 |
| Reported number | `gull_roe` | 8 | 0.0193 (-0.0195, 0.0582) | 1.0195 |
| Reported number | `intertidal_roe_shorebird` | 4 | -0.0527 (-0.1172, 0.0118) | 0.9487 |
| Reported number | `piscivore_active_spawn` | 12 | 0.0027 (-0.0239, 0.0292) | 1.0027 |
| Reported number | `roe_diving_seaduck` | 10 | -0.1126 (-0.1441, -0.0812) | 0.8935 |
| Reported number | `shoreline_scavenger` | 4 | 0.0442 (0.0258, 0.0625) | 1.0451 |
| Reported number | `surface_vegetation_roe` | 5 | -0.0145 (-0.0504, 0.0214) | 0.9856 |

### Overall tests and residual heterogeneity

- Reporting: guild-difference Q = 10.981 on 6 df, **p = 0.08897**. Residual Q = 38.894 on 41 df, p = 0.5646; residual I² = 0%.
- Reported number: guild-difference Q = 76.819 on 6 df, **p = 1.62e-14**. Residual Q = 104.557 on 39 df, p = 6.68e-08; residual I² = 62.7%.

The reporting outcome does not reject equal guild means at 0.05. Reported number shows strong guild differences plus substantial residual heterogeneity. In particular, the inverse-variance means are negative for `roe_diving_seaduck` and positive for `shoreline_scavenger`; this is not a simple common “spawn-start peak” across guilds. Because the exact within-model covariance was not persisted, these tests are approximate and should be labeled accordingly.

Sources: `outputs/post_stage4a_sog_event_study_v1/effect_estimates_v1.csv` and `metadata/canonical_species_registry.csv`. Released species contrasts and meta-regression results are in `outputs/referee_reads_v1/item10_species_timing_contrasts.csv`, `item10_guild_means.csv`, and `item10_meta_regression_tests.csv`.

## Part 1 limits before authorized Part 2

1. A fitted nonlinear link-count response (spline, factor-coded counts, quadratic, cap, or saturation model) is not on disk. Answering functional-form linearity beyond the binary comparison and descriptive support tables requires a new response-model fit.
2. Exact spawn-start/early-egg covariance was not persisted in the original event-study checkpoints. Part 2 resolves the availability problem by persisting fixed effects and covariance matrices for 96 fitted components. The approximate Item 10 calculations above were not retroactively replaced.
3. A dependence-preserving permutation for the paired outcome-asymmetry question is not available from aggregate coefficients and would require a prespecified row-level scheme plus repeated response-model fits.
4. The exact supplied supplementary-table script is unavailable. Its requested artifacts and numerical assertions were reconstructed, but the absent script itself cannot be verified.

No other item required a response-model fit.

## What I ran, wrote, skipped, and why

### Ran

- Read-only Git searches over the working tree, all refs, the reflog, the existing reference-commit worktree, ignored outputs, attachments, and unreachable blobs.
- Hash/cardinality-gated reads of only the through-2025 event metadata and source-link inventory.
- `Rscript --vanilla scripts/build_referee_reads_part1.R` with the existing project library. The script declares and tests all event/link, outcome-pair, support, and guild join cardinalities.
- Descriptive aggregation for items 1, 5, and 9; table extraction for items 2-4 and 6-7; the exact McNemar test for item 8; and the requested species-level inverse-variance meta-regressions for item 10.
- Visual inspection of `figures_out/figS_pretrend.png`.

### Wrote

- `REFEREE_READS_REPORT.md`
- `scripts/build_referee_reads_part1.R`
- Privacy-safe aggregates in `outputs/referee_reads_v1/`
- The five reconstructed supplementary products in `figures_out/`

### Skipped

- No protected Stage 4A or event-study response model was rerun.
- No new nonlinear, permutation, Laplace, negative-binomial, or placebo model was fit.
- No 2026-2028 holdout record was read.
- No source checklist, observer, locality, event, block, or coordinate identifier was released.
- Nothing in `outputs/post_stage4a_sog_event_study_v1/` was modified, regenerated, or overwritten.
- The supplied DOCX was not edited.

## Part 2: authorized versioned refit

Human authorization was supplied on 2026-07-25 as: "Run Part 2 now." The
repository's exact through-2025 post-result-refinement acknowledgement was set
only in the execution process. The work ran in the isolated
`codex/referee-part2-run` worktree so the manuscript branch and Part 1
artifacts were not changed during execution.

Both fixture modes passed before production:

- `POST_STAGE4A_SOG_EVENT_STUDY_FIXTURE=PASS`
- `POST_STAGE4A_LAPLACE_SENSITIVITY_FIXTURE=PASS`

The full primary production refit returned:

`POST_STAGE4A_SOG_EVENT_STUDY_GATE=PASS_PENDING_HUMAN_POST_STAGE4A_EVENT_STUDY_REVIEW`

The execution used all concurrent event links additively. The source-link
hash, event/link join cardinality, concurrent-link pairing, year,
registered-taxon, and frozen-output gates passed. It attempted all 100
registered components and wrote 100 component summaries: 96 contain
dimensionally valid fixed-effect and covariance matrices, while four preserve
the explicit failure status. The eight-file output manifest recomputes exactly
(8/8 SHA-256 matches).

### Active minus pre-onset result

The archived contrast is:

`did_active_0_14_day - did_pre_14_day`

BH adjustment was performed within each complete 49-species core family.

| Outcome | Registered core species | Estimable | Adjusted-significant positive | Adjusted-significant negative |
|---|---:|---:|---:|---:|
| Checklist reporting | 49 | 48 | 13 | 0 |
| Reported number conditional on a positive numeric report | 49 | 46 | 18 | 0 |

These are the prespecified acceptance counts. The absence of
adjusted-significant negatives is an observed result, not an execution gate.

### Component status

| Status | Components |
|---|---:|
| Completed | 95 |
| Completed with singular warning | 1 |
| Failed prespecified support | 3 |
| Failed numerical fit, no fallback | 1 |

The three support failures are the reported-number components for Surfbird,
Rhinoceros Auklet, and Glaucous Gull. The numerical failure is Glaucous Gull
reporting. They remain visible in the diagnostics; no fallback model was
silently substituted.

### Gradient limitation

The locked local R library did not contain `numDeriv`. The runner therefore
recorded `gradient_check_status = numDeriv_unavailable` for all 96 fitted
components and `not_fitted` for the other four. `max_abs_gradient` is `NA`, as
designed. No gradient distribution can be reported from this execution, and
the completed status must not be interpreted as a successful gradient check.

### Laplace sensitivity

The exact full-family `nAGQ = 1` reporting sensitivity was attempted with four
workers for one hour. All four workers remained responsive and CPU-bound, but
none of the first four fits completed. The attempt produced 0/49 checkpoints
and 0/49 model summaries before the process ceiling.

Status:

`COMPUTATIONALLY_INFEASIBLE_NO_COMPLETED_FIT_WITHIN_ONE_HOUR`

No smaller adjusted-significant-only family was substituted because its BH
q-values would not be comparable with the 49-species primary family. The
Laplace attempt yields no effect estimate and no evidence for or against
robustness.

### Part 2 artifacts and governance

Primary versioned outputs:

- `outputs/post_stage4a_sog_event_study_v1_1/`
- `outputs/post_stage4a_sog_event_study_model_summaries_v1/`

Laplace feasibility record:

- `outputs/post_stage4a_sog_event_study_laplace_v1/infeasibility_record.yml`

Final checks:

- The hash-locked `outputs/post_stage4a_sog_event_study_v1/` release was not
  modified or regenerated.
- No 2026-2028 response record was read.
- No M31 fit or interim holdout look was performed.
- No raw checklist, observer, locality, event, block, or coordinate identifier
  was released.
- The official repository privacy scanner passed across 775 text files in the
  isolated Part 2 worktree.
- The primary execution record reports `records_2026_plus_read: 0`,
  `comments_read: 0`, `shoreline_fields_read: 0`, source-link hash gate `PASS`,
  and concurrent-link pairing gate `PASS`.
- Scientific interpretation remains pending human review.
