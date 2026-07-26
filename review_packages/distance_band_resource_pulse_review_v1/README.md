# Distance-band resource-pulse review package

## Review purpose

This package combines the matched Bald Eagle and Glaucous-winged Gull
distance-band sensitivities for independent scientific review. The main
question is whether these results support a manuscript statement that bird
responses to the herring resource pulse are spatially concentrated near
recorded spawning source points.

No manuscript text is changed by this package. Both analyses are post-result
exploratory estimand refinements and should remain labelled that way.

## Headline comparison

At spawn start (days 0–3 versus the same distance band's days −28 to −15
baseline), both species had their largest joint positive response within
0–<2 km:

| Species | Reporting odds ratio (95% CI) | Conditional reported-number ratio (95% CI) |
|---|---:|---:|
| Bald Eagle | 1.310 (1.139–1.507) | 1.238 (1.190–1.288) |
| Glaucous-winged Gull | 1.321 (1.123–1.553) | 1.473 (1.376–1.577) |

The conditional reported-number response remained positive at 2–<4 and
4–<6 km for both species. Checklist reporting was also positive at 2–<4 km
for Bald Eagle, but not for Glaucous-winged Gull:

| Species | Band | Reporting odds ratio (95% CI) | Conditional reported-number ratio (95% CI) |
|---|---|---:|---:|
| Bald Eagle | 2–<4 km | 1.199 (1.072–1.340) | 1.125 (1.084–1.168) |
| Bald Eagle | 4–<6 km | 1.063 (0.966–1.170) | 1.084 (1.048–1.121) |
| Glaucous-winged Gull | 2–<4 km | 0.990 (0.870–1.126) | 1.152 (1.077–1.233) |
| Glaucous-winged Gull | 4–<6 km | 0.972 (0.865–1.092) | 1.129 (1.060–1.202) |

The distance profiles are not smooth radial decay curves. In particular, the
gull analysis contains both positive and negative outer-band contrasts.
Concurrent source-event exposures are jointly estimated, and these results do
not establish individual movement, abundance, or a causal distance threshold.

## Canonical reports and figures

- [Bald Eagle report](../../BALD_EAGLE_DISTANCE_BAND_SENSITIVITY_REPORT_V2.md)
- [Bald Eagle four-panel figure](../../outputs/post_stage4a_distance_band_sensitivity_v2/bald_eagle_distance_band_panel_v2.png)
- [Glaucous-winged Gull report](../../GLAUCOUS_WINGED_GULL_DISTANCE_BAND_SENSITIVITY_REPORT.md)
- [Glaucous-winged Gull four-panel figure](../../outputs/post_stage4a_gwgu_distance_band_sensitivity_v1/glaucous_winged_gull_distance_band_panel_v1.png)

The complete estimates, heterogeneity tests, covariance matrices, diagnostics,
execution records, and hash manifests remain in their canonical output
directories:

- [`outputs/post_stage4a_distance_band_sensitivity_v2/`](../../outputs/post_stage4a_distance_band_sensitivity_v2/)
- [`outputs/post_stage4a_gwgu_distance_band_sensitivity_v1/`](../../outputs/post_stage4a_gwgu_distance_band_sensitivity_v1/)

[`artifact_manifest.csv`](artifact_manifest.csv) records the SHA-256 hashes of
the principal review artifacts.

## Candidate manuscript language for review

> Exploratory distance-band sensitivities suggested that the strongest joint
> response to herring spawning was concentrated near recorded source points.
> During spawn-start days 0–3, within 2 km, checklist-reporting odds were
> 1.31-fold higher for Bald Eagle and 1.32-fold higher for Glaucous-winged
> Gull than their respective same-band pre-spawn baselines; positive reported
> numbers were 1.24- and 1.47-fold higher. Responses beyond the nearest band
> were weaker and non-monotonic, so these associations should not be
> interpreted as a causal distance threshold or individual movement.

This wording is deliberately cautious. It does not claim that every outer
band is null or that the response decreases monotonically with distance.

## Requested review

Please review the questions in
[`CLAUDE_REVIEW_PROMPT.md`](CLAUDE_REVIEW_PROMPT.md), then report any issue
that would make the proposed spatial-concentration interpretation misleading.
