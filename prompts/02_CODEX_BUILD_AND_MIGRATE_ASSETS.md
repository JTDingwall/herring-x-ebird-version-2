# Codex master task — build `herring-x-ebird-version-2` and migrate validated assets

You are the lead R, data-engineering, reproducibility, and statistical-computing agent for a new private GitHub repository:

- **New repository:** `JTDingwall/herring-x-ebird-version-2`
- **Legacy reference repository:** `JTDingwall/ebird_herring_analysis`
- **Pinned legacy commit:** `f3387d58f6d55a070b86f41ef41e11512dcf7688`

The Version 2 project is a clean, from-scratch reanalysis of the same authoritative eBird and DFO Pacific herring source datasets. It is **not** a branch of Version 1 and must not inherit Version 1 Git history. Reuse validated engineering assets deliberately, with provenance, while replacing the narrow Version 1 scientific design with the broader Version 2 framework.

Read this entire task before editing anything. Then read every existing file in the Version 2 scaffold, especially:

- `AGENTS.md`
- `README.md`
- `docs/00_METADATA_AUDIT.md`
- `docs/01_SCIENTIFIC_FRAMEWORK.md`
- `docs/02_ANALYSIS_DESIGNS.md`
- `docs/03_MODEL_CATALOGUE.md`
- `docs/04_DECISION_RULES.md`
- `docs/05_DATA_GOVERNANCE.md`
- `docs/06_CODEX_EXECUTION_PLAN.md`
- `prompts/00_CODEX_MASTER_PROMPT.md`
- `prompts/01_CODEX_SETUP_METADATA_AND_COOCCURRENCE.md`
- `reports/comprehensive_analysis_plan_v2.html`

## Mission

Build a private, reproducible R/`targets` repository that can extract the maximum defensible ecological information from:

1. the British Columbia eBird Basic Dataset and matching Sampling Event Data; and
2. the DFO Pacific Herring Spawn Index table plus its section and shoreline layers.

The project will ultimately estimate whether herring spawning is associated with:

- more bird detections;
- larger reported flocks;
- higher guild and community counts;
- richer or compositionally different bird assemblages;
- stronger mixed-species aggregation and conditional co-occurrence;
- concentration of birds near spawn and depletion at simultaneous farther locations;
- responses that vary with event timing, distance, extent, intensity, isolation, recurrence, and regional context;
- changes in birder visitation or reporting that must be separated from ecological response.

This setup task must build the repository, migrate approved assets, audit source metadata, reconcile registries, and scaffold the analysis. **Do not fit or inspect Version 2 bird–herring response estimates until the outcome-blind design gate is committed and explicitly approved.** Synthetic fixtures and simulations are allowed.

---

# 1. Create or open the private repository

## 1.1 Remote creation

Check whether `JTDingwall/herring-x-ebird-version-2` exists.

- If it does not exist and GitHub credentials permit creation, create it as **private**, with no auto-generated README, licence, or `.gitignore`.
- If it exists, confirm it is private and inspect all branches before pushing.
- If credentials prevent remote creation, initialize the local repository, set the intended remote, and report the exact authenticated command the investigator must run.

Do not fork the legacy repository. Do not copy its `.git` directory. Do not use a history-preserving subtree merge.

## 1.2 Clean-history requirement

The new repository must have its own root commit. Record the legacy commit only as provenance in documentation and migration manifests.

Before the first push, run a repository privacy scan over the full new history and working tree.

---

# 2. Inspect both repositories before migration

Clone or fetch the pinned legacy commit into a temporary read-only location. Inventory:

- all R functions;
- scripts and orchestration;
- tests and fixtures;
- configuration and metadata registries;
- documentation and bibliography;
- aggregate QA outputs;
- restricted, row-level, model-result, or machine-specific artifacts that must not migrate.

Write:

- `metadata/legacy_repository_inventory.csv`
- `metadata/legacy_asset_migration_manifest.csv`
- `reports/legacy_asset_migration_review.qmd`

The migration manifest must contain at least:

- `source_repository`
- `source_commit`
- `source_path`
- `source_blob_sha`
- `destination_path`
- `asset_class`
- `action` (`COPY`, `ADAPT`, `REFERENCE_ONLY`, `EXCLUDE`)
- `scientific_assumption_carried`
- `privacy_class`
- `reason`
- `tests_required`
- `migration_status`

No asset may be copied merely because it exists.

---

# 3. Allowlisted assets to migrate

Copy or adapt only assets that are generic, validated, privacy-safe, and scientifically compatible. Preserve source attribution in file headers or the migration manifest.

## 3.1 Generic repository and QA infrastructure

Inspect and selectively adapt:

- `R/config.R`
- `R/input_manifest.R`
- `R/join_assertions.R`
- `R/qa_logging.R`
- `R/setup_status.R`
- generic helpers from `scripts/00_setup.R`
- corresponding configuration, manifest, join-cardinality, and QA tests

Requirements:

- remove machine-specific paths;
- parameterize all source paths through environment variables/configuration;
- use deterministic IDs and hashes;
- write aggregate public QA separately from ignored restricted QA;
- do not carry Version 1 scientific locks into generic helpers.

## 3.2 eBird ingestion and processing assets

Inspect and selectively adapt:

- `R/ebird_ingestion.R`
- `R/ebird_processing.R`
- shared-checklist resolution logic;
- explicit EBD/SED schema maps;
- release-pair and many-to-one checklist-key checks;
- zero-filling and count-state parsing logic;
- tests for complete checklists, group checklists, numeric counts, `X`, lower bounds, ambiguity masks, and taxonomy collisions.

Preserve these principles:

- EBD and SED must be a verified matching release pair;
- complete checklists support zero-filled non-detections;
- shared/group copies are one sampling event;
- numeric count, `X`, lower-bound, ambiguous, missing, and zero-filled states remain distinct;
- raw comments, identifiers, and exact coordinates never enter tracked outputs.

Version 2 changes:

- do not restrict processing to the old five species;
- support the canonical expanded species/guild registry;
- support all-year source processing with configurable event-focused and background windows;
- retain fields needed for optional age/sex, behaviour, media, review-status, and comment-awareness diagnostics in ignored local products only.

## 3.3 Taxonomy and species-curation assets

Inspect and selectively adapt:

- `R/species_curation.R`
- `R/species_finalization.R`
- `metadata/species_crosswalk.csv`
- `metadata/analysis_taxa.csv`
- `metadata/guild_membership.csv`
- `metadata/ambiguous_taxon_rules.csv`
- `metadata/analysis_taxa_taxonomy_crosswalk.csv`
- literature-evidence metadata and taxonomy tests

Copy legacy registries into a provenance-only namespace such as:

- `metadata/legacy_v1/`

Do not use them as the final Version 2 registry without reconciliation. Generate one canonical Version 2 taxonomy/species/guild registry and a complete crosswalk from every legacy and scaffold row.

## 3.4 Herring event-engineering assets

Inspect and selectively adapt:

- `R/herring_event_engineering.R`
- source-field and derived-field maps;
- source-preservation logic;
- date parsing and anomaly flags;
- component-completeness handling;
- CRS tests;
- adjacency/overlap diagnostics;
- herring-event unit tests.

Preserve immutable source rows. Version 2 must support, side by side:

1. source-record events;
2. quality-tiered records rather than one universal exclusion rule;
3. event complexes under predeclared spatial/temporal definitions;
4. point, shoreline-anchor, section-shoreline, and uncertainty-footprint exposure representations;
5. separate Surface, Macrocystis, Understory, Length, Width, duration, method, and component-pattern variables;
6. local and regional concurrent-event metrics, isolation, recurrence, relative rank, and cumulative exposure.

Never treat an unobserved herring component as zero. Never call the component sum absolute biomass.

## 3.5 Spatial and temporal linkage assets

Inspect and selectively adapt:

- `R/spatial_linkage.R`
- `R/spatiotemporal_linkage.R`
- shoreline and section QA;
- candidate-link preservation;
- exact-tie handling;
- CRS and distance tests.

Version 2 must not copy the old one-row-per-checklist nearest-event result as the sole exposure product. Build an all-candidate exposure architecture capable of:

- event-relative days;
- event intervals and timing uncertainty;
- multiple simultaneous events;
- concentric rings and continuous distance;
- event-day-zone aggregation;
- cumulative distance/time kernels;
- point versus footprint versus shoreline exposure sensitivity;
- non-event background risk sets without pretending recorded absence is true absence.

## 3.6 Privacy, governance, testing, and references

Inspect and adapt:

- `docs/03_QAQC.md`
- relevant privacy checks from Prompt 11 remediation;
- `tests/testthat/` generic schema/cardinality/privacy tests;
- `docs/07_LITERATURE_ANCHORS.md`
- verified bibliography files;
- aggregate, nonrestricted source metadata summaries needed to confirm migration.

Copy bibliographic entries, not unverifiable prose. Retain only references that can be traced to a primary, official, or peer-reviewed source.

---

# 4. Assets that must not migrate

Do not copy, commit, or recreate from Version 1:

- `data/raw/**`
- `data/interim/**`
- `data/derived/**`
- EBD or SED rows;
- checklist IDs, group IDs, observer IDs, locality IDs, comments, or exact coordinates;
- overlap-weighted checklist tables;
- matching weights or propensity scores;
- fitted model objects, chain files, caches, or bootstrap samples;
- single-species or multispecies coefficient tables;
- Prompt 7, Prompt 8, Prompt 9, or Prompt 13 outcome artifacts as Version 2 inputs;
- exact-point maps or row-level review samples;
- machine-specific paths, credentials, logs, or temporary files;
- the legacy `.git` directory or rewritten history;
- generated HTML reports whose only purpose is to reproduce Version 1 results.

Legacy aggregate results may be cited in the Version 2 rationale, but they are not data inputs and must be labelled `LEGACY_CONTEXT_ONLY`.

---

# 5. Required Version 2 repository structure

Create or reconcile this structure:

```text
.Renviron.example
.gitignore
.github/workflows/
AGENTS.md
DESCRIPTION
LICENSE
README.md
_targets.R
renv.lock
config/
data/raw/README.md
data/interim/.gitkeep
data/derived/.gitkeep
docs/
metadata/
metadata/legacy_v1/
outputs/.gitkeep
prompts/
R/
references/
reports/
reports/assets/analysis_plan/
scripts/
tests/testthat/
```

Use `renv` and `targets`. CI must pass with synthetic fixtures and no raw data.

Recommended scalable data stack:

- `data.table` for streamed text processing;
- `arrow`/Parquet and optionally DuckDB for large derived tables;
- `sf` for spatial operations;
- `targets` dynamic branching by species, guild, event region, and model family;
- `future` or a compatible backend only after deterministic single-worker tests pass;
- `mgcv`, `glmmTMB`, `fixest`, `ordinal`, `brms`/`cmdstanr`, `gllvm` or another justified JSDM engine as registered—not all loaded by default.

Benchmark memory and elapsed time before choosing a full-data engine.

---

# 6. Deep metadata audit before outcome access

Run a complete audit of the locally configured source files.

## 6.1 eBird EBD and SED

Audit:

- exact release names, sizes, SHA-256 values, delimiters, encodings, and headers;
- EBD-to-SED many-to-one checklist relationship;
- unique and missing checklist keys;
- complete-checklist codes;
- protocol labels and effort fields;
- shared/group checklist structure and disagreements;
- date, time, latitude, longitude, county, locality type, project, and observer fields;
- numeric count tokens, `X`, blanks, lower-bound patterns, heaping, maxima, and source-copy disagreements;
- taxonomy concepts, categories, historical names, forms, hybrids, slashes, spuhs, domestic taxa, and parent/ISSF mappings;
- behaviour, age/sex, breeding, media, approved/reviewed, and comment fields for optional diagnostic feasibility;
- observer and locality concentration using anonymized aggregate summaries;
- coverage by year, month, region, section, protocol, observer, locality, and shoreline distance.

Do not write raw text comments or source identifiers to tracked files.

## 6.2 DFO herring table

Audit every field and missingness pattern:

- Region, Year, StatisticalArea, Section, LocationCode, LocationName, SpawnNumber;
- StartDate, EndDate, interval order, duration, uncertainty, and year consistency;
- Longitude, Latitude, Length, Width, Method;
- Surface, Macrocystis, Understory, component count, and component pattern;
- duplicate keys, overlapping intervals, adjacent records, repeated locations, isolated events, concurrent regional event counts, and recurrence across years;
- event rank within section/region/year;
- local and regional cumulative spawn-index context;
- quality tiers and recoverable metadata rather than blanket exclusion.

## 6.3 Spatial layers

Audit complete shapefile bundles, not only `.shp` members:

- bundle hash and sidecars;
- CRS, feature count, geometry type, validity, extent, and fields;
- deterministic WGS84 to EPSG:3005 transformation checks;
- section overlays, shoreline classes, and boundary cases.

## 6.4 Required outputs

Write:

- `metadata/input_manifest.csv`
- `metadata/source_field_registry.csv`
- `metadata/source_checksum_registry.csv`
- `outputs/metadata/` aggregate QA tables
- `reports/metadata_audit.qmd`
- `reports/metadata_audit.html`

Classify discrepancies as `MATCH`, `EXPECTED_CHANGE`, `REQUIRES_REVIEW`, or `FAIL` against the pinned legacy evidence.

No bird-response model may run until all critical metadata checks pass.

---

# 7. Reconcile canonical registries

There are currently overlapping species and model registries in the scaffold. Replace drift with a single source of truth.

## 7.1 Species and guild registry

- Reconcile `metadata/species_registry.csv`, `metadata/species_registry_v2.csv`, and legacy registries.
- Pin the eBird taxonomy version.
- Preserve the expanded candidate list; do not reduce to five focal taxa.
- Record species-level, guild-level, ambiguity-bound, falsification, behaviour/age-sex, and excluded roles separately.
- Define support thresholds by outcome: detection, numeric count, upper-tail count, event-time, distance rings, regions, observers, and localities.
- Use no estimated herring effect in support screening.
- Generate documentation and tests from the canonical registry; remove hard-coded counts.

## 7.2 Model registry

- Reconcile YAML and CSV model registries into one canonical machine-readable registry.
- Preserve all unique models and create a legacy ID crosswalk.
- Add the following explicit modules if absent:
  - pairwise null-adjusted co-occurrence;
  - detection-first JSDM/GLLVM with multiple latent factors;
  - phase- and distance-dependent residual association;
  - network-level mixed-flock summaries;
  - bird-weighted mean distance and spatial concentration;
  - upper-tail/exceedance flock-size models;
  - observer/checklist-richness and numeric-versus-`X` reporting models;
  - optional behaviour and age/sex composition substudies where metadata support them;
  - restricted comment-awareness sensitivity using local, uncommitted text parsing.
- Every model row must specify its estimand, unit, response, exposure, family, random/fixed structure, support gate, validation, multiplicity family, interpretation boundary, and output contract.

## 7.3 Co-occurrence registry

Create:

- `metadata/cooccurrence_pair_registry.csv`
- `metadata/cooccurrence_model_registry.csv`

Include pair-level prior mechanism, guild relationship, taxonomy ambiguity, support requirements, and confirmatory/supporting/exploratory status.

---

# 8. Build the outcome-blind pipeline

Implement and test a `targets` graph through the design gate.

## 8.1 eBird products

Create ignored, partitioned products with explicit schemas:

- canonical checklist table;
- source-to-analysis checklist crosswalk;
- observer-history and locality-history features using strictly prior data;
- species-by-checklist detection/count partitions;
- guild lower-bound, named-only, and inclusive-upper-bound outcomes;
- checklist richness, guild richness, Hill-diversity ingredients, and total associated count;
- optional local-only behaviour, age/sex, media, review, and comment-awareness indicators.

## 8.2 Herring products

Create:

- immutable source-record table;
- quality-tiered event table;
- event-complex tables for each registered definition;
- event timing-uncertainty table;
- event point/shoreline/footprint representations;
- event isolation, recurrence, concurrency, rank, duration, extent, and component-pattern covariates;
- annual section/region context.

## 8.3 Exposure products

Create:

- all candidate checklist–event links;
- event-relative time from at least −90 to +120 days, with core non-overlapping periods registered separately;
- rings `0–1`, `1–2`, `2–3`, `3–4`, `4–5`, `5–10`, and `10–20 km`, plus 0.5 km and continuous distances;
- multi-event cumulative kernels at registered spatial and temporal scales;
- event-day-zone tables;
- bird-independent background risk sets;
- comparison-location candidate pools and contamination flags;
- repeated-location and same-observer support tables;
- bird-weighted-distance computation scaffolds without opening bird outcomes during design selection.

## 8.4 Outcome-blind support report

Report support by:

- species and guild;
- event and event complex;
- year and region;
- event-time period and day bin;
- distance ring;
- observer and locality overlap;
- count type and upper-tail threshold;
- herring quality tier and component pattern;
- source-record versus footprint geometry.

Freeze design alternatives and validation folds before fitting actual outcomes.

---

# 9. Preserve and render the comprehensive analysis plan

Treat `reports/comprehensive_analysis_plan_v2.html` as the investigator-facing design specification. Create a reproducible source such as:

- `reports/comprehensive_analysis_plan_v2.qmd`

Reproduce all sections, example figures, example tables, and lay summaries. All example graphics must remain labelled **ILLUSTRATIVE — NOT EMPIRICAL RESULTS** until replaced by validated Version 2 outputs.

The rendered report must include:

- source and metadata audit plan;
- all hypotheses and estimands;
- species and guild strategy;
- count, encounter, spatial, temporal, intensity, redistribution, co-occurrence, community, phenology, long-term, observation-process, and validation analyses;
- model registry with priority and interpretation boundaries;
- public versus restricted output contracts;
- computational plan and decision gates;
- shells for final figures, tables, and lay summaries.

Do not replace example graphics with real outcomes before the outcome gate is approved.

---

# 10. Privacy and restricted-data controls

The following must never be committed:

- raw EBD/SED rows;
- row-level derived checklist or species data;
- sampling-event, group, observer, or locality identifiers;
- raw comments;
- exact checklist coordinates;
- exact-point maps;
- fitted objects containing restricted row-level data;
- credentials or absolute local paths.

Implement scans over:

- tracked files;
- staged diffs;
- generated reports;
- Git history;
- filenames and file contents.

Public QA must be aggregate and disclosure-safe. Restricted QA belongs in ignored local paths.

---

# 11. Tests and CI

CI must pass without raw data using synthetic fixtures. Add tests for:

- source schema and explicit field maps;
- deterministic file and shapefile-bundle hashes;
- EBD/SED pairing and key cardinality;
- shared-checklist resolution;
- count-state parsing and aggregation;
- taxonomy/crosswalk uniqueness;
- canonical species, guild, model, and co-occurrence registries;
- event complex reproducibility;
- date intervals and timing uncertainty;
- CRS and geometry transformations;
- distance-ring boundaries;
- all-candidate and multi-event exposure accounting;
- join cardinality and source preservation;
- anonymization and privacy scans;
- generated documentation matching registries;
- no hard-coded registry counts;
- deterministic simulation fixtures and validation folds.

Use separate local integration-test tags for full raw-data stages.

---

# 12. Commit sequence

Use bounded commits, for example:

1. `Initialize clean Version 2 repository`
2. `Inventory legacy assets and privacy classes`
3. `Migrate generic ingestion and QA infrastructure`
4. `Migrate taxonomy and herring metadata assets`
5. `Reconcile canonical species guild and model registries`
6. `Add outcome-blind exposure and support scaffolding`
7. `Add cooccurrence and community model scaffolds`
8. `Render comprehensive analysis plan and metadata report`
9. `Pass fixture CI and privacy audit`

Do not squash away the migration manifest or scientific decision trail.

---

# 13. Acceptance criteria

The task is complete only when:

- the new private repository exists with a clean independent history;
- the pinned legacy repository was inspected and the migration manifest is complete;
- no prohibited asset migrated;
- generic reused code has provenance and new tests;
- `renv::restore()` works from a clean clone;
- fixture CI passes with no raw data;
- source metadata audit runs locally when environment paths are provided;
- one canonical species/guild registry exists;
- one canonical model registry exists and includes co-occurrence/community additions;
- the full outcome-blind `targets` graph runs through the support gate;
- the comprehensive HTML analysis plan renders reproducibly;
- restricted-data and history scans pass;
- no Version 2 bird–herring outcome estimate has been opened or fitted;
- all unresolved scientific choices are listed for investigator review.

---

# 14. Final Codex response

Return:

1. repository URL, visibility, default branch, and HEAD SHA;
2. clean-history confirmation;
3. files copied, adapted, referenced, and excluded;
4. migration-manifest summary;
5. source metadata audit status and discrepancies;
6. canonical species, guild, model, and co-occurrence registry counts;
7. `targets`, test, CI, render, and privacy-scan results;
8. raw-data files accessed locally, with only filenames/checksums—not row data;
9. unresolved design decisions;
10. exact next command and gate needed before opening bird outcomes;
11. explicit confirmation that no bird-response estimate was inspected or fitted.
