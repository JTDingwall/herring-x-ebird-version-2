# Bald Eagle distance-band timing sensitivity through 26 km

## Result

The Bald Eagle spawn-start response is concentrated near recorded herring
source points. Checklist reporting was 31% higher than the same-band baseline
within 2 km, and positive reported number conditional on numeric detection was
24% higher. The positive spawn-start response attenuated over 2–6 km. From
10 through 26 km, nearly all spawn-start intervals included 1.0 and the point
estimates clustered near the same-band baseline.

The exceptions to that broad outer-distance pattern were negative
spawn-start contrasts at 8–<10 km for both outcomes and at 18–<20 km for
checklist reporting. These localized negative contrasts should not be
interpreted as evidence that individual eagles moved between bands.

Distance-by-timing heterogeneity remained clear after extending the model
through 26 km. The global five-period test was Q = 108.26 on 60 df
(p = 0.000135) for checklist reporting and Q = 423.79 on 60 df
(p = 3.55 × 10^-56) for conditional reported number. Spawn-start
heterogeneity alone was Q = 47.31 on 12 df (p = 4.12 × 10^-6) and
Q = 235.79 on 12 df (p = 1.25 × 10^-43), respectively.

## Figure

[Bald Eagle response timing by distance, 0–26 km](outputs/post_stage4a_distance_band_sensitivity_v2/bald_eagle_distance_band_panel_v2.png)

The figure uses four panels: the two outcomes crossed with 0–<12 km and
12–26 km. All panels for a given outcome share the same logarithmic ratio
scale. Distance is encoded with an ordered colour palette plus distinct
symbols and line types. Intervals are exact model-covariance 95% intervals.

## Spawn-start contrasts

Each ratio compares days 0–3 with days −28 to −15 within the same 2 km
source-point distance band.

| Distance band | Reporting odds ratio (95% CI) | Conditional reported-number ratio (95% CI) |
|---|---:|---:|
| 0–<2 km | 1.310 (1.139–1.507) | 1.238 (1.190–1.288) |
| 2–<4 km | 1.199 (1.072–1.340) | 1.125 (1.084–1.168) |
| 4–<6 km | 1.063 (0.966–1.170) | 1.084 (1.048–1.121) |
| 6–<8 km | 0.957 (0.876–1.046) | 0.969 (0.940–1.000) |
| 8–<10 km | 0.878 (0.805–0.956) | 0.951 (0.921–0.982) |
| 10–<12 km | 1.060 (0.975–1.153) | 1.017 (0.988–1.047) |
| 12–<14 km | 1.020 (0.924–1.125) | 0.974 (0.940–1.009) |
| 14–<16 km | 1.049 (0.960–1.147) | 1.005 (0.974–1.038) |
| 16–<18 km | 1.051 (0.967–1.142) | 0.998 (0.967–1.029) |
| 18–<20 km | 0.906 (0.825–0.994) | 0.986 (0.955–1.019) |
| 20–<22 km | 1.024 (0.940–1.115) | 1.013 (0.982–1.045) |
| 22–<24 km | 1.009 (0.927–1.098) | 0.991 (0.961–1.022) |
| 24–26 km | 1.036 (0.945–1.137) | 1.019 (0.987–1.053) |

The complete period-specific and active-days-0–14 contrasts are in
[`bald_eagle_distance_band_effects_v2.csv`](outputs/post_stage4a_distance_band_sensitivity_v2/bald_eagle_distance_band_effects_v2.csv).

## Interval support decision

No bands were merged. All thirteen candidate 2 km intervals had ample support
in every registered timing period and both outcome samples. Across the full
model, minimum exposed-model-row support was 1,166 for checklist reporting and
736 for conditional reported number. Within the newly added 20–26 km range,
the corresponding minima were 1,681 and 864. All are far above the locked
minimum of 20.

The response-aware support audit selected the concrete bands before model
fitting and fit no response model. Its aggregate evidence is in
[`outputs/post_stage4a_distance_band_sensitivity_v2_preflight/`](outputs/post_stage4a_distance_band_sensitivity_v2_preflight/).

## Model and linkage

The v2 model retains the v1 population, outcomes, periods, covariates, and
random intercepts. It replaces the five plotted 0–10 km bands plus one
10–20 km adjustment band with 13 jointly estimated 2 km bands through 26 km.
All 78 period-by-distance exposure counts are included additively in one
checklist row, so concurrent herring-source links are retained without
duplicating checklists as independent observations.

The archived 0–20 km source-link cache was reused exactly. A new protected
metadata-only cache extended candidate links through 26 km, adding 625,251
links across the complete archived frame. The rebuild contained every archived
link with matching event day and distance tolerance. Because link distances
are serialized to three decimals, new-only links immediately outside the old
radius can print as 20.000 km. Provenance therefore keeps archived 20.000 km
rows in 18–<20 km and assigns new-only 20.000 km rows to 20–<22 km.

The extension reused the archived EBD membership/date cache. It did not scan
raw EBD responses, read comments, use shoreline fields, or read any
2026–2028 record.

## Diagnostics and interpretation limits

Both fitted components completed without convergence, singularity, or rank
deficiency warnings:

- Checklist reporting: 217,199 model rows.
- Positive numeric count conditional on detection: 83,359 model rows.

The first five spawn-start estimates changed only slightly from v1 after the
outer bands were jointly expanded. The qualitative near-distance pattern is
unchanged.

This is post-result exploratory estimand refinement. Ratios describe adjusted
associations in checklist reporting and reported number; they are not
occupancy, abundance, causal effects, or individual movement. Glaucous-winged
Gull was not fitted. No manuscript or historical Stage 4A/v1 output was
modified.

Complete covariance, fixed effects, support, diagnostics, heterogeneity tests,
execution metadata, and hashes are in
[`outputs/post_stage4a_distance_band_sensitivity_v2/`](outputs/post_stage4a_distance_band_sensitivity_v2/).
