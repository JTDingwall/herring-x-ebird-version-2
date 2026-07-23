# Descriptive statistics plan (v3)

**Date:** 2026-07-22

**Rule:** use tracked privacy-safe aggregates only; do not reopen protected response or coordinate records.

## Purpose

The v3 descriptive layer establishes the checklist frame, regional imbalance, observer support, taxon reporting prevalence, numeric-count availability, broad flock-size distributions, and recorded herring-event coverage before adjusted coefficients are presented. All raw summaries are labeled unadjusted and are not interpreted as spawn effects.

## Deterministic sources and grains

| Output | Source | Source grain | v3 grain | Cardinality rule |
|---|---|---|---|---|
| `descriptive_statistics_v3.csv` | Stage 3 event-blocked fold balance and stratum balance; observer robustness; response-free support table | fold-region, fold-region-stratum, or region | region-metric | event-blocked validation folds partition final checklists and are summed; stratum counts may overlap across concurrent links |
| `species_descriptive_summary_v3.csv` | `aggregate_sample_sizes.csv`; response-free Stage 2 species support; guild registry; M02 effects | species-region or pooled species | 49 species x 4 regions | one-to-one join by common name within source grain; 196 output rows required |
| `guild_descriptive_summary_v3.csv` | M01 aggregate sample sizes; guild and membership registries | guild-region and species-guild | 8 guilds x 4 regions | one-to-one guild join; member lists aggregated before joining |
| `herring_event_descriptive_summary_v3.csv` | Stage 3 fold and stratum balance | fold-region or fold-region-stratum | region-metric | sums use only the event-blocked partition; concurrent window/ring counts are explicitly nonexclusive |
| Table 1 | region summaries above | region | region | exactly four released regions |
| Tables 3--4 | frozen M02 and M29 coefficients | model component | model component plus deterministic exponentiation | no statistical estimate is recomputed |

## Available summaries

- Final analytical checklist totals, active/reference/other counts, source-event counts, event blocks, events represented in both primary periods, event-window support, distance-ring support, dominant-observer share, and effective observer replication.
- Region-specific species checklist totals, detections, complete-checklist nondetections, detection prevalence, finite positive numeric reports, numeric availability, structural-unknown counts, and fit status.
- Pooled response-free species X counts, lower-bound counts, ambiguity-affected counts, median, 90th and 99th positive-count percentiles, years, events, observers, locations, and maximum shares.
- Region-specific guild prevalence and positive-numeric availability; transparent guild membership.
- Candidate-frame protocol, duration, travel-distance, and observer-count summaries. These are labeled as response-free candidate-frame summaries because their denominator is not identical to the final analysis frame.

## Unavailable without new aggregate authorization

- Region-specific positive-count quartiles and upper-tail quantiles.
- Region-specific X/lower-bound/ambiguity counts.
- Per-checklist distribution of the number of detected guild members.
- Guild positive-count quantiles and lower/upper ambiguity bounds.
- Concurrent-event linkage distribution.
- Event-date-within-year distribution and per-event checklist-count distribution.
- Raw active/reference/other prevalence and count summaries for individual taxa.
- Fine-grid or hexagonal spatial densities.

These fields remain blank with explicit availability codes. No protected cache is opened, and no value is approximated from a neighboring statistic.

## Spatial plan

The main map uses a public generalized British Columbia polygon and four broad region display anchors. Region-level checklist and recorded-event totals are plotted as labels or symbols. The supplementary support map shows region-level active/reference counts. Display anchors are approximate cartographic positions, not data-derived record coordinates. All displayed regional counts exceed the repository threshold of 20.

The exposure-design schematic is nongeographic. It explains the 0--5 km active zone, 5--20 km contemporaneous reference zone, omitted other class, event-time condition, active-priority rule, concurrent links, and the limitation of representing a traveling checklist by one point coordinate.

## Interpretation rules

- “Detection prevalence” = taxon detections / eligible complete checklists.
- “Complete-checklist nondetection” = eligible checklist omission after frozen ambiguity rules; not confirmed biological absence.
- “Positive reported count” = finite numeric report greater than zero.
- Candidate-frame effort summaries cannot be described as exact final-frame distributions.
- Pooled Stage 2 count quantiles cannot be described as regional or active/reference summaries.
- Event-window and distance-ring proportions are not compositional because concurrent links can place one checklist in multiple strata.
- DFO source-event counts represent recorded linkage support, not herring biomass or complete surveyed presence/absence.
