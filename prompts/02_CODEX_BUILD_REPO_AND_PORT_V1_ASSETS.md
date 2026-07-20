# Codex task — build the clean Version 2 repository and port reusable Version 1 assets

You are the lead R, Git, reproducibility, and privacy engineer for **Herring × eBird Version 2**.

Your task is to create and fully initialize a new private GitHub repository named:

```text
JTDingwall/herring-x-ebird-version-2
```

This must be a **new repository with a clean Git history**, not a branch, fork, subtree merge, or history rewrite of `JTDingwall/ebird_herring_analysis`.

The legacy repository is a read-only provenance source:

```text
JTDingwall/ebird_herring_analysis
```

Version 1 established valuable ingestion, taxonomy, QA, spatial, privacy, and reproducibility infrastructure, but its fitted models, weights, outcomes, and manuscript history must not become the analytical starting point for Version 2.

## 1. Read first

Before modifying anything, read in this order:

1. `AGENTS.md`
2. `README.md`
3. `docs/00_METADATA_AUDIT.md`
4. `docs/01_SCIENTIFIC_FRAMEWORK.md`
5. `docs/02_ANALYSIS_DESIGNS.md`
6. `docs/03_MODEL_CATALOGUE.md`
7. `docs/04_DECISION_RULES.md`
8. `docs/05_DATA_GOVERNANCE.md`
9. `docs/06_CODEX_EXECUTION_PLAN.md`
10. `docs/07_COMPREHENSIVE_ANALYSIS_PLAN.md`
11. `reports/comprehensive_analysis_plan.html`
12. every file under `metadata/`, `config/`, and `prompts/`

Treat `reports/comprehensive_analysis_plan.html` and `metadata/analysis_module_registry.csv` as the current broad scientific blueprint. Treat current registries as provisional until they are reconciled.

## 2. Non-negotiable scientific boundary

This setup task may inspect source metadata, code, schemas, taxonomy, aggregate support summaries, and QA logic. It must **not fit or inspect any new Version 2 bird-response effect**.

Do not open, model, rank, or select specifications based on focal bird detections or counts during repository setup.

Do not optimize the setup to make the hypothesis look true. The hypothesis to be tested later is that herring spawn may increase local bird occurrence, reported flock size, total associated bird count, guild richness, community aggregation, and near-spawn spatial allocation while decreasing allocation to simultaneous farther shorelines. Positive, null, negative, and contrary responses are all valid outcomes.

Stop at an outcome-blind metadata/design gate.

## 3. Resolve the exact source commit

Do not assume the source SHA from documentation is still current.

1. Resolve the current `main` SHA of `JTDingwall/ebird_herring_analysis` using authenticated GitHub access.
2. Record:
   - repository URL;
   - resolved SHA;
   - commit date;
   - commit message;
   - whether it differs from the previously audited baseline `f3387d58f6d55a070b86f41ef41e11512dcf7688`.
3. Pin all source inspection and file extraction to the resolved SHA.
4. Never import the source repository’s `.git` directory, branch history, pull-request refs, tags, or model artifacts.

Write this evidence to:

```text
metadata/v1_source_commit.json
```

## 4. Create or verify the destination repository

If the GitHub repository does not exist:

```bash
git init -b main
gh repo create JTDingwall/herring-x-ebird-version-2 \
  --private \
  --source=. \
  --remote=origin
```

If it exists, verify that:

- it is owned by `JTDingwall`;
- visibility is private;
- default branch is `main`;
- it is not a fork;
- its history does not contain Version 1 commits or restricted files;
- `origin` points only to the Version 2 repository.

Do not push until the local privacy scan, registry tests, and provenance audit pass.

## 5. Preserve a clean history

The destination repository must not inherit Version 1 history. Port files by allowlisted extraction from a pinned commit, for example:

```bash
git --git-dir=/path/to/read_only_v1/.git show <PINNED_SHA>:R/config.R > /tmp/v1_config.R
```

or with an allowlisted `git archive` path set.

Never:

- add Version 1 as a mergeable remote and merge it;
- copy its `.git` directory;
- use `git clone --mirror`;
- import pull-request refs;
- use a history-preserving subtree;
- copy an entire source tree and delete unwanted files afterward.

The rule is **allowlist first**, not “copy everything, then clean.”

## 6. Asset-porting principles

Every reused asset must be classified as one of:

- `copy_exact`: scientifically and operationally identical;
- `port_and_generalize`: useful logic but contains Version 1 assumptions;
- `reference_only`: read for evidence, do not copy;
- `reject`: obsolete, outcome-specific, privacy-sensitive, or incompatible.

Create:

```text
metadata/v1_asset_port_manifest.csv
```

with one row per evaluated source asset and these fields:

```text
source_repo
source_sha
source_path
destination_path
asset_classification
action
scientific_assumptions_found
changes_made
restricted_field_scan
machine_path_scan
tests_added_or_updated
review_status
notes
```

No ported file may be committed without a manifest row.

## 7. Allowlisted source assets

Use `config/v1_asset_port_allowlist.yml` as the machine-readable starting point. Inspect each asset before copying. The following categories are eligible.

### 7.1 Generic repository and package infrastructure

Eligible for reference or careful porting:

- `DESCRIPTION`
- `NAMESPACE`
- `.Rprofile`
- `renv.lock`
- `_targets.R`
- `scripts/00_setup.R`
- generic package/test bootstrap files

Rules:

- do not blindly replace the Version 2 scaffold;
- merge dependency requirements deliberately;
- remove Version 1 model-stage dependencies that are not needed;
- add Version 2 dependencies only when a registered module requires them;
- regenerate `renv.lock` from the reconciled project rather than trusting stale platform-specific state;
- keep operating-system-specific executable paths out of tracked configuration.

### 7.2 Generic R validation and provenance utilities

Eligible for `copy_exact` or `port_and_generalize` after tests:

- configuration loading and validation;
- input-manifest generation and SHA-256 helpers;
- shapefile-bundle inventory logic;
- join-cardinality assertions;
- QA logging and stage-gate helpers;
- safe anonymization helpers;
- deterministic ID helpers that do not expose source identifiers;
- source-field/header inspection;
- model/analysis hash helpers;
- privacy scanners;
- session-information capture.

Candidate source files include:

```text
R/config.R
R/input_manifest.R
R/join_assertions.R
R/qa_logging.R
R/model_cache.R
R/model_engine_audit.R
R/setup_status.R
```

Port only functions that are still general. Split mixed files instead of importing outcome-specific code.

### 7.3 eBird ingestion and checklist-processing logic

Eligible for generalization:

```text
R/ebird_ingestion.R
R/ebird_processing.R
```

Retain or improve:

- explicit EBD/SED field maps;
- exact checklist-key validation;
- many-to-one EBD-to-SED cardinality checks;
- shared-checklist collapse with source crosswalk;
- complete-checklist filtering;
- configurable protocol and effort rules;
- zero-filling;
- preservation of numeric, `X`, lower-bound, ambiguous, and missing count states;
- chunked or database-backed processing suitable for a ~14.6 GB EBD;
- full exclusion accounting;
- strict no-raw-data-in-Git behavior.

Generalize away:

- the five-species-only pipeline;
- the fixed 2015–2025 primary period;
- one fixed 5 km exposure;
- outcome-specific support thresholds;
- assumptions that encounter probability is the sole primary response.

### 7.4 Taxonomy and species/guild assets

Eligible for porting:

```text
metadata/species_crosswalk.csv
metadata/analysis_taxa.csv
metadata/guild_membership.csv
metadata/ambiguous_taxon_rules.csv
R/species_curation.R
R/species_finalization.R
```

Requirements:

- preserve the pinned taxonomy version and every source concept;
- preserve named species, ISSF parent mappings, forms, hybrids, intergrades, slashes, spuhs, and domestic categories distinctly;
- never allocate an ambiguous taxon to a named species without an approved mapping;
- support guild lower/upper bounds when every possible identity belongs to the same guild;
- reconcile the current 58-row candidate registry with the 47-row legacy-derived support registry;
- produce one canonical species registry, one canonical guild registry, and one source-taxonomy crosswalk;
- keep observed-support fields separate from ecological-priority fields;
- do not inspect effect estimates when deciding eligibility.

### 7.5 Herring event and spatial metadata logic

Eligible for careful generalization:

```text
R/herring_event_engineering.R
R/spatial_linkage.R
R/spatiotemporal_linkage.R
```

Retain:

- all 17 authoritative herring fields;
- immutable source-record IDs;
- WGS84 source coordinates and BC Albers analysis CRS;
- explicit start/end parsing;
- Surface, Macrocystis, and Understory as distinct components;
- missing components as missing, never zero;
- length, width, method, section, location, and region metadata;
- source-record geometry and precision flags;
- source-to-derived-event crosswalks;
- full anomaly audits;
- all-candidate linkage tables and exact-tie preservation.

Generalize for Version 2:

- retain strict source-record events but also build event complexes under registered 1 km/3 day, 2 km/7 day, and 5 km/14 day rules;
- replace universal seven-flag exclusion with registered event-quality tiers;
- create start, end, midpoint, interval, and jitter-ready timing fields;
- create point, conservative extent, shoreline-linked, and event-complex geometry candidates;
- compute distance rings at 0.5, 1, 2, 3, 4, 5, 10, and 20 km;
- create all-event cumulative exposure kernels;
- preserve multi-event membership and never treat duplicated event-checklist rows as independent.

### 7.6 QA, schema, and literature documents

Eligible for reference or porting into a clearly labelled `docs/v1_reference/` area:

```text
docs/03_QAQC.md
docs/06_DATA_SCHEMA.md
docs/07_LITERATURE_ANCHORS.md
```

Do not import Version 1 locked decisions as Version 2 decisions. Create a crosswalk that labels each assumption:

- retained;
- generalized;
- superseded;
- rejected;
- pending Version 2 support gate.

### 7.7 Generic tests

Eligible for porting and expansion:

- config/schema tests;
- checksum and shapefile-bundle tests;
- join-cardinality tests;
- shared-checklist tests;
- zero-fill tests;
- taxonomy mapping tests;
- herring source-preservation tests;
- CRS and distance-unit tests;
- privacy tests;
- deterministic hash/ID tests.

Do not import tests whose only purpose is to freeze a Version 1 coefficient, weight, five-species list, single 5 km buffer, 2015–2025 period, or Prompt-specific result.

## 8. Reference-only Version 1 evidence

The following may be read and summarized but must not be copied as live Version 2 analytical inputs:

- aggregate input manifest and source checksums;
- source-field maps and herring field summaries;
- aggregate zero-fill status;
- aggregate species detection/count support;
- aggregate event/phase support;
- Version 1 scientific-conservatism audit;
- Prompt 7/8/9/12/13 decision and validation summaries;
- metadata describing privacy remediation.

Use these only to:

- verify expected source versions;
- design tests;
- identify known failure modes;
- document why Version 2 differs;
- confirm that the local raw inputs match expected checksums.

Do not import any Version 1 bird-response estimate as a Version 2 result.

## 9. Prohibited assets and patterns

Use `config/v1_asset_port_denylist.yml` and add any newly discovered risk.

Never copy or commit:

```text
.git/**
.github pull-request refs from Version 1
.Renviron
credentials or tokens
data/raw/**
data/interim/**
data/derived/**
restricted EBD or SED rows
sampling_event_identifier values
source observer IDs
source locality IDs or names
exact checklist coordinates
checklist/species comments or verbatim excerpts
row-level checklist-to-event links
matching weights or matched checklist tables
fitted model objects
Stan chain CSVs
bootstrap row samples
Version 1 coefficient/effect tables
Version 1 manuscript result figures
Version 1 rendered outcome HTML
machine-specific absolute paths
```

Also reject source files containing any of these unless they are rewritten and the restricted content is removed before staging.

## 10. Required repository structure

Reconcile the project into this minimum structure:

```text
AGENTS.md
README.md
DESCRIPTION
NAMESPACE
renv.lock
_targets.R
.Rprofile
.Renviron.example
.gitignore
.gitattributes
.github/workflows/
R/
config/
data/raw/README.md
data/interim/.gitkeep
data/derived/.gitkeep
docs/
metadata/
outputs/.gitkeep
prompts/
references/
reports/
scripts/
tests/testthat/
```

Add:

```text
metadata/v1_source_commit.json
metadata/v1_asset_port_manifest.csv
metadata/canonical_species_registry.csv
metadata/canonical_guild_registry.csv
metadata/analysis_module_registry.csv
metadata/model_registry.csv
metadata/estimand_registry.csv
metadata/figure_registry.csv
metadata/table_registry.csv
metadata/input_manifest.csv
reports/comprehensive_analysis_plan.html
reports/repository_setup_audit.html
```

## 11. Reconcile current scaffold inconsistencies

Before adding new code, inventory and resolve at least these known inconsistencies:

1. `metadata/species_registry.csv` has 58 candidates, while `metadata/species_registry_v2.csv` has 47 legacy-derived rows.
2. Guild names differ between the broad candidate registry and `metadata/guild_registry_v2.csv`.
3. The 33-row model registry and the 50-row estimand-oriented analysis-module registry overlap but are not identical.
4. README references and script names are stale in places.
5. Existing tests may hard-code old registry counts.
6. Existing setup may lack a complete, portable `renv.lock`.
7. Shapefile validation must compare complete bundles, not only a `.shp` file against a bundle checksum.
8. Source paths must come from environment variables, not copied Windows paths.
9. The current scaffold may contain duplicate setup prompts; retain one canonical setup prompt and archive or remove superseded versions with a decision record.
10. Every current figure and table in the comprehensive plan must be explicitly labelled synthetic/illustrative.

Write a reconciliation report before implementation:

```text
reports/repository_inventory_and_reconciliation.md
```

## 12. Canonical registry design

Create one authoritative registry for each concept.

### 12.1 Species registry

Required fields:

```text
analysis_taxon_id
common_name
scientific_name
ebird_taxon_code
source_taxon_concept_ids
taxonomy_version
guild_ids
priority_tier
ecological_mechanism
evidence_strength
expected_direction
expected_timing
count_strategy
taxonomic_complications
support_status
species_model_status
guild_model_status
approval_status
```

Support status must be outcome-blind and based on coverage, not an estimated herring effect.

### 12.2 Guild registry

Allow species to belong to more than one guild only when the overlap is scientifically explicit. Record:

```text
guild_id
guild_label
mechanism
membership_rule
expected_timing
expected_spatial_response
primary_outcomes
dominance_audit_required
ambiguity_bound_rule
analysis_priority
```

### 12.3 Estimand and model registries

Keep these separate:

- **estimand registry**: the ecological quantity being estimated;
- **model registry**: a statistical implementation for an estimand;
- **analysis-module registry**: workflow-level modules including descriptive, diagnostic, validation, and synthesis tasks.

A model may not be fitted unless it maps to an approved estimand and module.

## 13. Co-occurrence and multispecies architecture

Make the user’s co-occurrence hypothesis explicit:

> During herring spawn, species may co-occur, feed, or travel in mixed aggregations, so the presence or abundance of one species may be associated with other species appearing.

Implement registries and scaffolding for:

1. raw pairwise co-detection and count association;
2. null-adjusted co-occurrence preserving prevalence, checklist richness, effort, date, location, and observer strata;
3. detection-first JSDM/GLLVM with species-specific herring and nuisance effects;
4. abundance JSDM for a reduced well-supported species set;
5. phase- and distance-specific residual association matrices;
6. network density, modularity, centrality, and guild mixing;
7. leave-event/year/region-out network stability;
8. guild richness, Hill diversity, total count, and composition models;
9. privacy-safe local comment/behaviour keyword audits as supporting evidence only.

Do not recreate the failed Version 1 rank-one event/observer/location structure.

Use multiple latent factors or another validated covariance architecture. Require a hash-identical pilot before a full multispecies fit. Compare against no-pooling and species-specific benchmarks.

Do not interpret residual association as proof of direct interaction, facilitation, or shared travel. It may reflect omitted habitat, common response, observation process, or scale.

Do not use contemporaneous “other bird count” as an ordinary covariate in primary species models.

## 14. Metadata-first execution order

Implement only through the outcome-blind design gate in this task:

1. repository inventory and privacy scan;
2. resolve/pin Version 1 source SHA;
3. create port manifest and port allowed generic assets;
4. reconcile package dependencies and `renv`;
5. reconcile canonical registries;
6. validate local raw input paths and checksums;
7. inspect exact EBD/SED/herring/shapefile headers and field types;
8. validate EBD/SED pairing and checklist-key cardinality;
9. validate shapefile bundles and CRSs;
10. profile source-level metadata without focal bird outcomes;
11. create aggregate metadata QA tables;
12. construct a `targets` graph through metadata/design support only;
13. render `reports/repository_setup_audit.html`;
14. run tests and privacy scans;
15. stop for human approval.

Do not fit the core model registry during this task.

## 15. Required tests and CI

Create or update GitHub Actions to run without restricted raw data using fixtures.

Required fixture-based tests:

- config and environment path validation;
- input-manifest and SHA-256 logic;
- complete shapefile-bundle checksum logic;
- header encoding/delimiter/field mapping;
- EBD-to-SED many-to-one key checks;
- shared-checklist collapse and count disagreement audit;
- zero-fill detection/count-state preservation;
- taxonomy crosswalk uniqueness and ambiguity rules;
- guild lower/upper-bound logic;
- herring source-field preservation;
- event-quality tiers and event-complex construction;
- CRS transformations and kilometre units;
- distance-ring boundary rules;
- multi-event membership without row-independent assumptions;
- registry foreign-key integrity;
- synthetic-figure labels;
- privacy denylist and machine-specific path scan.

CI must fail if tracked files contain row-level restricted eBird values, recognizable checklist-ID values, source observer/locality-ID values, exact checklist coordinate pairs, or raw comments. Schema labels such as `sampling_event_identifier` are allowed in code and documentation; the scanner must distinguish field names from data values.

## 16. Comprehensive analysis plan report

Preserve and validate:

```text
reports/comprehensive_analysis_plan.html
scripts/build_comprehensive_analysis_plan.py
metadata/analysis_module_registry.csv
```

Requirements:

- self-contained HTML;
- every example figure visibly labelled illustrative/synthetic;
- lay and technical views;
- filterable model/species/module tables;
- current registry counts generated rather than hard-coded;
- no raw or row-level restricted data;
- report source hash recorded;
- render test in CI;
- add a Quarto source later only if it can reproduce the same content without requiring raw data.

Do not replace the plan with a shorter generic README.

## 17. Privacy scan before first push

Before staging and again before pushing, scan the complete working tree and Git index for restricted **values**, not merely schema labels:

- checklist-ID values matching patterns such as `S[0-9]+`;
- source observer/locality-ID values and source locality names;
- latitude/longitude column pairs or high-precision coordinate sequences;
- source checklist/species comments;
- local usernames and absolute Windows/macOS/Linux paths;
- EBD/SED/raw filenames outside approved manifest/config templates;
- secrets, tokens, `.Renviron`, and credentials;
- model objects, large files, and embedded restricted tables in HTML.

Write aggregate scan evidence to:

```text
outputs/setup/privacy_scan_summary.json
```

Do not persist the sensitive matching text in a tracked scan report.

## 18. Commit and publication sequence

Use small, reviewable commits. Recommended sequence:

1. `Initialize clean Version 2 repository scaffold`
2. `Record Version 1 source provenance and asset-port rules`
3. `Port and generalize reusable ingestion and QA utilities`
4. `Reconcile taxonomy, guild, estimand, and model registries`
5. `Add metadata audit pipeline and fixture tests`
6. `Add comprehensive analysis plan and reader report`
7. `Add CI and privacy gates`

Before the first push:

```bash
git status --short
git ls-files
# run test suite
# run privacy scan
# inspect staged diff
git diff --cached --stat
git diff --cached
```

Push only after all critical setup gates pass.

Optionally tag the approved setup state:

```text
v0.1.0-metadata-scaffold
```

Do not tag if the metadata or privacy gate remains open.

## 19. Stop conditions

Stop and request human review if any of these occur:

- source repository SHA cannot be resolved;
- destination repository ownership/visibility is wrong;
- a source asset contains restricted rows or identifiers;
- a ported function silently embeds Version 1’s five-species, 5 km, or 2015–2025 assumptions;
- local raw file checksum differs from the recorded expected source;
- EBD and SED releases do not match;
- header/encoding/schema differs materially;
- a shapefile bundle is incomplete or CRS is missing;
- registry reconciliation is scientifically ambiguous;
- privacy scan fails;
- a join changes cardinality unexpectedly;
- a required test cannot be made fixture-based;
- setup would require opening focal bird outcomes;
- the only reason for a design change is a favorable prior result.

Do not guess through a stop condition.

## 20. Acceptance criteria

The task is complete only when all of the following are true:

- [ ] New private GitHub repository exists with clean history.
- [ ] Version 1 source `main` SHA is resolved and pinned.
- [ ] No Version 1 Git objects or restricted history were imported.
- [ ] Every evaluated source asset has a manifest row.
- [ ] Only allowlisted reusable assets were ported.
- [ ] One canonical species registry exists.
- [ ] One canonical guild registry exists.
- [ ] Estimand, model, and module registries are distinct and cross-referenced.
- [ ] Co-occurrence and mixed-species analyses are explicitly registered.
- [ ] Raw input paths are environment-driven.
- [ ] Expected input checksums and source versions are recorded.
- [ ] Shapefile bundles are validated correctly.
- [ ] Metadata audit runs without reading focal outcomes.
- [ ] `targets` graph runs through the metadata/design gate.
- [ ] Fixture tests pass locally and in CI.
- [ ] Privacy and machine-path scans pass.
- [ ] Comprehensive plan HTML renders and all examples are labelled synthetic.
- [ ] No Version 2 bird-response model was fitted or inspected.
- [ ] Setup report documents every unresolved scientific decision.

## 21. Final Codex response format

Return a structured completion report containing:

1. destination repository URL;
2. visibility and default branch;
3. final commit SHA and tag, if any;
4. pinned Version 1 source SHA;
5. files added, ported, generalized, rejected, and reference-only;
6. registry reconciliation counts;
7. test results;
8. CI status;
9. input checksum/header/schema status;
10. privacy scan status;
11. comprehensive HTML render status and path;
12. unresolved metadata/scientific decisions;
13. exact manual actions required next;
14. explicit confirmation that no Version 2 focal bird-response outcome was opened or fitted.

Do not summarize a failed gate as a pass. Do not claim the new repository exists until the remote can be verified.
