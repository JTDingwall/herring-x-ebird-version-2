# Stage 4A core response methods — pre-response lock

## Status and scope

This document freezes the Stage 4A implementation before protected bird-response
access. It contains no observed response result. Stage 4A is restricted to the
human-authorized core biological analyses, hurdle components, fixed diagnostics,
and WCVI robustness checks listed in the hashed model-disposition record. The
historical 45-model registry remains unchanged.

## Population and geometry

The primary population is the verified factorized 58-taxon denominator restricted
to complete Stationary or Traveling checklists, 5–300 minutes, at most 5 km of
travel, one to ten observers, and years no later than 2025. SoG from 2005 is
primary. WCVI from 2015 is candidate-primary and requires the observer-disjoint
robustness view, the dominant-observer holdout, and transparent concentration
reporting. CC and NA are hierarchical/descriptive only. The at-most-2-km frame is
a targeted sensitivity. The broader 10-km frame is not run.

Only immutable herring source points and their frozen event metadata linkage are
used. Shoreline classes, unions, and derived alongshore lengths remain audit
provenance and are excluded from every model and sensitivity.

## Outcomes

Checklist reporting, positive numeric count, unquantified `X`, lower-bound count,
ambiguity, and deterministic omission zero remain distinct. `X` contributes only
to the reporting component. Ambiguity masks produce structural unknowns, never
zeros. Positive-count results describe reported relative counts conditional on a
numeric report; they do not estimate absolute abundance or biomass. Reporting
probability is not true absence or occupancy.

## Models and validation

M01 and M02 are two-part hurdle analyses. Their M11 detection and M12 positive
lognormal components are implementation components, not independent evidence.
The parallel registered positive-count sensitivity is zero-truncated NB2. M05
uses the frozen event-time and source-point-distance strata while retaining all
concurrent links in one independent checklist row. M08 compares active-near
support with contemporaneous reference support as a redistribution diagnostic.

Four deterministic event-blocked folds are the sole validation basis for claims
about new herring events. Performance is reported by fold. Observer-disjoint
validation is labeled only as observer-composition robustness. Held-out
predictions set observer and generalized-location random effects to their
population expectation and never use conditional BLUPs.

Species synthesis uses prespecified hierarchical partial pooling while retaining
individual-species estimates. Benjamini–Hochberg adjustment is confined to
coherent species–outcome families. All activated models are reported regardless
of sign or apparent interest; deferred models remain visibly not fitted.

## Privacy and stopping rule

Only aggregate cells meeting the registered minimum release count of 20 may be
tracked. Protected caches, event rows, identifiers, coordinates, local paths, and
sparse responses remain ignored. Comments and records from 2026 onward are not
opened. Successful execution stops at
`PASS_PENDING_HUMAN_STAGE4A_RESULTS_REVIEW`.
