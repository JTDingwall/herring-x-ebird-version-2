# Revision memo: manuscript v9

## Major changes

- Replaced the earlier descriptive timing argument with the verified direct active-minus-pre (A14) contrast, calculated from the complete fixed-effect covariance matrix.
- Made the complete 49-species support-qualified family the primary inferential set and retained the eleven named taxa as illustrative natural-history examples.
- Incorporated the verified analytical frame: 217,200 eligible complete checklists, 1,120 source events, 58 event blocks, 29,248 observer clusters, and 22,980 generalized locations.
- Reported the primary A14 results: 13 of 48 estimable checklist-reporting contrasts and 18 of 46 estimable conditional-positive-count contrasts were BH-significant; all significant contrasts were positive.
- Added verified fixed-effect predictions to place selected ratios on absolute scales, including Glaucous-winged Gull checklist reporting, Short-billed Gull conditional count, and Surf Scoter conditional count.
- Added the finite-number-versus-X analysis, binary-any-link sensitivity, and the two completed alternative-engine checks. Claims are limited to what those checks establish.
- Replaced the first two figures with direct A14 forest plots and revised the results tables to report A14 estimates and BH-adjusted q-values.
- Reframed the Discussion and Conclusion around event-linked associations rather than causal effects, consumption, movement, or regional abundance change.

## Handling of non-estimable species–outcome components

The requested failed components were removed from displayed results. Exclusion was applied at the component level: a species remains in a figure or table only where the displayed outcome has a valid estimable fit. This preserves verified results without presenting failed model components as estimates.

The detailed failure statuses remain in the privacy-safe analysis record. The manuscript reports aggregate completion counts and states that component-specific figures and tables include estimable fits only.

## Interpretation of the verified results

The direct A14 analysis supports a post-onset concentration of positive event-linked associations for a subset of species, because it formally compares days 0–14 with days −14 to −1 rather than inferring timing from separate significance thresholds. The strongest checklist-reporting contrasts occurred among several gulls, while prominent conditional-count contrasts occurred in Long-tailed Duck, Surf Scoter, Short-billed Gull, and other waterbirds.

The two outcomes distinguish different observation components. Surf and White-winged Scoters increased in conditional positive numeric count without a corresponding checklist-reporting contrast; Harlequin Duck, Common Merganser, Glaucous-winged Gull, and Short-billed Gull increased in both. Dabbling-duck results and imperfect sign concordance under binary exposure encoding show that residual habitat, migration, access, observer behaviour, and exposure construction remain plausible explanations.

No finite-number-versus-X A14 contrast survived BH adjustment, but 30 of 41 estimable models were singular. This result does not establish that selection into the conditional-count analysis is absent, ignorable, or biased in a known direction.

## Section-level change log

| Section | Change |
|---|---|
| Abstract | Added verified sample and event totals, direct A14 family results, finite-versus-X result, binary sensitivity, and a noncausal conclusion. |
| Methods 2.1–2.3 | Added verified event, block, observer, and location totals; clarified source events, connected event blocks, same-event/block zone representation, and point-based spatial linkage. |
| Methods 2.4 | Retained the conceptual event-link model and per-link estimand; added the direct A14/A7 covariance-based comparisons and partial alternative-engine validation. |
| Methods 2.5 | Defined primary and secondary timing families, standardised fixed-effect predictions, finite-versus-X analysis, and completed sensitivities. |
| Results 3.1 | Replaced failed-species rows with aggregate model-completion reporting; retained component statuses in the analysis record. |
| Results 3.2–3.4 | Made direct A14 results primary; added full-family and illustrative forest plots, A14 tables, A7 results, and verified absolute predictions. |
| Results 3.5–3.6 | Recalibrated specificity claims; added finite-versus-X, binary exposure, and alternative-engine findings. |
| Discussion and Conclusion | Interpreted direct timing results conservatively and consolidated observation-process, exposure, validation, and causal limitations. |
| Figures and tables | Replaced “detection”/“flock size” terminology, plotted only estimable components, and identified the retained convergence-warning fit. |

## Outstanding analyses and author inputs

| Type | Outstanding item | Manuscript treatment |
|---|---|---|
| Analysis | Complete the remaining prespecified representative `glmmTMB` checks. | The manuscript identifies the two completed checks as partial and does not generalize them to the full family. |
| Analysis | Event-block bootstrap or another dependence-preserving family/event-level uncertainty analysis. | No family-wide mean shift is claimed. Species-level BH-adjusted A14 tests remain the inferential unit. |
| Analysis | Stationary-only and short-travel checklist sensitivities. | Point-based travelling-route exposure is treated as a direction-unknown limitation. |
| Analysis | Alternative radii, nearest-event assignment, capped-link counts, and complete single-event results for both outcomes. | The additive per-link estimand and binary-any-link sensitivity are reported; other exposure encodings are explicitly incomplete. |
| Analysis | Observer overlap, event support restrictions, influence diagnostics, and taxonomic/year sensitivities. | These are listed as future robustness checks and are not implied to have been completed. |
| Analysis | Placebo/shifted onset analysis. | The verified direct A14 and A7 timing contrasts are reported without a placebo claim. |
| Author input | Full postal address and telephone number. | Visible placeholders retained. |
| Author input | Registration identifier and repository/archive DOI. | Visible placeholders retained in Methods and availability statements. |
| Author input | Funding statement. | Visible placeholder retained. |
| Author input | Journal-compliant generative-AI disclosure. | Visible placeholder retained. |
| Author input | Additional acknowledgements. | Visible placeholder retained. |

## Verification

- Every numerical result added to the manuscript was taken from the verified analysis outputs.
- No failed component is displayed as an estimate.
- The Word file was rendered to PDF and all 19 pages were visually inspected.
- Figure titles, axis labels, legends, captions, and table page breaks were checked after a second render.
- True Word tracked changes were not preserved or claimed; this memo provides the section-level change log.
