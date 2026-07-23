# D7 — Taxonomy audit

## Taxonomy version

The frozen family is built on **eBird Taxonomy v2025** (`taxonomy_version` in
`metadata/canonical_species_registry.csv`, uniform across all species). The
manuscript never states this. Recommended in Methods (Phase 3 item 4).

## Split-affected taxa in the 2005-2025 window

The registry flags exactly the three gulls of interest:

| Species | `taxonomic_complications` | Change in window |
|---|---|---|
| Short-billed Gull | historical common-name change | Mew Gull split (2021) |
| American Herring Gull | historical split requires versioned mapping | Herring Gull complex split (2024) |
| Iceland Gull | historical complex requires versioned mapping | Thayer's Gull lump (2017) |

Annual detection counts (`D7_gull_annual_detection_counts.csv`) rise steeply
across the series for all three, e.g. Short-billed Gull 27 (2008) to 3,747
(2022); Iceland Gull 23 (2009) to 653 (2021); American Herring Gull 20 (2010) to
239 (2025). Most of this is eBird participation growth, but the split years fall
inside the series.

## Why this does not obviously bias the interaction

The event study includes calendar year as a factor and estimates a
near-versus-reference difference-in-differences. A taxonomy change alters the
reported concept equally for near and reference checklists within a given year,
so it is absorbed by the year factor and differenced out of the interaction. The
residual risk is confined to any within-year, spatially structured reporting
change at a split boundary, which is second order. State the version and the
mapped concepts; the design already neutralises the first-order effect. A raw
trend analysis would not be protected this way, but this is not a trend analysis.

## Ambiguity and taxonomic rules for a Methods paragraph

The spec (`metadata/post_stage4a_sog_event_study_spec_v1.yml`) fixes the state
rules: an unquantified `X` contributes to detection but never to numeric count
(`unquantified_X_as_numeric: prohibited`); ambiguity is never coerced to zero
(`ambiguity_as_zero: prohibited`); lower-bound, ambiguous, structural-unknown,
and finite exact counts remain distinct states, encoded by `count_type` in the
reported states (`numeric`, `X`, `ambiguity_affected`). These are the rules the
manuscript invokes four times without describing. Draft Methods prose and a
supplementary state table are in `OPEN_QUESTIONS.md` for author review before
insertion.
