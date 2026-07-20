# Codex prompt — Set up Herring × eBird Version 2, including community co-occurrence

You are Codex acting as a senior R, spatial-ecology, and reproducible-research engineer. Work only inside the new repository `herring-x-ebird-version-2`. Do not modify or rerun the Version 1 repository except to read its input manifest, source metadata, and reusable non-result-specific implementation patterns.

## Project objective

Set up a clean Version 2 analysis that uses the authoritative DFO Pacific herring spawn data and matched eBird EBD/SED data to test a broad, triangulated ecological hypothesis:

> Pacific herring spawning produces a short-lived resource pulse that increases local bird numbers, flock sizes, species richness, and multispecies aggregation near spawn, while potentially reducing bird allocation at simultaneous farther shorelines through redistribution.

The project must analyze occurrence, reported counts, distance, event timing, spawn intensity/extent, guild responses, regional redistribution, community composition, and species co-occurrence. Multiple models are for triangulation, not for selecting whichever result is most favorable.

## Scientific requirement: species co-occurrence and mixed assemblages

Bird species are not independent. Several species may respond to the same herring pulse, use social information, join mixed-species feeding aggregations, or simply be more likely to be recorded when total bird abundance is high. Build this dependence into the data architecture and model registry from the beginning.

Distinguish four processes:

1. **Shared environmental response:** species co-occur because they independently respond to spawn, habitat, season, tide, weather, or location.
2. **Residual ecological association:** species remain positively or negatively associated after measured environmental and observation covariates are controlled.
3. **More-individuals/sampling effect:** checklists with more individual birds mechanically tend to contain more species.
4. **Observation-process association:** conspicuous aggregations, observer skill, effort, or preferential birder visitation increase the probability that multiple species are reported together.

Do not describe checklist-scale co-detection as proof that species physically traveled together. eBird checklists identify co-recording within a sampling event, not flock membership or coordinated movement. Physical mixed-flock or traveling-together claims require dedicated observations, standardized behavior data, or explicit checklist comments and must remain a separate descriptive analysis.

Do not include total bird count, guild richness, or another species' observed presence as ordinary adjustment covariates in the primary herring-effect models. Those variables can be caused by spawn and are therefore potential mediators or colliders. Analyze them as outcomes, latent community structure, secondary mediation/descriptive quantities, or prespecified conditional-prediction analyses.

## Read before changing code

Read, in this order:

1. `AGENTS.md`
2. `README.md`
3. every file under `docs/`
4. `config/project.yml`, `config/model_registry.yml`, and `config/sensitivity_grid.yml`
5. every CSV under `metadata/`
6. all current tests
7. the Version 1 files `metadata/input_manifest.csv`, `config/project.yml`, `docs/06_DATA_SCHEMA.md`, and the relevant source-field maps only to locate and verify the authoritative inputs

Do not copy Version 1 fitted models, biological coefficients, outcome-selected decisions, or restricted outputs into Version 2.

## Scope of this Codex task

Complete repository setup, source-path configuration, metadata verification, registry expansion for co-occurrence, and the outcome-blind data/model scaffolding. Do not fit or inspect Version 2 herring-effect models in this task. Stop at a human review gate after the metadata and support architecture is complete.

## Phase 0 — Repository and environment setup

1. Confirm the repository is on branch `main` and has no uncommitted restricted data.
2. Create or repair the R project structure using `renv`, `targets`, `tarchetypes`, and `testthat`.
3. Use memory-safe tooling appropriate for a roughly 14.6 GB EBD file. Benchmark candidate ingestion approaches on bounded chunks before choosing one. Candidate packages include `data.table`, `duckdb`, and `arrow`; do not require all of them if one tested approach is sufficient.
4. Add required analytical dependencies only through `renv`. Core candidate packages include `sf`, `data.table`, `yaml`, `jsonlite`, `digest`, `targets`, `tarchetypes`, `testthat`, `mgcv`, `glmmTMB`, `fixest`, `vegan`, `gllvm`, `iNEXT` or an equivalent rarefaction package, and plotting/reporting dependencies. Treat `brms`/`cmdstanr` as optional until a small model-identical pilot is justified.
5. Ensure `.gitignore` excludes all raw EBD/SED files, row-level derived checklists, observer IDs, locality IDs, exact checklist coordinates, model caches containing restricted rows, and temporary database files.
6. CI must run only on synthetic fixtures and public aggregate registries; it must never require or expose restricted source data.
7. Add platform-independent setup scripts for Windows, macOS, and Linux where necessary. Do not hard-code user-specific absolute paths.

## Phase 1 — Authoritative input discovery and metadata audit

Use Version 1's input manifest only to locate the investigator's local source files. Configure Version 2 to reference the same immutable files by external path or safe local symlink. Never copy the 14.6 GB EBD into Git.

Verify and record:

- file existence, byte size, SHA-256, release names, and matching EBD/SED release;
- exact headers, delimiter, encoding, and required source fields;
- shapefile sidecars and CRS;
- eBird checklist key cardinality between EBD and SED;
- complete-checklist coding, protocol labels, group-checklist structure, date range, effort fields, start time, observer, locality, coordinate, behavior, and comment-field availability;
- herring field names, types, units, missingness, date anomalies, event-key uniqueness, Method levels, component-observation patterns, Length and Width support, and coordinate ranges;
- whether any source release or checksum differs from the existing Version 2 metadata audit.

All differences must be reported. Never force source data to match an expected audit value.

Write only aggregate metadata products under `outputs/metadata_audit/` and a human-readable Quarto report. No checklist IDs, observer IDs, locality IDs, comments, or exact eBird coordinates may enter tracked output.

## Phase 2 — Registry and data-contract setup

### Species and guilds

Validate the expanded species registry against the pinned eBird taxonomy. Retain source taxon concepts and explicit handling for species, ISSFs, forms, slashes, spuhs, hybrids, domestic taxa, and unidentified groups. Do not allocate ambiguous records to named species.

Preserve mechanistic guilds, including roe-diving sea ducks, gull roe feeders, active-spawn piscivores, intertidal roe foragers, shoreline scavengers/raptors, surface/vegetation roe feeders, and alcids. A species may have a species model and contribute to a guild model.

### Required checklist-level outcome fields

Design one auditable checklist-by-taxon structure containing, at minimum:

- detection;
- numeric reported count;
- count type: numeric, `X`, zero-filled, lower-bound, ambiguous, or missing;
- numeric lower bound where defensible;
- taxonomic ambiguity flags;
- checklist effort and observer-process fields;
- event exposure fields without duplicating a checklist as if duplicate rows were independent.

Also design checklist-by-guild and checklist-by-community products containing:

- any guild detection;
- guild species richness;
- summed named-species count;
- lower- and upper-bound guild count under ambiguous taxa;
- total herring-associated bird count;
- total individuals excluding each focal species for descriptive/mediation analyses;
- raw species richness;
- Hill diversity and coverage-standardized or rarefied richness;
- large-aggregation thresholds;
- checklist-level species detection and count matrices for multivariate models.

### Co-occurrence model registry additions

Add explicit, machine-readable model rows for the following analyses. Use new stable IDs and preserve all existing model rows.

1. **Community latent-factor JSDM:** detection matrix with species-specific spawn, event-time, distance, effort, seasonality, event, observer, and location effects plus at least two latent factors. Species-specific contextual effects are required; do not reproduce the Version 1 rank-one shared random-effect structure.
2. **Multivariate count or hurdle model pilot:** for a bounded set of well-supported species/guilds, jointly model encounter and positive counts while allowing cross-species covariance. Run only after simulation and a model-identical pilot.
3. **Residual co-occurrence network:** estimate residual species associations after controlling for spawn exposure, event time, distance, calendar, location, effort, and observer structure. Report uncertainty and stability under event-level resampling.
4. **Phase-specific association comparison:** compare residual association matrices or latent-factor structure across pre-spawn, active/egg, post-spawn, and simultaneous comparison conditions. Use a prespecified permutation or bootstrap that respects herring event and checklist clustering.
5. **Richness–abundance decomposition:** model total associated count, raw richness, rarefied/coverage-standardized richness, and Hill diversity separately. This must distinguish a true compositional/diversity response from the mechanical result that more individuals produce more detected species.
6. **Joint aggregation index:** model the number of guilds/species simultaneously present and the probability that multiple prespecified guilds exceed abundance thresholds on the same checklist.
7. **Conditional species prediction:** as a secondary descriptive model only, estimate whether species B is more likely when species A or a community latent score is present after environmental adjustment. Label this predictive association, not causation or facilitation.
8. **Null co-occurrence analysis:** compare observed pairwise co-detection and abundance association with null matrices preserving checklist effort strata, species prevalence, season, geography, and event structure. Do not use raw unadjusted correlations as ecological evidence.

For every co-occurrence model, record the exact ecological interpretation and the alternative explanations: shared habitat, shared spawn response, unmeasured environment, observer behavior, and the more-individuals effect.

## Phase 3 — Herring and exposure scaffolding

Create tested functions and data contracts, but do not open bird outcomes yet, for:

- immutable herring source records;
- source-record quality tiers rather than one universal complete-case exclusion;
- event complexes at 1 km/3 days, 2 km/7 days, and 5 km/14 days;
- start-date, end-date, midpoint, interval, and decay timing definitions;
- point distance, shoreline-projected distance, extent/uncertainty sensitivity using Length and Width, and section/location-level fallback;
- non-overlapping distance rings: 0–1, 1–2, 2–3, 3–4, 4–5, 5–10, and 10–20 km;
- all-event cumulative exposure kernels at 0.5, 1, 2, 3, 5, and 10 km scales;
- event-day support from at least −60 to +90 days;
- separate Surface, Macrocystis, Understory, Length, Width, Method, component-count, and relative-index fields;
- a dynamic simultaneous comparison definition that always says “no recorded active spawn within the specified radius,” never confirmed absence.

## Phase 4 — Outcome-blind support and simulation scaffolding

Before fitting any ecological response, create aggregate support tables by species, guild, event, year, section/region, distance ring, event-day bin, observer, locality, protocol, and count type.

Simulate realistic data using observed prevalence, zero inflation, positive-count tails, heaping, `X` frequency, event clustering, observer clustering, species covariance, and co-occurrence. Use simulation to determine which model families are identifiable and computationally feasible. Do not select the model family by viewing the sign or significance of a real herring effect.

Freeze:

- analysis periods;
- distance rings and continuous kernels;
- event-time windows;
- species/guild support rules;
- rarefaction/coverage-standardization rules;
- validation folds;
- event-level bootstrap seeds;
- model formulas and prior families for any Bayesian pilots;
- all registry and configuration hashes.

## Required testing

Add tests for:

- all source and analysis keys;
- many-to-one EBD–SED joins;
- shared-checklist deduplication;
- zero filling;
- numeric/`X`/lower-bound/ambiguous count separation;
- herring missing-component handling;
- event-complex determinism;
- non-overlapping ring assignment;
- multi-event exposure without independent-row duplication;
- species and guild matrix dimensions;
- focal-species-excluded community totals;
- rarefaction reproducibility;
- co-occurrence null-model margin preservation;
- no rank-one cross-species contextual restriction;
- privacy scans of every tracked output.

## Required deliverables before stopping

1. A restored and locked `renv` environment.
2. A passing fixture-based test suite.
3. A source input manifest with verified hashes and schema.
4. An aggregate metadata-audit report.
5. Validated species, guild, estimand, and model registries.
6. Updated scientific framework containing an explicit co-occurrence hypothesis.
7. Updated model catalogue containing the eight co-occurrence analyses above.
8. Tested data contracts for checklist, taxon, guild, community, herring event, exposure, and support tables.
9. A `targets` graph through metadata audit and outcome-blind support scaffolding.
10. A concise human review memo listing every discrepancy, unresolved decision, computational risk, and proposed next phase.

## Hard stop

Stop after these setup and outcome-blind deliverables. Do not fit, inspect, rank, or interpret any Version 2 bird–herring outcome model until the investigator approves the metadata audit, species/guild registry, co-occurrence definitions, support rules, and frozen model registry.
