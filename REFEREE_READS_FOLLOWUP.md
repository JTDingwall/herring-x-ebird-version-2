# Follow-up corrections to `REFEREE_READS_REPORT.md`

## Result requiring attention

Using the archived coefficient covariance changes the checklist-reporting guild
test from Q = 10.981 on 6 df, p = 0.08897, to **Q = 14.971 on 6 df,
p = 0.02049**. It also changes checklist-reporting residual heterogeneity from
Q = 38.894 on 41 df, p = 0.5646, I2 = 0%, to **Q = 66.703 on 41 df,
p = 0.00679, I2 = 38.5%**. Thus the manuscript's statement that the
checklist-reporting guild test has p = 0.09 is not supported by the exact
variance calculation.

The reported-number guild result remains strongly heterogeneous and becomes
more extreme: Q increases from 76.819 to 117.340 on 6 df
(p = 5.90e-23). No guild mean changes direction, and no guild 95% interval
changes whether it excludes zero. In particular, the reported-number result
still places `roe_diving_seaduck` higher during early egg availability and
`shoreline_scavenger` higher at spawn start.

Item 8 is also corrected. The corrected paired result reconciles with the
manuscript's headline marginals: 28 of 48 reporting species and 42 of 46 count
species are positive for the primary active-minus-pre-onset contrast.

These are recomputations from archived outputs. No response model was rerun.

## Item A: paired outcome-asymmetry test

### Contrast used by the original Item 8

The proposed diagnosis is confirmed. The Item 8 code selected
`contrast == "did_active_0_14_day"` from
`outputs/post_stage4a_sog_event_study_v1/effect_estimates_v1.csv`. This is the
active-period contrast relative to the model's -28 to -15 day baseline. It is
not the primary contrast

`did_active_0_14_day - did_pre_14_day`.

Reapplying the original code path exactly reproduces the published Item 8
table: 28 positive in both outcomes, 11 count only, 1 reporting only, and 6
negative in both, with exact two-sided McNemar p = 0.00634765625. The issue is
therefore the selected contrast, not a transcription or arithmetic error.

### Corrected paired table

The corrected calculation uses `active_minus_pre_14_day` from
`outputs/post_stage4a_sog_event_study_v1_1/active_minus_pre_contrasts_v1.csv`.
The join is one-to-one by registered analysis taxon and retains all 46 species
with both outcomes estimable.

| Checklist reporting | Reported number positive | Reported number negative | Total |
|---|---:|---:|---:|
| Positive | 27 | 0 | 27 |
| Negative | 15 | 4 | 19 |
| Total | 42 | 4 | 46 |

The 15 discordant pairs are all count-positive/reporting-negative. The exact
two-sided McNemar p-value is **0.00006103515625**.

Within the paired 46-species subset, the marginal proportions are:

- Checklist reporting: 27/46 = 0.5870.
- Reported number: 42/46 = 0.9130.

These reconcile with the manuscript. The primary-contrast file contains 48
estimable reporting species, of which 28 are positive, and 46 estimable count
species, of which 42 are positive. The two reporting-estimable species excluded
from the paired table because their count models are not estimable are Surfbird
(positive reporting contrast) and Rhinoceros Auklet (negative reporting
contrast). Removing those two changes 28/48 to 27/46 while leaving the count
marginal at 42/46.

| Quantity | Original Item 8 | Corrected primary contrast |
|---|---:|---:|
| Positive in both | 28 | 27 |
| Count only | 11 | 15 |
| Reporting only | 1 | 0 |
| Negative in both | 6 | 4 |
| Reporting positive in paired set | 29/46 | 27/46 |
| Count positive in paired set | 39/46 | 42/46 |
| Exact two-sided McNemar p | 0.00634765625 | 0.00006103515625 |

## Item B: guild timing test with archived covariance

### Exact contrast variance

For each species and outcome, the timing contrast remains

`did_spawn_start - did_early_egg`.

The archived point contrast was held fixed. Its exact variance was recomputed
from the persisted coefficient covariance matrix as

`Var(spawn) + Var(early egg) - 2 Cov(spawn, early egg)`.

The same unaltered guild assignments from
`metadata/canonical_species_registry.csv` were used. All 48
reporting-estimable species and all 46 count-estimable species were retained.
The complete per-species table, including the approximate and exact standard
errors, is in
`outputs/referee_reads_followup_v1/item10_species_timing_contrasts.csv`.

### Inverse-variance weighted guild means

Values are link-scale means with 95% intervals. Positive values favor spawn
start; negative values favor early egg. The exact column uses the persisted
within-model covariance.

| Outcome | Guild | N | Approximate mean (95% CI) | Exact mean (95% CI) |
|---|---|---:|---:|---:|
| Reporting | `alcid_piscivore` | 4 | -0.0614 (-0.2094, 0.0866) | -0.0613 (-0.1787, 0.0560) |
| Reporting | `gull_roe` | 8 | 0.0633 (0.0049, 0.1216) | 0.0520 (0.0069, 0.0971) |
| Reporting | `intertidal_roe_shorebird` | 5 | -0.0623 (-0.1562, 0.0316) | -0.0620 (-0.1393, 0.0153) |
| Reporting | `piscivore_active_spawn` | 12 | -0.0005 (-0.0445, 0.0434) | -0.0012 (-0.0374, 0.0351) |
| Reporting | `roe_diving_seaduck` | 10 | 0.0182 (-0.0294, 0.0658) | 0.0161 (-0.0224, 0.0547) |
| Reporting | `shoreline_scavenger` | 4 | 0.0644 (0.0189, 0.1099) | 0.0635 (0.0257, 0.1013) |
| Reporting | `surface_vegetation_roe` | 5 | 0.0056 (-0.0478, 0.0589) | 0.0052 (-0.0383, 0.0486) |
| Reported number | `alcid_piscivore` | 3 | -0.0621 (-0.1715, 0.0473) | -0.0640 (-0.1507, 0.0228) |
| Reported number | `gull_roe` | 8 | 0.0193 (-0.0195, 0.0582) | 0.0087 (-0.0210, 0.0384) |
| Reported number | `intertidal_roe_shorebird` | 4 | -0.0527 (-0.1172, 0.0118) | -0.0516 (-0.1056, 0.0025) |
| Reported number | `piscivore_active_spawn` | 12 | 0.0027 (-0.0239, 0.0292) | 0.0024 (-0.0195, 0.0244) |
| Reported number | `roe_diving_seaduck` | 10 | -0.1126 (-0.1441, -0.0812) | -0.1152 (-0.1414, -0.0890) |
| Reported number | `shoreline_scavenger` | 4 | 0.0442 (0.0258, 0.0625) | 0.0462 (0.0311, 0.0612) |
| Reported number | `surface_vegetation_roe` | 5 | -0.0145 (-0.0504, 0.0214) | -0.0144 (-0.0437, 0.0149) |

No row changes sign or interval-exclusion status. For reported number,
`roe_diving_seaduck` remains negative with an interval excluding zero, while
`shoreline_scavenger` remains positive with an interval excluding zero. The
ecological timing statement for those guilds is therefore unchanged.

### Omnibus guild tests and residual heterogeneity

| Outcome | Quantity | Approximate | Exact |
|---|---|---:|---:|
| Reporting | Guild Q (6 df) | 10.981, p = 0.08897 | **14.971, p = 0.02049** |
| Reporting | Residual Q (41 df) | 38.894, p = 0.5646 | **66.703, p = 0.006790** |
| Reporting | Residual I2 | 0.0% | **38.5%** |
| Reported number | Guild Q (6 df) | 76.819, p = 1.62e-14 | **117.340, p = 5.90e-23** |
| Reported number | Residual Q (39 df) | 104.557, p = 6.68e-08 | **159.802, p = 1.47e-16** |
| Reported number | Residual I2 | 62.7% | **75.6%** |

The exact calculation therefore changes the checklist-reporting omnibus
conclusion at the 0.05 level and reveals residual heterogeneity that the
zero-covariance approximation did not detect. The reported-number conclusion
does not change, although both its between-guild and residual heterogeneity
statistics become larger.

### Sign of the archived covariance

The covariance between `did_spawn_start` and `did_early_egg` is positive in
every analyzed component:

| Outcome | Components | Mean covariance | Median covariance | Positive |
|---|---:|---:|---:|---:|
| Reporting | 48 | 0.002496 | 0.001307 | 48/48 |
| Reported number | 46 | 0.002116 | 0.000766 | 46/46 |
| Combined | 94 | **0.002310** | 0.001101 | **94/94** |

The manuscript's covariance-sign claim is confirmed. Because the exact
variance subtracts twice this positive covariance, setting covariance to zero
overstated every species' timing-contrast variance. The exact standard error
averages 0.801 times the approximate standard error across the 94 components.
Calling the approximation conservative is therefore correct for the
species-level variances; the exact omnibus results show the practical
consequence of that conservatism.

## Reproducibility and scope checks

The correction is generated by
`scripts/build_referee_reads_followup.R`. The script declares and tests the
one-to-one species joins, reproduces the original Item 8 table before replacing
its contrast, verifies 48/46 estimable primary-contrast marginals, validates
the identities and dimensions of all 94 covariance-bearing timing components,
and reproduces the archived approximate guild results before substituting the
exact variances.

The persisted coefficient point contrasts and frozen released timing contrasts
differ only at numerical optimizer tolerance; the maximum absolute difference
is 0.0000104. The released point contrasts were retained so that the
side-by-side comparison isolates the effect of replacing the variance
approximation.

The script was run twice from a clean process. All eight output SHA-256 hashes
were identical between runs.

Replacement artifacts:

- `outputs/referee_reads_followup_v1/item8_paired_outcome_asymmetry.csv`
- `outputs/referee_reads_followup_v1/item8_paired_species.csv`
- `outputs/referee_reads_followup_v1/item8_reporting_species_excluded_from_pair.csv`
- `outputs/referee_reads_followup_v1/item8_original_vs_corrected.csv`
- `outputs/referee_reads_followup_v1/item10_species_timing_contrasts.csv`
- `outputs/referee_reads_followup_v1/item10_guild_means.csv`
- `outputs/referee_reads_followup_v1/item10_meta_regression_tests.csv`
- `outputs/referee_reads_followup_v1/item10_covariance_summary.csv`

No file in `outputs/post_stage4a_sog_event_study_v1/` was modified. The
49-species family and canonical guild assignments were unchanged. No
2026-2028 holdout response was read, no manuscript file was edited, and no
response model was fitted or refitted.
