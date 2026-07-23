# D3 — Unquantified-X selection channel

`count_type` in `stage4a_reported_states` takes three values among detections:
`numeric` (1,132,426), `X` (36,463), `ambiguity_affected` (723). The conditional
count model keeps only `numeric` positive counts, so `X` plus `ambiguity_affected`
is exactly the detection subset the count model discards. Because
`ambiguity_affected` is negligible, the "non-numeric fraction" below is
effectively the unquantified-`X` rate.

Full 53-species table (all four strata with >=20 detections):
`D3_nonnumeric_selection.csv`. Strata are checklist memberships built from the
link table (near/reference x baseline/active), mirroring the additive exposure.

## What it shows

The X rate is low in absolute terms (mostly under 10% of detections) but it
responds to exposure, and for most aggregating species it rises **more** in the
near-active stratum than in the reference-active stratum (positive
difference-in-differences):

| Species | near base to active | ref base to active | DiD |
|---|---|---|---|
| White-winged Scoter | 0.059 to 0.090 | 0.068 to 0.069 | +0.031 |
| Iceland Gull | 0.099 to 0.178 | 0.089 to 0.144 | +0.024 |
| Greater Scaup | 0.031 to 0.068 | 0.042 to 0.058 | +0.021 |
| Harlequin Duck | 0.020 to 0.045 | 0.022 to 0.026 | +0.021 |
| Short-billed Gull | 0.060 to 0.096 | 0.055 to 0.071 | +0.020 |
| Glaucous-winged Gull | 0.056 to 0.079 | 0.059 to 0.065 | +0.017 |
| Surf Scoter | 0.047 to 0.070 | 0.037 to 0.052 | +0.008 |
| Long-tailed Duck | 0.045 to 0.090 | 0.043 to 0.081 | +0.007 |
| American Herring Gull | 0.055 to 0.075 | 0.055 to 0.069 | +0.006 |

## Consequence for interpretation

The conditional count model conditions on numeric quantification, and the
quantified fraction shrinks with exposure, more near than reference, for exactly
the species with the largest count ratios. Observers most often drop the count on
the largest aggregations, so the discarded detections are plausibly the biggest
flocks. The reported near/reference flock-size ratios for the strong aggregators
(Iceland Gull most of all, then the scoters and gulls) are therefore likely
**conservative**: the numeric subset understates the aggregation it is meant to
measure. This is a selection channel distinct from detection selection, which the
manuscript handles in Results 3.2 and Discussion 4.2 but does not mention for
quantification. Routed to Phase 3 item 11 (add to Discussion 4.2). It does not
overturn any result; it makes the count ratios a lower bound for these species.
