---
title: "Outstanding analyses and author inputs"
subtitle: "Priority table for manuscript completion"
author: "Jacob T. Dingwall"
date: ""
---

# Interpretation

The clean revised manuscript is scientifically accurate without the analyses below because unsupported claims were removed or marked as outstanding. The **high-priority** analyses are strongly recommended before submission if the paper will retain timing, checklist-reporting, and conditional-count inference as central contributions.

# Analyses

| Priority | Analysis or output | Purpose | Current manuscript handling |
|---|---|---|---|
| High | Species-level active-minus-pre contrasts using the full fixed-effect covariance matrix | Directly test whether active-period event-link slopes exceed pre-spawn slopes rather than comparing numbers of BH-significant species. | Timing described as a descriptive pattern; visible analysis placeholder retained. |
| High | Family-level or hierarchical post-minus-pre summary | Assess whether temporal concentration is supported across the species family without treating correlated contrasts as independent trials. | No family-level temporal test claimed. |
| High | Laplace (`nAGQ = 1`) refits for representative positive, negative, and null checklist-reporting results | Check the uncertainty from the `nAGQ = 0` approximation for headline reporting models. | Approximation disclosed; stronger validation identified as required. |
| High | Finite numeric count versus `X` model among reported observations | Test whether numeric quantification changes with exposure and avoid assuming the direction of selection bias. | `X` treated as a third observation process; no conservative-bias claim. |
| High | Complete single-event sensitivity for both outcomes | Verify the current single-event summary for checklist reporting as well as conditional count and supply a complete results table. | Existing 72,443-checklist count summary retained with qualification. |
| High | Nonlinearity or alternative encoding of event-link counts | Test the assumption that each additional recorded link has the same model-scale association. Minimum options: binary any-link, capped counts, or spline/categories where supported. | Per-link linear estimand stated explicitly as a limitation. |
| Medium | Alternative mixed-model implementation, such as `glmmTMB` | Check whether headline coefficients and uncertainty are implementation-dependent. | Listed as validation work; no result implied. |
| Medium | Event-block bootstrap or other event-level resampling | Assess whether Wald uncertainty is too narrow under event-level dependence. | No bootstrap claim made. |
| Medium | Random-effect variances, gradients, convergence summaries, and influence diagnostics | Show how much clustering is attributed to event blocks, observers, and locations and identify influential units. | Current model-completion status retained; unavailable details not invented. |
| Medium | Appropriate zero-truncated negative-binomial or hurdle sensitivity | Test the lognormal conditional-count specification. | Existing distributional assessment reported; no negative-binomial result claimed. |
| Medium | Stationary-only and short-distance travelling-checklist analyses | Assess route-to-point exposure error. | Direction of travelling-checklist bias treated as unknown. |
| Medium | Alternative near/reference radii | Evaluate dependence on the <5 km and 5–20 km zones. | Current spatial scale interpreted narrowly. |
| Medium | Nearest-event assignment and capped-link sensitivity | Compare the additive-link estimand with more conventional exposure assignments. | Additive estimator described explicitly; alternative results not implied. |
| Medium | Events and event blocks with adequate near/reference support | Show whether the contrast is supported within the dependency units and how many units contribute both zones and periods. | Visible analysis placeholder retained in Methods. |
| Medium | Observer overlap restrictions | Restrict to observers represented across zones or periods, where feasible, to reduce compositional changes. | Observer-composition confounding retained as a limitation. |
| Medium | Taxonomic-year sensitivity | Check taxa affected by concept changes or unstable reporting periods. | Versioned harmonisation described; sensitivity not claimed. |
| Desirable | Predicted checklist-reporting probabilities and percentage-point contrasts | Give ecologically interpretable absolute magnitudes at a stated exposure configuration. | Relative event-link ratios retained without conversion to probability changes. |
| Desirable | Predicted geometric mean counts, observed medians/IQRs, and `X` proportions | Improve interpretation of conditional counts and the selected numeric subset. | No values estimated from ratios. |
| Desirable | Placebo-onset or shifted-date analysis | Test whether similar event-linked patterns arise at artificial onset dates. | Listed as future validation; no placebo result claimed. |
| Desirable | Study-area map | Show checklist and spawning-event coverage at a privacy-safe spatial resolution. | Recommended but not required for the current text. |
| Desirable | Event-link design schematic | Show how one checklist can contribute to several period-by-zone link counts and how those links enter the estimand. | Worked example added in text; no new schematic created. |
| Desirable | Landscape complete-family figure and larger timing heat map | Improve readability of species labels, estimates, and cell values without changing the released numerical results. | Existing figures retained with revised terminology; journal production should use larger or landscape layouts. |

# Author inputs

| Priority | Author input | Location |
|---|---|---|
| Required | Full institutional postal address | Title page |
| Required | Corresponding-author telephone number | Title page |
| Required | Registration identifier and/or repository DOI | Methods |
| Required | Persistent repository DOI for data and code statements | Data and code availability |
| Required | Funding statement | Declarations |
| Required | Journal-compliant generative-AI disclosure | Declarations |
| Required | Additional acknowledgements, or confirmation that none are needed | Acknowledgements |
| Verify | Final Fisheries and Oceans Canada dataset citation wording | Methods and data availability |

# Recommended minimum before submission

If computational resources are limited, prioritise:

1. species-level active-minus-pre contrasts;
2. representative `nAGQ = 1` checklist-reporting refits;
3. finite-number-versus-`X` analysis;
4. complete two-outcome single-event sensitivity; and
5. one alternative to the linear additive-link exposure, preferably binary any-link or capped link counts.

The remaining analyses would improve robustness and interpretation but are less central to the principal scientific claims.
