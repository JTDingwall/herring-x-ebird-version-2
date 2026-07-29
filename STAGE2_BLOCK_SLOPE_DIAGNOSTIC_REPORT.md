# Stage 2 event-block random-slope diagnostic

## Verdict

Event-block slope variance was **not near zero across the ten strongest Stage 2
count effects**. Nine of the ten point estimates exceeded the frozen
near-zero threshold, and their 95% profile-likelihood intervals excluded zero.
Common Goldeneye was the only near-zero case. This conclusion does not depend
on Iceland Gull, whose primary fit carried a mild convergence warning.

The stop condition therefore did not trigger. The full block-aware interval
calculation was not run, as instructed, but it remains scientifically relevant:
these models show block-level heterogeneity in the estimand direction and do
not justify rewriting Section 4.4 on a near-zero-variance premise.

## Species results

The species set was frozen before these fits by sorting the completed Stage 2
conditional-positive-count active-minus-pre estimates from largest to smallest.
The model retained all Stage 2 fixed effects and the observer and generalized
location random intercepts. It replaced the event-block random intercept with a
correlated event-block intercept and one random slope in the normalized
active-minus-pre contrast direction. The normalization makes the reported
variance directly interpretable on the log count-contrast scale.

Intervals are 95% REML profile-likelihood intervals for the random-slope
standard deviation, squared to the variance scale.

| Rank | Species | Stage 2 count ratio | Positive numeric counts (blocks) | Slope variance (95% interval) | Slope SD (95% interval) | Fit |
|---:|---|---:|---:|---:|---:|---|
| 1 | Long-tailed Duck | 1.472 | 2,946 (44) | 0.01494 (0.00337–0.08189) | 0.122 (0.058–0.286) | completed |
| 2 | Surf Scoter | 1.330 | 16,632 (57) | 0.17974 (0.04714–0.44716) | 0.424 (0.217–0.669) | completed |
| 3 | Short-billed Gull | 1.310 | 22,003 (57) | 0.02867 (0.01062–0.06683) | 0.169 (0.103–0.259) | completed |
| 4 | Bonaparte's Gull | 1.251 | 4,025 (47) | 0.10111 (0.01783–0.28548) | 0.318 (0.134–0.534) | completed |
| 5 | Iceland Gull | 1.236 | 4,317 (47) | 0.03942 (0.01639–0.15402) | 0.199 (0.128–0.392) | convergence warning |
| 6 | Harlequin Duck | 1.214 | 12,030 (56) | 0.00955 (0.00271–0.02692) | 0.098 (0.052–0.164) | completed |
| 7 | Glaucous-winged Gull | 1.205 | 85,053 (57) | 0.02098 (0.00908–0.04157) | 0.145 (0.095–0.204) | completed |
| 8 | Greater Scaup | 1.197 | 4,514 (52) | 0.03999 (0.00754–0.10569) | 0.200 (0.087–0.325) | completed |
| 9 | Common Goldeneye | 1.185 | 21,195 (55) | 0.00053 (0–0.00298) | 0.023 (0–0.055) | completed |
| 10 | California Gull | 1.179 | 6,644 (55) | 0.03014 (0.00950–0.08967) | 0.174 (0.097–0.299) | completed |

The frozen operational rule required every point variance to be at most 0.0025
(SD at most 0.05) and every interval upper limit to be at most 0.01 (SD at most
0.10). Only Common Goldeneye passed both parts.

All ten profile calculations completed and none of the fits was singular.
Iceland Gull exceeded the optimizer's scaled-gradient tolerance
(0.00332 versus 0.002); its estimate and interval should be treated as
qualified. Eight of the other nine species still fail the near-zero rule, so
the overall verdict is unchanged if Iceland Gull is excluded.

## Exposed checklists by event block

An exposed checklist had a positive value in at least one of the twelve
registered period-by-zone exposure-link columns under the Stage 2 start-date
anchor.

| Metric | Value |
|---|---:|
| Exposed checklists | 93,391 |
| Total event blocks | 58 |
| Blocks with at least one exposed checklist | 57 |
| Blocks with zero exposed checklists | 1 |
| Mean per block | 1,610.2 |
| Standard deviation per block | 2,099.1 |
| 25th percentile | 44 |
| Median | 509 |
| 75th percentile | 3,160.5 |
| 90th percentile | 4,711.1 |
| Maximum | 9,489 |
| Largest-block share | 10.16% |
| Five-largest-block share | 32.34% |
| Herfindahl index | 0.04604 |
| Effective clusters, inverse Herfindahl | **21.72** |

The minimum and 10th percentile were below the repository's release threshold
of 20 and are suppressed. Zero-share blocks remain in the 58-block denominator;
they do not change the Herfindahl calculation.

## Interpretation and boundary

The nominal 58 blocks substantially overstate the concentration-adjusted
cluster count: the inverse-Herfindahl result is 21.72. Combined with
non-negligible slope variance in nine species, this diagnostic supports the
concern that event-block dependence can matter for uncertainty in the
active-minus-pre contrast.

It does **not** provide block-aware intervals or p-values for the fixed
contrasts, and it does not update Benjamini–Hochberg counts. A random-slope
variance profile answers a different question from a cluster bootstrap. No
bootstrap, wild bootstrap, CR2 sweep, reporting model, Stage 3 dose model, or
2026–2028 response record was run or accessed.

## Reproducibility and validation

- Aggregate results:
  `outputs/post_stage4a_stage2_block_slope_diagnostic_v1/`
- Restricted fitted objects:
  `data/derived/post_stage4a_stage2_block_slope_diagnostic_v1/models/`
- Specification:
  `metadata/post_stage4a_stage2_block_slope_diagnostic_spec_v1.yml`
- Execution code:
  `R/post_stage4a_stage2_block_slope_diagnostic_v1.R`

The execution record reports passing input hashes, declared join cardinalities,
privacy checks, historical-output immutability checks, and zero response
records from 2026 onward. A separate post-run validation reproduced every slope
variance directly from the ten saved model objects and verified the output hash
manifest.

