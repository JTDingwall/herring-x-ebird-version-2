# Conventional exposure sensitivity: interpretation memo

## Frozen design choice

Deterministic nearest-event assignment was selected before model fitting. Complete single-event restriction retained 72,443 of 217,200 checklists and supported conditional positive numeric reported-count models for 19 of 49 species. Nearest-event assignment retained all 217,200 checklists, preserved full fixed-effect rank, and supported the count model for 41 of 49 species. Both candidates supported checklist reporting for all 49 species. The decision used only design support and geometry; no response estimate or fitted result was read.

## Primary-versus-sensitivity comparison

| Outcome | Primary estimable | Nearest-event estimable | Sign concordance | Primary BH q < 0.05 | Nearest-event BH positive / negative | Sign reversals | Material interpretation changes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Checklist reporting | 48 | 49 | 34/48 (70.8%) | 13 | 7 positive / 2 negative | 14 | 3 |
| Conditional positive numeric reported count | 46 | 41 | 34/41 (82.9%) | 18 | 19 positive / 0 negative | 7 | 1 |

The nearest-event sensitivity identifies 4 material interpretation change(s) under the fixed pre-result comparison rule. 11/13 primary-BH reporting signs and 18/18 primary-BH count signs were preserved; 7 and 17, respectively, remained BH-significant. The main conclusions therefore require the species- and outcome-specific qualifications listed below; observational and noncausal limitations remain.

BH-threshold crossing alone is not classified as a material change. Same-direction interval nonoverlap is flagged but is not treated as a material change because the exposure units differ. A material change is a sign reversal with at least one 95% confidence interval excluding zero.

## Material directional reversals

| Species | Outcome | Primary ratio (95% CI) | Nearest-event ratio (95% CI) | Primary q | Nearest-event q | BH threshold crossed | Classification |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Surf Scoter | Checklist reporting | 1.00 (0.93–1.08) | 0.71 (0.59–0.85) | 0.948 | 0.001 | yes | material_direction_reversal__at_least_one_interval_excludes_zero |
| Harlequin Duck | Checklist reporting | 1.15 (1.05–1.26) | 0.84 (0.66–1.07) | 0.013 | 0.394 | yes | material_direction_reversal__at_least_one_interval_excludes_zero |
| American Wigeon | Checklist reporting | 1.11 (1.04–1.17) | 0.99 (0.87–1.14) | 0.004 | 0.967 | yes | material_direction_reversal__at_least_one_interval_excludes_zero |
| Barrow's Goldeneye | Conditional positive numeric reported count | 1.10 (1.01–1.19) | 0.95 (0.81–1.12) | 0.052 | 0.615 | no | material_direction_reversal__at_least_one_interval_excludes_zero |

## BH-threshold crossings (not material by themselves)

| Species | Outcome | Primary ratio (95% CI) | Nearest-event ratio (95% CI) | Primary q | Nearest-event q | BH threshold crossed | Classification |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Surf Scoter | Checklist reporting | 1.00 (0.93–1.08) | 0.71 (0.59–0.85) | 0.948 | 0.001 | yes | material_direction_reversal__at_least_one_interval_excludes_zero |
| Brant | Checklist reporting | 1.16 (1.04–1.30) | 1.37 (1.00–1.89) | 0.026 | 0.158 | yes | same_direction__compatible_magnitude |
| Glaucous-winged Gull | Checklist reporting | 1.14 (1.08–1.20) | 1.03 (0.91–1.17) | 5.01e-05 | 0.851 | yes | same_direction__compatible_magnitude |
| American Herring Gull | Checklist reporting | 1.39 (1.23–1.57) | 1.54 (1.07–2.22) | 8.51e-07 | 0.076 | yes | same_direction__compatible_magnitude |
| Northern Pintail | Checklist reporting | 1.21 (1.10–1.32) | 1.23 (1.01–1.51) | 3.21e-04 | 0.125 | yes | same_direction__compatible_magnitude |
| Red-necked Grebe | Conditional positive numeric reported count | 1.02 (0.96–1.08) | 1.22 (1.04–1.44) | 0.702 | 0.029 | yes | same_direction__compatible_magnitude |
| Harlequin Duck | Checklist reporting | 1.15 (1.05–1.26) | 0.84 (0.66–1.07) | 0.013 | 0.394 | yes | material_direction_reversal__at_least_one_interval_excludes_zero |
| Bufflehead | Checklist reporting | 0.94 (0.89–1.00) | 0.72 (0.63–0.82) | 0.110 | 1.39e-05 | yes | same_direction__nonoverlapping_intervals__encoding_scales_not_directly_comparable |
| Common Loon | Conditional positive numeric reported count | 1.05 (1.01–1.08) | 1.02 (0.93–1.12) | 0.041 | 0.660 | yes | same_direction__compatible_magnitude |
| American Wigeon | Checklist reporting | 1.11 (1.04–1.17) | 0.99 (0.87–1.14) | 0.004 | 0.967 | yes | material_direction_reversal__at_least_one_interval_excludes_zero |
| American Wigeon | Conditional positive numeric reported count | 1.06 (1.01–1.11) | 1.20 (1.09–1.33) | 0.052 | 6.70e-04 | yes | same_direction__compatible_magnitude |

The complete machine-readable review table, including uncertain reversals, unsupported components, and same-direction interval nonoverlap, is `interpretation_changes.csv`.

## Component-status handling

All primary, finite-number-versus-X, and nearest-event components are retained in `component_status.csv`, including failures and warnings. Failed components are statuses rather than null biological results. The table explicitly flags Surfbird, Rhinoceros Auklet, Glaucous Gull, Red-throated Loon, Western Gull, Common Goldeneye, Marbled Murrelet, and Western Grebe.

## Scientific boundary

The sensitivity changes only the exposure encoding. Eligibility, zones, periods, A14 active-minus-pre comparison, covariates, random effects, confidence intervals, and BH families remain unchanged. Results concern checklist reporting and conditional positive numeric reported counts; they do not establish detection probability, occupancy, regional abundance, diet, movement, or causation.
