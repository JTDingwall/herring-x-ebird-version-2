---
title: "Revision memo"
subtitle: "Event-linked changes in coastal-bird checklist reporting and counts during Pacific herring spawning in the Strait of Georgia"
author: "Jacob T. Dingwall"
date: ""
---

# Scope

The manuscript was revised as a clean ecology-focused document using the numerical results in the v7 manuscript, its tables, and the released aggregate repository outputs. No model was rerun and no coefficient, confidence interval, p-value, q-value, sample size, or diagnostic result was estimated for this revision.

True Word tracked changes were not preserved. The revised manuscript is a clean document accompanied by this section-level change log.

# Major changes

- Reframed the paper for ecologists, ornithologists, fisheries scientists, and community-science researchers.
- Renamed the binary outcome **checklist reporting** and the count outcome **conditional positive numeric count**.
- Made the complete 49-species family the primary inferential set and treated the eleven named species as illustrative ecological profiles.
- Defined the estimand as a baseline-adjusted near/reference contrast of additive event-link slopes.
- Added a conceptual model equation, term definitions, a worked example, and the unit of the estimate.
- Defined source events and statistical event blocks and reported the verified Strait of Georgia totals.
- Recalibrated timing claims: the period-specific BH counts are now explicitly descriptive, and a direct active-minus-pre comparison is marked as outstanding.
- Replaced claims that the design separates herring from migration with a narrower statement about adjustment for seasonal changes shared by near and reference areas.
- Removed causal claims about herring-induced movement, consumption, abundance, and regional population change.
- Reframed unquantified `X` observations as a potentially informative third observation process without assuming the direction of bias.
- Retained `nAGQ = 0` in the main Methods because it affects inference, while moving routine implementation language out of the ecological argument.
- Rewrote data and code availability without hashes, fixtures, production authorization, manifests, code-halting conditions, PowerShell, or other repository-governance language.

# Section-level change log

| Section | Principal changes |
|---|---|
| Title and Abstract | New noncausal title; post-result exploratory status; data sources, zones, response definitions, family-wide results, contradictory taxa, and limitations stated directly. |
| Introduction | Shortened technical framing; clarified migration, habitat, access, and observer behaviour; made the ecological question and cautious expectations explicit. |
| Methods: data and responses | Consolidated eligibility criteria; distinguished reporting, finite numeric counts, `X`, and ambiguity; removed occupancy and flock-size terminology. |
| Methods: event linkage | Defined source event, event block, timing windows, spatial zones, concurrent links, travelling-checklist limitation, and additive link counts. |
| Methods: estimand | Added equation, worked example, contrast definition, and per-additional-event-link interpretation; replaced broad difference-in-differences wording. |
| Methods: models and multiplicity | Retained model families, links, main covariates, random effects, `nAGQ = 0`, BH procedure, and completed sensitivities; made the full family primary. |
| Results | Reordered to lead with the complete family; retained positive, negative, null, failed, and singular outcomes; separated family-wide results from illustrative profiles. |
| Timing | Recast as a descriptive pattern; inserted a visible active-minus-pre analysis requirement. |
| Specificity | Treated comparator results as exploratory and highlighted the wider dabbling-duck and goose contradiction. |
| Discussion | Reorganized into main findings, ecological interpretation, observation-process/design limitations, and implications; reduced repeated caveats. |
| Conclusion | Removed formal post-versus-pre, causal movement, consumption, and abundance claims. |
| Availability and declarations | Simplified for ecological readers and standardized all missing author information as visible placeholders. |

# Figures, tables, and references

The existing released numerical values were preserved. Figures were regenerated from the released aggregate outputs only to change terminology and the estimand label; no model output changed. The complete-family figure is now presented before the illustrative-species figure.

No new references were added. The generic difference-in-differences citations flagged for verification in the v7 README were not needed for the revised ecological description and are not cited in the revised main text.

# Outstanding work

The accompanying “Outstanding analyses and author inputs” document separates high-priority analyses, additional robustness work, presentation additions, and author-supplied information. Missing results remain visible in the clean manuscript as `[[ANALYSIS REQUIRED: ...]]`; missing author information remains as `[[AUTHOR INPUT REQUIRED: ...]]`.
