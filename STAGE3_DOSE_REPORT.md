# Stage 3 dose analysis

The prespecified Stage 3 dose pattern is **not supported**. The nested dose model improved fit for many species, and three positive within-location contrasts survived BH, but all three disappeared when `log(length_m)` was held constant. The evidence therefore does not support a robust response to recorded spawn index beyond the spatial extent of a spawn.

This is a post-result estimand refinement, not confirmatory evidence. Relative spawn index is not absolute biomass, and the fitted associations are not causal effects.

## Falsification decision

The criteria recorded before the Stage 3 response fits were:

- **Supported:** the within-location dose contrast is positive and survives BH for a meaningful number of species, the likelihood-ratio test is significant, the signal holds under the surface-only restriction, and the effort outcomes show no dose response.

- **Not supported:** the likelihood-ratio test is not significant, the effect is carried entirely by the between-location term, or it disappears when `log(length_m)` is held constant.

- **Uninterpretable:** checklist duration shows a dose response, or the effect reverses between the full and surface-only fits.

After checkpoint 1, the author declared the surface-only set non-estimable and replaced it with a dive-only consistent-majority sensitivity. The original criteria remain visible in the immutable specification; the amendment is recorded separately. The result is **not supported**, rather than uninterpretable: no effort outcome responded after BH, the three primary signals kept their direction in the dive-only fit, but each failed the prespecified persistence condition after adjustment for spawn length.

## Index aggregation and model population

The 1,120 linked candidate events contained 995 positive scored events, 125 events with no recorded component, no nonpositive scored events, and no event with more than one frozen survey row. For a row with at least one recorded component, missing components contributed zero only while summing the event total. The descriptive `0.00` for those 125 events was never logged or entered as zero spawn.

Under the adopted start-date anchor, 1,100 events retained a link in the -28 to +28 day model window. Of these, 979 had a positive score and entered dose sums; 121 had no recorded component and contributed no dose because they were dropped before logging. The remaining four unscorable candidates lay outside period support.

Among the 995 positive events, the aggregated relative spawn index had median 591.42 t (IQR 143.67-1,913.29), with a range of 0.0161-21,461.89 t. The frozen link-weighted grand mean of `log(index)` was 6.263486.

| Survey-method set | Linked candidates | Positive scored | No component | Positive-index median (IQR), t |
|---|---:|---:|---:|---:|
| Dive observed | 950 | 939 | 11 | 690.07 (191.85-2,022.08) |
| Surface observed | 68 | 56 | 12 | 48.37 (10.27-133.80) |
| Method incomplete | 102 | 0 | 102 | Not estimable |

All declared joins passed their cardinality gates. The analysis used 217,200 eligible checklists from 2005-2025, read no 2026-2028 response record, and released no checklist, observer, locality, event-key, or coordinate identifier.

## Likelihood-ratio headline

Adding the 12 total-dose terms to the Stage 2 plus survey-method model improved fit after the separate fixed-49 BH correction for 29/49 reporting models and 32/49 count models. Reporting was estimable for all 49 species; count was estimable for 46, with three insufficient-support failures retained. Thus recorded spawn size often improved overall fit, but this omnibus result did not establish the prespecified positive within-location active-minus-pre pattern.

## Primary within-location result against Stage 2

Positive BH-surviving within-location contrasts fell from the Stage 2 timing totals of 13 reporting and 20 count increases to 2 reporting and 1 count dose contrasts. There were no negative BH survivors in either outcome.

| Species | Outcome | Ratio | 95% CI | p | BH q |
|---|---|---:|---:|---:|---:|
| Glaucous-winged Gull | Positive numeric count | 1.1019 | 1.0740-1.1306 | 1.29e-13 | 6.33e-12 |
| Iceland Gull | Checklist reporting | 1.1103 | 1.0409-1.1843 | 0.00149 | 0.0364 |
| Short-billed Gull | Checklist reporting | 1.1064 | 1.0512-1.1645 | 0.000107 | 0.00527 |

## Within- versus between-location dose

The primary coefficient compared larger and smaller recorded events at the same location. None of the three primary signals was carried entirely by the between-location term: their between-location estimates stayed positive, but only the Glaucous-winged Gull count contrast was nominally different from zero.

| Species and outcome | Within-location ratio (p) | Between-location ratio (p) |
|---|---:|---:|
| Glaucous-winged Gull, count | 1.1019 (1.29e-13) | 1.0666 (0.000184) |
| Iceland Gull, reporting | 1.1103 (0.00149) | 1.0509 (0.295) |
| Short-billed Gull, reporting | 1.1064 (0.000107) | 1.0732 (0.0638) |

Across all estimable rows, within- and between-location signs disagreed for 20 reporting species and 15 count species. Between-location coefficients were not assigned a separate BH family because the prespecified multiplicity key was the within-location contrast.

## Survey-method sensitivity

The surface-only set contained 68/1,120 linked candidates (6.1%), including only 56 positive scored events. It is **non-estimable**: no surface-only response model was fit and no biological interpretation is made.

The replacement dive-only set comprised 950/1,120 candidates (84.8%); 934 retained a start-anchor model-window link and 923 were positively scored. Eleven dive events with no recorded component were dropped before logging. All three primary BH signals retained direction and survived BH in this consistent-majority set, and Surf Scoter reporting became an additional positive survivor.

| Species | Outcome | Primary ratio (q) | Dive-only ratio (q) |
|---|---|---:|---:|
| Glaucous-winged Gull | Count | 1.1019 (6.33e-12) | 1.0894 (5.46e-09) |
| Iceland Gull | Reporting | 1.1103 (0.0364) | 1.1075 (0.0450) |
| Short-billed Gull | Reporting | 1.1064 (0.00527) | 1.1052 (0.00748) |
| Surf Scoter | Reporting | 1.0817 (0.0600) | 1.0849 (0.0450) |

## Extent sensitivity

`log(index)` and `log(length_m * width_m)` were strongly correlated (Pearson r = 0.8763 across 11,908 positive finite-extent events in the frozen event source). Holding the 12 centred `log(length_m)` link sums constant removed every positive primary survivor:

| Species | Outcome | Primary ratio (q) | Length-adjusted ratio (q) |
|---|---|---:|---:|
| Glaucous-winged Gull | Count | 1.1019 (6.33e-12) | 1.0007 (1.000) |
| Iceland Gull | Reporting | 1.1103 (0.0364) | 1.0140 (0.985) |
| Short-billed Gull | Reporting | 1.1064 (0.00527) | 1.0222 (0.985) |

The length-adjusted model instead produced four negative count survivors: Surf Scoter, Common Goldeneye, Iceland Gull, and California Gull. These were not positive primary signals and do not rescue the prespecified dose pattern. The disappearance of all three positive primary hits is the criterion that determines the **not supported** verdict and indicates that the observed pattern is about spawn extent rather than a robust response to recorded spawn intensity.

## Observer-effort negative-control outcomes

No dose contrast survived BH across the three effort outcomes:

| Outcome | Estimate | Ratio or additive change | p | BH q |
|---|---:|---:|---:|---:|
| Log duration minutes | 0.00279 | 1.00279 | 0.530 | 0.795 |
| Log distance travelled plus one | 0.00308 | 1.00309 | 0.140 | 0.421 |
| Number of observers | 0.000121 | +0.000121 observers | 0.981 | 0.981 |

Each model dropped its response from the covariate set and retained the other two effort measures. These results do not show checklist effort increasing with recorded spawn size.

## Fake-anchor dose placebos

All four fake-anchor families returned zero positive and zero negative BH-surviving dose contrasts. Reporting was estimable for all 49 species at both offsets. Count was estimable for only 14/49 species at -90 days and 17/49 at +90 days, so the count placebo nulls have limited model support.

| Offset | Reporting survivors | Count survivors |
|---:|---:|---:|
| -90 days | 0 positive, 0 negative | 0 positive, 0 negative |
| +90 days | 0 positive, 0 negative | 0 positive, 0 negative |

## Guild and tercile summaries

The exact-covariance, inverse-variance guild omnibus differed among the seven fixed guilds for reporting (p = 0.000114) and count (p = 0.00163). For reporting, the gull-roe guild had ratio 1.0674 (95% CI 1.0415-1.0940), while the alcid-piscivore guild had ratio 0.9335 (0.8761-0.9946). For count, the corresponding ratios were 1.0410 (1.0230-1.0594) and 1.0522 (1.0007-1.1064). These summaries describe heterogeneity among exploratory species coefficients; they do not overcome the extent-sensitivity failure.

The within-year tercile diagnostic was visually monotone only for Glaucous-winged Gull positive count: low 1.1817, middle 1.2652, high 1.4767. The other sequences were not monotone: Glaucous-winged Gull reporting 1.1937, 1.0753, 1.2607; Bald Eagle reporting 1.0075, 0.9674, 1.1474; and Bald Eagle count 1.0842, 1.1377, 1.1024. This figure is descriptive and is not an additional test family.

## Failures and warnings retained

- Primary and LRT count models failed for Surfbird, Rhinoceros Auklet, and Glaucous Gull because of insufficient support; all three rows remain in both fixed-49 output families. All reporting models completed.

- The dive-only count sensitivity additionally failed for Red-throated Loon and Bonaparte's Gull, for five retained failures in total. The extent sensitivity retained the same three count failures as the primary analysis.

- The placebo tables retain the fixed denominator of 49 even though only 14 and 17 count fits were estimable at -90 and +90 days.

- All 294 real-model diagnostic instances carried a convergence, singularity, or rank warning, predominantly rank-deficiency warnings. No fallback model was substituted. The CSV status fields and protected checkpoints retain the complete failure and warning record.

## What this analysis does not claim

The author should not claim that recorded spawn index predicts a general bird response, that a one-unit index increase has a causal effect, that the index is absolute biomass, or that conditional positive eBird counts are abundance. The positive primary signals were sparse relative to Stage 2, vanished after adjustment for spawn length, and therefore do not support a response to spawn intensity distinct from extent. Missing herring components are not observed zeros, and the 125 fully unrecorded events were never entered as zero spawn.
