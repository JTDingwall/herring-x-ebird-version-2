# Bald Eagle distance-band timing sensitivity

## Result

Bald Eagle response timing differs strongly with distance from recorded herring
source points. The spawn-start pulse is largest within 2 km, smaller from 2 to
6 km, absent from 6 to 8 km, and negative relative to the same-band baseline
from 8 to 10 km. This pattern occurs in both checklist reporting and positive
reported number.

The global distance-by-timing heterogeneity test rejects a common five-period
profile across the five plotted distance bands for checklist reporting
(Q = 69.27, 20 df, p = 2.39 × 10^-7) and conditional reported number
(Q = 224.65, 20 df, p = 1.41 × 10^-36). Spawn-start heterogeneity alone is also
strong for reporting (Q = 39.93, 4 df, p = 4.48 × 10^-8) and reported number
(Q = 166.53, 4 df, p = 5.81 × 10^-35).

These are post-result exploratory associations, not causal effects, abundance
estimates, or evidence of individual movement.

## Spawn-start estimates

Each estimate compares days 0 to 3 with days −28 to −15 within the same
source-point distance band. Intervals are exact linear-contrast intervals from
the persisted model covariance.

| Distance band | Reporting odds ratio (95% CI) | Conditional reported-number ratio (95% CI) |
|---|---:|---:|
| 0–<2 km | 1.314 (1.144–1.509) | 1.245 (1.197–1.294) |
| 2–<4 km | 1.207 (1.079–1.349) | 1.128 (1.087–1.171) |
| 4–<6 km | 1.072 (0.974–1.179) | 1.088 (1.053–1.125) |
| 6–<8 km | 0.967 (0.886–1.056) | 0.971 (0.941–1.001) |
| 8–10 km | 0.882 (0.811–0.960) | 0.956 (0.926–0.986) |

The duration-weighted days 0 to 14 contrast is more muted. Reporting remains
positive only in the 2–<4 km band at the conventional 95% interval level,
whereas conditional reported number is positive through 4–<6 km and negative
from 6 to 10 km. The figure preserves the disjoint periods so that the sharp
days 0 to 3 pulse is not hidden by averaging it with days 4 to 14.

## Figure

[Bald Eagle distance-band panel](outputs/post_stage4a_distance_band_sensitivity_v1/bald_eagle_distance_band_panel_v1.png)

The two panels show checklist reporting and reported number conditional on a
numeric detection. Distance bands use different colours, symbols, and line
types. Lines connect discrete model periods and do not imply a continuous
trajectory. Baseline is fixed at one by definition.

## Model and estimand

The analysis uses the authorized SoG 2005–2025 checklist population and the
same response definitions, effort covariates, year and protocol adjustment, and
event-block, observer-cluster, and generalized-location-cluster random
intercepts as the post-Stage 4A event study. The model contains 36 additive
joint exposure counts: six timing periods crossed with five plotted 2 km bands
from 0 to 10 km plus a >10 to 20 km adjustment band. All concurrent source-event
links remain in one independent checklist row.

Unlike the historical M05 model, this model estimates timing by distance
jointly. M05 included time and distance as additive main effects and therefore
could not test whether the timing profile changed with distance.

The reporting component used 217,199 model rows and the conditional-number
component used 83,359 positive numeric reports. Both fits converged without
singularity or rank deficiency. Across the 36 joint terms, exposed model-row
support ranged from 1,166 to 21,677 for reporting and from 736 to 9,076 for
conditional number; no privacy or support threshold was approached.

## Validation and boundaries

- The authorization and specification were committed before protected response
  access at commit `90421ae`.
- Only Bald Eagle was fit. Glaucous-winged Gull remains deferred for the
  requested figure-review step.
- The year gate confirmed that no 2026–2028 records were read.
- Source-link hashes, checklist-to-link cardinality, checklist-year agreement,
  additive concurrent-link accounting, term support, model geometry, and
  convergence all passed.
- Frozen Stage 4A and post-Stage 4A output directories were not modified.
- No manuscript file was edited.
- The clipped first render was replaced by an aggregate-only render at commit
  `c6f391d`; no model was refit during that correction.

Complete effects, exact covariance, support, diagnostics, heterogeneity tests,
hashes, and the execution record are in
[`outputs/post_stage4a_distance_band_sensitivity_v1/`](outputs/post_stage4a_distance_band_sensitivity_v1/).
