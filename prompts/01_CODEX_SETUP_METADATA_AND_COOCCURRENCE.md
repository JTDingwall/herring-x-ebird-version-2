# Codex task: set up **Herring × eBird Version 2**

You are the lead R/reproducibility engineer for a new analysis of Pacific herring spawn and eBird checklist data. Work carefully and make the repository auditable, privacy-safe, and suitable for a multi-model ecological analysis.

## Scope of this task

This task is **repository setup, registry reconciliation, and a deep source-metadata audit**. Do not fit or inspect herring-effect estimates for bird detections, counts, guilds, or communities during this setup task. Stop at the metadata/design gate and report what is ready for scientific approval.

The scientific hypothesis will eventually be tested, not assumed: herring spawn may increase bird occurrence, reported flock size, guild richness, community aggregation, and the share of birds near spawn, while simultaneous farther shorelines may lose birds. Preserve and report positive, null, and negative results. Never choose filters or model variants because they strengthen this hypothesis.

## Repositories

- Legacy repository for reference only: `JTDingwall/ebird_herring_analysis`.
- New repository: `JTDingwall/herring-x-ebird-version-2`.
- GitHub repository must be **private** because raw eBird data and row-level derivatives are restricted.
- Display name may be “Herring × eBird Version 2”; use the ASCII repository slug `herring-x-ebird-version-2`.
- Do not edit, rerun, or rewrite the legacy repository.
- The legacy repository may be read for source metadata, checksums, schemas, taxonomy decisions, and reusable QA logic. Do not copy its fitted results, model objects, row-level eBird outputs, or outcome-dependent restrictions into Version 2.

If the supplied Version 2 folder, ZIP, or Git bundle already exists, preserve its Git history and continue from it. Otherwise initialize a new Git repository on `main`, add the private GitHub remote, and create the structure described below.

## Read before changing code

Read, in this order:

1. `AGENTS.md`
2. `README.md`
3. every file under `docs/`
4. every file under `prompts/`
5. every file under `metadata/`
6. `config/project.yml`, `config/model_registry.yml`, and `config/sensitivity_grid.yml`
7. `_targets.R`, `DESCRIPTION`, all current R functions, scripts, and tests
8. the legacy repository’s `metadata/input_manifest.csv`, `docs/06_DATA_SCHEMA.md`, species/guild metadata, and herring field summaries

Write `reports/setup_inventory.md` summarizing what exists, what is authoritative, and every inconsistency found before making scientific changes.

## Known setup inconsistencies that must be resolved outcome-blind

Do not ignore or work around these silently:

1. `prompts/00_CODEX_MASTER_PROMPT.md` refers to `scripts/01_audit_inputs.R`, but the current script is `scripts/01_validate_input_metadata.R`.
2. `docs/06_CODEX_EXECUTION_PLAN.md` refers to an obsolete model-ID sequence that does not match the current registries.
3. `config/model_registry.yml` and `metadata/model_registry.csv` describe different model catalogues and ID systems.
4. `metadata/species_registry.csv` is the expanded candidate list, while `metadata/species_registry_v2.csv` is a smaller legacy-derived list; current tests hard-code a smaller count.
5. `R/metadata_audit.R` currently treats shapefile paths like single files even though expected size and SHA-256 values are for full shapefile bundles.
6. `scripts/00_setup.R` installs packages directly and does not yet provide a complete `renv` workflow.
7. Documentation, registries, tests, and README counts must be generated from canonical registries rather than hand-maintained numbers.

Resolve these by creating machine-readable crosswalks and one source of truth. Do not delete unique registered models or candidate species merely to make files agree.

## Raw input configuration

Use only protected local paths supplied through an untracked `.Renviron`:

```text
HERRING_EBIRD_V2_EBD=/absolute/path/to/ebd_CA-BC_smp_relMay-2026.txt
HERRING_EBIRD_V2_SED=/absolute/path/to/ebd_CA-BC_smp_relMay-2026_sampling.txt
HERRING_EBIRD_V2_HERRING=/absolute/path/to/Pacific_herring_spawn_index_data_2025_EN.csv
HERRING_EBIRD_V2_SHORELINE=/absolute/path/to/FWCSTLNSSP_line.shp
HERRING_EBIRD_V2_SECTIONS=/absolute/path/to/SectionsIntegrated.shp
```

Never copy raw data into Git. Never commit `.Renviron`, EBD/SED rows, checklist IDs, observer IDs, locality IDs, exact checklist coordinates, raw comments, or row-level joins.

Expected source baselines from the legacy audit are:

| Dataset | Expected bytes | Expected SHA-256 |
|---|---:|---|
| eBird EBD | 14,590,250,503 | `5578ccacb1520040d46cd153a9cfef47b48233515ce5d923fcb732a7e904adee` |
| eBird SED | 757,638,279 | `9b5b1893ff5b37c9a4a6faa596e71a5894dcb81bafee214ace33c4beee85b6ed` |
| DFO herring CSV | 3,545,779 | `6d3b2c08e3586bde52f5fe2af602c63014468b54e49dc906bd1f8dfe6706e8ac` |
| BC shoreline shapefile bundle | 20,548,809 | `d5dc7c8f8e7ab59b3f0df2d08e130155ce1ee8c95195249baa54616b59bf8953` |
| DFO sections shapefile bundle | 316,944 | `f91ae390a60e93fc3da7d77f38740b893b280f0e1386cb58716c70ec9b8e1d24` |

For shapefiles, hash the deterministic bundle of approved sidecars, not only the `.shp` file. Require at least `.shp`, `.shx`, `.dbf`, and `.prj`; inventory `.cpg`, `.sbn`, `.sbx`, and `.shp.xml` when present. Match the legacy bundle-hash convention or document and crosswalk any corrected convention.

## Phase A — repository and R environment setup

1. Create or verify a private GitHub repository with default branch `main`.
2. Confirm `.gitignore` blocks raw, interim, derived, model-object, log, HTML, compressed-table, exact-coordinate, checklist-ID, observer-ID, and locality-ID artifacts.
3. Add `.Renviron.example`, never `.Renviron`.
4. Initialize `renv`; use a reproducible R version and create `renv.lock`.
5. Retain an R package-style project with `DESCRIPTION`, `R/`, `tests/testthat/`, `scripts/`, `reports/`, `docs/`, `metadata/`, `config/`, and `_targets.R`.
6. Configure `targets`/`tarchetypes` so each phase has explicit file and QA dependencies.
7. Add Quarto reports for setup, metadata audit, design support, and later results.
8. Add GitHub Actions that run fixture-based unit tests and registry/privacy checks without requiring raw data.
9. Add a privacy scanner that fails when tracked files contain restricted field names, exact coordinate pairs, source IDs, or recognizable EBD/SED extracts.
10. Make setup scripts non-interactive and fail clearly when system libraries or packages are missing.

Use these actual entry points, correcting documentation to match them:

```bash
Rscript scripts/00_setup.R
Rscript scripts/01_validate_input_metadata.R
Rscript scripts/02_validate_registries.R
Rscript scripts/03_profile_source_metadata.R
Rscript tests/testthat.R
```

Add a fast metadata mode that checks existence, bytes, bundle completeness, release pairing, and headers without hashing the 14.6 GB EBD. Add a full mode that verifies all SHA-256 values before any derived dataset is trusted.

## Phase B — deep metadata audit before bird outcomes

Recompute the audit directly from the configured raw files. Do not rely only on the legacy report.

### eBird EBD and SED

- Verify release-name compatibility between EBD and matching SED.
- Inspect exact headers, delimiter, encoding, field order, duplicate columns, types, date formats, and key fields.
- Verify the many-EBD-rows-to-one-SED-checklist relationship using streamed or chunked key audits.
- Profile SED rows by year, month, county, protocol, completeness code, locality type, group identifier, duration, distance, area, observer count, start time, and missingness.
- Profile shared-checklist group sizes and disagreements in effort metadata.
- Audit checklist-key uniqueness and unmatched EBD/SED keys without writing source identifiers to tracked outputs.
- Profile EBD taxonomic categories, taxonomy coverage, observation-count forms (`numeric`, `X`, blank, lower-bound or other nonstandard values), approval/review status, and source concept-year ranges.
- Confirm that complete checklists can be zero-filled without treating ambiguous slash/spuh/hybrid records as named-species detections.
- Report only aggregate summaries to tracked outputs.

### DFO herring data

- Verify all 17 source fields and their units.
- Profile year, Region, StatisticalArea, Section, LocationCode, SpawnNumber, dates, coordinates, Length, Width, Method, Surface, Macrocystis, and Understory.
- Audit missingness, ranges, method levels, component-observation patterns, reversed intervals, date/year discordance, coordinate gaps, and event-key uniqueness.
- Preserve the full source record set.
- Do not treat missing spawn-index components as zero.
- Keep relative spawn index distinct from absolute biomass.
- Profile possible event fragmentation: same-location interval overlap and 1 km/3 day, 2 km/7 day, and 5 km/14 day event-complex definitions.
- Do not choose an event-complex rule from bird outcomes.

### Spatial layers

- Verify CRS, geometry type, validity, field names, feature counts, bounds, and sidecars.
- Test WGS84/EPSG:4326 to BC Albers/EPSG:3005 transformations on deterministic samples.
- Do not expose exact eBird points in tracked figures or tables.

### Required metadata outputs

Write aggregate outputs under `outputs/metadata/` and a human-readable `reports/metadata_audit.qmd`/HTML containing:

- source manifest and provenance;
- exact schema maps;
- row and key accounting;
- field types, levels, ranges, units, and missingness;
- EBD/SED pairing and cardinality QA;
- herring anomaly and component-pattern summaries;
- spatial-layer bundle/CRS QA;
- comparison with every legacy baseline;
- a discrepancy table with `MATCH`, `EXPECTED_CHANGE`, `REQUIRES_REVIEW`, or `FAIL` status.

No bird-response outcome may be opened until all critical metadata checks pass and this report is committed.

## Phase C — canonical registries

### Species and guilds

- Reconcile `metadata/species_registry.csv` and `metadata/species_registry_v2.csv` with a generated crosswalk.
- Preserve the expanded candidate list; do not reduce it to the five Version 1 focal species.
- Deduplicate only by verified taxonomy identity, not common-name similarity.
- Pin the eBird taxonomy version and preserve source taxon concepts and historical mappings.
- Keep named species, slashes, spuhs, hybrids, forms, and domestic taxa distinct.
- Create a canonical species registry with roles such as species model, guild model, ambiguity-bound model, falsification outcome, and excluded-with-reason.
- Make support eligibility outcome-blind: use detections, numeric-count availability, years, sections, events, periods, distance rings, observers, and locations—not estimated herring effects.
- Generate documentation and test expectations from the canonical registry; remove hard-coded row counts.

### Model registry

- Reconcile `config/model_registry.yml` and `metadata/model_registry.csv` into one canonical machine-readable model registry.
- Preserve a `legacy_model_id`/crosswalk for every pre-existing row.
- Prefer one canonical YAML registry and generate the CSV/report from it, or implement an equally strict single-source alternative.
- Add tests proving YAML, generated CSV, documentation, and `_targets.R` agree.
- Do not discard a unique model because its ID conflicts with another file.
- Do not authorize model fitting during this setup task.

## Required treatment of bird co-occurrence and mixed-species aggregation

Bird species may travel, forage, or aggregate together, and a checklist with many birds can have a higher probability of containing additional species. Make this an explicit Version 2 analysis component rather than treating species as independent.

Create `metadata/cooccurrence_pair_registry.csv` before outcomes are inspected. Include:

- pair ID and both taxon IDs;
- shared guild/foraging mechanism;
- prior reason for possible association, such as mixed flocking, shared prey, similar diving habitat, scavenging aggregation, or no prior expectation;
- whether the pair is confirmatory, supporting, or exploratory;
- support thresholds and taxonomy ambiguity flags.

Register and scaffold at least these analyses:

### 1. Descriptive and null-adjusted co-occurrence

For the zero-filled checklist-by-species detection matrix, calculate by phase and distance zone:

- pairwise co-detection frequency;
- Jaccard index;
- phi correlation;
- pairwise odds ratio with stable handling of sparse cells;
- observed-minus-expected or standardized effect size under a null model that preserves species prevalence and checklist richness within appropriate year, calendar, region, protocol, and effort strata.

Raw co-detection alone is not evidence that species attract one another.

### 2. Joint species distribution model / GLLVM

Fit a later detection-first JSDM/GLLVM with:

- one row per eligible complete checklist and one column per supported species;
- species-specific herring event-time, distance, and intensity coefficients;
- checklist effort, protocol, time, season, accessibility, location, observer, event, and year structure;
- multiple latent factors with species-specific loadings;
- enough factors to represent more than one community gradient, selected by outcome-blind simulation/predictive criteria;
- no shared rank-one contextual structure like the failed Version 1 multispecies model;
- event-, location-, observer-, and species-aware validation.

Use `gllvm`, `Hmsc`, `sjSDM`, `boral`, or a carefully justified Bayesian implementation after a small hash-identical pilot. Do not begin with custom Stan unless existing packages cannot represent the registered estimand.

The JSDM must separate:

1. **shared environmental response** to herring, habitat, calendar, and effort; from
2. **residual species association** remaining after those variables are controlled.

Interpret residual association as conditional co-occurrence, not proof of direct social attraction, facilitation, or shared travel.

### 3. Phase- and distance-dependent association

Assess whether the residual association matrix changes between:

- early pre, immediate pre, spawn start, early egg, late egg, and post periods; and
- near-spawn and outer distance zones.

Compare rotation-invariant residual covariance/correlation matrices, not raw latent-factor labels. Use herring-event bootstrap or compatible Bayesian uncertainty. Report only stable pairwise changes or community-level summaries after multiplicity/shrinkage control.

### 4. Community and guild responses

Retain complementary models for:

- total herring-associated reported bird count;
- guild total count;
- guild any-detection;
- species and guild richness;
- Hill diversity;
- community composition/ordination;
- latent community scores;
- network-level summaries such as mean positive residual association, modularity, and guild clustering, with bootstrap stability.

### 5. Avoid endogenous “other birds” adjustment in primary models

Do **not** simply add the contemporaneous total number of other birds on the same checklist as a routine covariate in the primary herring-effect model. It is another simultaneous outcome, may be affected by herring, may mediate the ecological response, and can create mathematical coupling or collider/endogeneity bias.

If an exploratory conditional model is implemented, use a leave-one-species-out assemblage measure, pre-register it, label it descriptive/mediational, and never use it to replace the joint model or to claim that one species causes another to appear.

### 6. Observation-process distinction

Because conspicuous mixed-species flocks may change observer behavior, separately model:

- checklist submission allocation;
- unique-observer allocation;
- observer continuity;
- numeric versus `X` count reporting;
- checklist richness as a function of effort and observer skill.

Show these diagnostics beside community results so ecological co-occurrence is not confused with birder response.

## Phase D — pipeline scaffolding only

Create a tested `targets` graph through the outcome-blind support stage:

1. input manifest and metadata audit;
2. canonical taxonomy/species/guild/model/co-occurrence registries;
3. streamed complete-checklist construction;
4. shared-checklist crosswalk kept only in ignored storage;
5. count parsing with distinct detection, numeric, `X`, lower-bound, ambiguous, and missing states;
6. herring source-record and event-complex tables;
7. spatial/temporal candidate-link specifications;
8. outcome-blind support summaries by species, guild, event, year, ring, period, observer, and location;
9. simulated-data model-family benchmarks;
10. frozen validation folds and model hashes.

During setup, functions and tests may use synthetic fixtures only. Do not run actual bird-response models.

## Testing requirements

Add or repair tests for:

- exact schema requirements and explicit field maps;
- deterministic bundle hashing;
- EBD/SED release and many-to-one key relationship;
- shared-checklist resolution and source preservation;
- numeric/`X`/lower-bound/ambiguous count handling;
- taxonomy crosswalk uniqueness;
- species, guild, model, and co-occurrence registry keys;
- no undefined model/species/guild references;
- distance-ring boundaries and multi-event exposure accounting;
- event-complex reproducibility;
- date and CRS transformations;
- join cardinality at every stage;
- no restricted fields or exact coordinates in tracked outputs;
- generated documentation matching canonical registries;
- no hard-coded species/model counts that can drift.

CI must pass without raw data by using small synthetic fixtures. Local full-data tests may be marked and run only when input environment variables are present.

## Git and privacy requirements

Before each push:

1. run unit tests and registry consistency checks;
2. scan tracked files and Git history for restricted identifiers and source data;
3. verify `git status` contains no raw/interim/derived data;
4. inspect staged diffs;
5. commit with a bounded message;
6. push only code, aggregate metadata, tests, configuration, and documentation.

Do not publish the repository until the restricted-data scan passes.

## Setup acceptance criteria

The setup task is complete only when:

- the private GitHub repository exists and `main` is current, or exact push commands are reported if credentials prevent creation;
- `renv::restore()` works from a clean clone;
- fixture-based CI and local tests pass;
- actual script names and documentation agree;
- a single canonical species/guild registry exists, with an auditable crosswalk from both current species files;
- a single canonical model registry exists, with an auditable crosswalk from both current model files;
- co-occurrence/JSDM, phase-dependent residual association, and null-adjusted pairwise analyses are explicitly registered;
- shapefile bundle hashing is correct;
- fast and full input-audit modes work;
- the full metadata audit matches or transparently explains differences from the legacy baselines;
- no row-level bird outcome has been modeled;
- no restricted data are tracked;
- `reports/setup_inventory.md` and `reports/metadata_audit.qmd` are complete;
- a machine-readable gate states `READY_FOR_OUTCOME_BLIND_DESIGN_REVIEW` or gives explicit blocking failures.

## Final response to the investigator

Return:

1. repository URL and latest commit SHA;
2. concise file/change summary;
3. test and CI results;
4. metadata-audit status and every discrepancy;
5. canonical species, guild, model, and co-occurrence registry counts;
6. privacy scan result;
7. exact blockers or manual decisions;
8. the next proposed bounded Codex task;
9. confirmation that no bird-response outcomes were opened or modeled.

Stop after this response. Do not proceed to full zero-filling, exposure-response estimation, or model fitting without explicit authorization.
