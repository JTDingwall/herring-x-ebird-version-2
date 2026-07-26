# Distance-band resource-pulse review package

## Review purpose

This package combines the matched Bald Eagle and Glaucous-winged Gull
distance-band sensitivities with the requested PR #17 follow-up: exact
archived-covariance profile tests, 13-band BH correction, tight
immediate-pre comparisons, terrestrial negative controls, support
reconciliation, and the event-date precision audit.

No manuscript text is changed. All analyses remain post-result exploratory
estimand refinements.

## Follow-up result that should lead the review

The 13-band waterbird profile differs between archived days 0–3 and the
equal-duration pooled pre-spawn profile for both species and outcomes:

| Species | Outcome | Wald χ² (13 df) | p |
|---|---|---:|---:|
| Bald Eagle | Reporting | 36.985 | 0.000417 |
| Bald Eagle | Positive reported number | 319.928 | 1.61 × 10⁻⁶⁰ |
| Glaucous-winged Gull | Reporting | 55.842 | 2.87 × 10⁻⁷ |
| Glaucous-winged Gull | Positive reported number | 288.012 | 7.72 × 10⁻⁵⁴ |

Neither American Robin nor Chestnut-backed Chickadee has a BH-significant
upward spike within 0–<2 km at days 0–3. The controls are not perfectly flat:
American Robin reporting changes over the full 13-band profile and is elevated
within 0–<2 km during immediate pre-spawn. That nuance is part of the report.

The fitted event-time anchor is the midpoint of the DFO `StartDate` and
`EndDate` fields, not a continuously observed biological onset. Survey cadence
is unavailable, so the proposed symmetric ±3-day refit was correctly stopped.

## Headline support and asymmetry

The 0–<2 km days 0–3 cell contains 1,166 exposed checklists, approximately
half the support in the 8–12 km bands. Reporting ratios versus the same-band
days −28 to −15 baseline are:

| Species | Reporting odds ratio (95% CI) | Positive-number ratio (95% CI) |
|---|---:|---:|
| Bald Eagle | 1.310 (1.139–1.507) | 1.238 (1.190–1.288) |
| Glaucous-winged Gull | 1.321 (1.123–1.553) | 1.473 (1.376–1.577) |

Bald Eagle reporting does **not** clear over the active days 0–14 composite:
1.083 (0.988–1.187), p = 0.089, BH q = 0.290. Its positive-number
outcome and both gull outcomes do clear that composite.

Across 312 waterbird contrasts, 104 are nominally significant and 84 survive
BH adjustment within species, outcome, and period across the 13 bands.
Multiple outer-band contrasts are significantly below their own baseline; the
full inventory is in the follow-up report and CSV.

## Canonical reports and figures

- [Follow-up report](../../DISTANCE_BAND_FOLLOWUP_REPORT.md)
- [Terrestrial control 0–<2 km figure](../../outputs/post_stage4a_distance_band_followup_v1/terrestrial_control_near_band_timing_v1.png)
- [Bald Eagle report](../../BALD_EAGLE_DISTANCE_BAND_SENSITIVITY_REPORT_V2.md)
- [Bald Eagle four-panel figure](../../outputs/post_stage4a_distance_band_sensitivity_v2/bald_eagle_distance_band_panel_v2.png)
- [Glaucous-winged Gull report](../../GLAUCOUS_WINGED_GULL_DISTANCE_BAND_SENSITIVITY_REPORT.md)
- [Glaucous-winged Gull four-panel figure](../../outputs/post_stage4a_gwgu_distance_band_sensitivity_v1/glaucous_winged_gull_distance_band_panel_v1.png)

Complete follow-up outputs are in
[`outputs/post_stage4a_distance_band_followup_v1/`](../../outputs/post_stage4a_distance_band_followup_v1/).
The historical species output directories remain unchanged.

## Candidate language for review only

> Exploratory distance-band analyses indicated that the adjusted spatial
> profile changed around the recorded herring event-date midpoint. During
> archived days 0–3, checklist-reporting odds within 2 km were 1.31-fold
> higher for Bald Eagle and 1.32-fold higher for Glaucous-winged Gull than
> their same-band days −28 to −15 baselines; positive reported numbers were
> 1.24- and 1.47-fold higher. Neither terrestrial negative control showed a
> BH-significant upward 0–<2 km spike, although American Robin reporting
> showed broader event-time structure. Responses beyond 2 km were
> non-monotonic and included significant negative contrasts, so these
> associations do not establish a causal distance threshold, abundance
> change, or individual movement.

This paragraph is a review candidate, not a manuscript edit.

## Requested review

Please answer the questions in
[`CLAUDE_REVIEW_PROMPT.md`](CLAUDE_REVIEW_PROMPT.md), citing exact artifacts
for each material criticism.
