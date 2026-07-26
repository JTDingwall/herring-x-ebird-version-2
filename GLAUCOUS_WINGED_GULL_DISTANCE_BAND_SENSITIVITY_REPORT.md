# Glaucous-winged Gull distance-band timing sensitivity through 26 km

## Result

The clearest positive Glaucous-winged Gull response occurred within 2 km of a
recorded herring source point. At spawn start (days 0–3), checklist reporting
odds were 32% higher than the same-band baseline and positive reported number
conditional on numeric detection was 47% higher. Conditional reported number
also increased at 2–<4 km, 4–<6 km, and 8–<10 km, but the profile was not a
simple monotonic decline with distance.

Several farther bands had negative spawn-start contrasts. Checklist reporting
was lower at 6–<10, 14–<18, 22–<24, and 24–26 km. Conditional reported number
was lower at 14–<16 and 24–26 km, while it was higher at 22–<24 km. These
non-monotonic estimates describe simultaneous, jointly adjusted associations
with recorded source points; they do not show that individual gulls moved
between distance bands.

Distance-by-timing heterogeneity was clear. The global five-period test was
Q = 128.03 on 60 df (p = 7.71 × 10^-7) for checklist reporting and
Q = 448.17 on 60 df (p = 9.03 × 10^-61) for conditional reported number.
Spawn-start heterogeneity alone was Q = 40.44 on 12 df
(p = 6.07 × 10^-5) and Q = 210.89 on 12 df
(p = 1.83 × 10^-38), respectively.

## Figure

[Glaucous-winged Gull response timing by distance, 0–26 km](outputs/post_stage4a_gwgu_distance_band_sensitivity_v1/glaucous_winged_gull_distance_band_panel_v1.png)

The figure matches the Bald Eagle layout: the two outcomes crossed with
0–<12 km and 12–26 km. All panels for a given outcome share the same
logarithmic ratio scale. Distance is encoded with an ordered colour palette,
symbols, and line types. Intervals are exact model-covariance 95% intervals.

## Spawn-start contrasts

Each ratio compares days 0–3 with days −28 to −15 within the same 2 km
source-point distance band.

| Distance band | Reporting odds ratio (95% CI) | Conditional reported-number ratio (95% CI) |
|---|---:|---:|
| 0–<2 km | 1.321 (1.123–1.553) | 1.473 (1.376–1.577) |
| 2–<4 km | 0.990 (0.870–1.126) | 1.152 (1.077–1.233) |
| 4–<6 km | 0.972 (0.865–1.092) | 1.129 (1.060–1.202) |
| 6–<8 km | 0.843 (0.759–0.936) | 0.983 (0.922–1.047) |
| 8–<10 km | 0.856 (0.771–0.952) | 1.148 (1.080–1.221) |
| 10–<12 km | 1.013 (0.917–1.118) | 1.025 (0.972–1.081) |
| 12–<14 km | 0.993 (0.877–1.125) | 1.013 (0.946–1.086) |
| 14–<16 km | 0.891 (0.802–0.989) | 0.923 (0.872–0.978) |
| 16–<18 km | 0.846 (0.765–0.936) | 0.991 (0.932–1.055) |
| 18–<20 km | 1.006 (0.904–1.118) | 0.956 (0.902–1.014) |
| 20–<22 km | 1.023 (0.927–1.128) | 1.046 (0.995–1.099) |
| 22–<24 km | 0.888 (0.803–0.982) | 1.109 (1.047–1.176) |
| 24–26 km | 0.867 (0.772–0.973) | 0.909 (0.855–0.966) |

The complete period-specific and active-days-0–14 contrasts are in
[`glaucous_winged_gull_distance_band_effects_v1.csv`](outputs/post_stage4a_gwgu_distance_band_sensitivity_v1/glaucous_winged_gull_distance_band_effects_v1.csv).

## Interval support decision

No bands were merged. All thirteen candidate 2 km intervals had ample support
in every registered timing period and both outcome samples. Across the full
model, minimum exposed-model-row support was 1,166 for checklist reporting and
603 for conditional reported number. Within 20–26 km, the corresponding
minima were 1,681 and 603. All are far above the locked minimum of 20.

The response-aware support audit selected the concrete bands before model
fitting and fit no response model. Its aggregate evidence is in
[`outputs/post_stage4a_gwgu_distance_band_sensitivity_v1_preflight/`](outputs/post_stage4a_gwgu_distance_band_sensitivity_v1_preflight/).

## Model and linkage

This analysis exactly matches the Bald Eagle v2 population, outcomes, timing
periods, 2 km bands, covariates, and random intercepts, but fits
Glaucous-winged Gull only. All 78 period-by-distance exposure counts are
included additively in one checklist row, so concurrent herring-source links
are retained without duplicating checklists as independent observations.

The reconciled 0–26 km source-link cache was reused. It contains every archived
0–20 km link with matching event day and distance tolerance and adds 625,251
protected metadata-only links through 26 km. Because link distances are
serialized to three decimals, provenance keeps archived rows printed as
20.000 km in 18–<20 km and assigns new-only rows printed as 20.000 km to
20–<22 km.

The analysis reused the archived EBD membership/date cache. It did not scan raw
EBD responses, read comments, use shoreline fields, or read any 2026–2028
record.

## Diagnostics and interpretation limits

Both fitted components converged without singularity or rank-deficiency
warnings:

- Checklist reporting: 217,037 model rows.
- Positive numeric count conditional on detection: 85,053 model rows.

This is post-result exploratory estimand refinement. Ratios describe adjusted
associations in checklist reporting and reported number; they are not
occupancy, abundance, causal effects, or individual movement. The simultaneous
distance-band coefficients may also reflect correlated exposure to multiple
nearby source events and should not be interpreted as an isolated radial
decay curve.

Bald Eagle was not refitted. No manuscript, historical Stage 4A output, or
Bald Eagle distance-band output was modified.

Complete covariance, fixed effects, support, diagnostics, heterogeneity tests,
execution metadata, and hashes are in
[`outputs/post_stage4a_gwgu_distance_band_sensitivity_v1/`](outputs/post_stage4a_gwgu_distance_band_sensitivity_v1/).
