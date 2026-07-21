# Stage 3 Phase 3 blocked-validation methods

Status: human-approved and Stage 3 finalized. No response model was fitted, no response access was authorized, and Phase 4 has not started.

## Scientific target

The primary validation target is generalization to new herring spawning events and their associated active/reference sampling. It is not prediction of a random checklist from an already-observed event.

The validation population contains 239,934 independent primary-frame checklists linked to 3,717 immutable herring source events. Concurrent links are metadata attached to one checklist; they never create independent replicated checklist rows.

## View A: primary event-blocked validation

Each herring source event is an atomic source unit. Source events linked concurrently to the same independent checklist are unioned into one protected block. This produces 308 event blocks. Whole blocks, all source events in them, every shared checklist and all concurrent links receive one fold.

Five folds were preferred. They retained all registered minima in SoG and WCVI but failed at least one minimum in CC and NA. Four folds were therefore evaluated and are the approved deterministic design; five folds must not be forced when doing so violates the frozen support requirements. Four folds retain every minimum in SoG, WCVI and CC. One NA fold has only one source event represented in both primary periods, below the frozen minimum of two. NA remains hierarchical/descriptive only, so this limitation is retained visibly, does not block SoG or WCVI, and cannot be used to upgrade NA.

The four-fold event-blocked split has zero event-block, herring-source-event, independent-checklist, shared-group or concurrent-link leakage. Observer and generalized-location overlap are measured rather than forced into the event blocks because the target is new-event generalization.

## View B: observer robustness

Observer-cluster-disjoint folds assign each protected observer cluster to one fold. This view tests sensitivity to observer composition; it is not a substitute for event-blocked validation and must not be described as validating generalization to new herring events. Herring event blocks may cross observer folds in this view, while checklist and shared-group units remain intact. Observer overlap is zero by construction, and event/location overlap is reported.

A protected leave-dominant-observer-cluster-out stress test is also reported for each review region. CC and NA remain hierarchical/descriptive regardless of observer-fold feasibility.

## WCVI conditional-primary decision

| Fold | Checklists | Herring events | Active | Reference | Maximum observer share | Effective observers | Effective herring events |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 2,164 | 99 | 212 | 334 | 0.402 | 5.878 | 31.942 |
| 2 | 1,795 | 77 | 252 | 138 | 0.247 | 13.402 | 35.560 |
| 3 | 2,462 | 102 | 225 | 457 | 0.431 | 5.308 | 38.279 |
| 4 | 2,163 | 67 | 154 | 241 | 0.315 | 7.911 | 25.953 |

All four WCVI event-blocked folds pass the registered checklist, event, period and active/reference minima. Pooled WCVI observer concentration remains high: the dominant cluster contributes 35.6% and effective observer replication is 7.4. Holding out that cluster leaves 5,529 checklists, 345 herring events, 613 active checklists and 886 contemporaneous references; the holdout retains all registered minima.

WCVI therefore remains candidate primary. Every future WCVI primary presentation requires fold-specific validation results, observer-robustness results, the dominant-observer holdout and transparent observer-concentration reporting. The concentration warning does not automatically demote WCVI while all required checks remain adequate. This is a validation-design decision only, not evidence of a bird response.

## SoG, CC and NA

- SoG from 2005 passes every event-blocked fold and remains primary with observer diagnostics.
- CC gains complete four-fold minimum support but remains hierarchical/descriptive under the human decision.
- NA retains one four-fold both-period limitation and remains hierarchical/descriptive. It is not eligible for an unsupported standalone regional claim.

## Estimand safeguards

Future detection output, if separately authorized, must be labelled as probability reported on an eligible complete checklist. Positive-count output must be labelled as a reported relative count conditional on detection and numeric availability. True absence, occupancy, absolute abundance and biomass language remain prohibited without separate identification.

For every held-out prediction, observer and generalized-location random effects must be marginalized or set to their population-level expectation. Learned conditional random effects or BLUPs must not be used merely because an observer or generalized location appeared in training data.

The 2026–2028 prospective confirmation period remains completely locked.

No EBD rescan, sparse bird-state access, denominator expansion, response summary, exposure contrast, effect estimate, model fit, comment access, shoreline access or 2026-and-later access occurred in Phase 3.
