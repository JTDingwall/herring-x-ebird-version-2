# Codex Stage 2 Prompt — Outcome-Blind Support Audit and Scientific Design Lock

## Repository

Work only in the private repository:

`JTDingwall/herring-x-ebird-version-2`

Baseline commit for this stage:

`fd1473bbd473c76692e1cd676d68a208dfe45b6b`

Create and work on a branch named:

`design/stage2-outcome-blind-lock`

Do not modify or rerun `JTDingwall/ebird_herring_analysis`.

Read `AGENTS.md`, `README.md`, `docs/04_DECISION_RULES.md`,
`docs/08_UNRESOLVED_SCIENTIFIC_DECISIONS.md`, all canonical registries, the
repository reconciliation report, and the comprehensive analysis plan before
writing code.

## Purpose

Resolve the ten open scientific design decisions without estimating,
displaying, ranking, or selecting any herring–bird response effect.

This is an **outcome-blind design and support stage**, not a biological-results
stage. It may inspect taxonomy, count state, and support counts under the strict
rules below, but it must not estimate whether birds increase or decrease near
spawn.

The output is a reviewable scientific design-lock packet. Stop at a new human
approval gate. Do not fit any of the 45 registered response models.

## Existing facts that must remain true

- Version 2 has a clean history and does not import Version 1 Git history.
- Raw EBD/SED, identifiers, exact checklist coordinates, comments, record-level
  derivatives, fitted objects, coefficients, and weights remain untracked.
- The five protected inputs are accessed only through the established
  environment variables.
- Detection, numeric count, `X`, lower-bound count, ambiguity, and missingness
  remain distinct.
- Missing herring components remain missing and are never converted to zero.
- The herring relative spawn index is not described as absolute biomass.
- All concurrent events remain available for additive-exposure construction.
- A duplicated checklist–event row is never treated as an independent bird
  observation.
- All design choices are made without consulting an estimated herring effect,
  its sign, p-value, posterior probability, or apparent biological appeal.

## Strict outcome-access boundary

### Allowed before the candidate design grid is frozen

- Full SED effort, protocol, observer, locality, date, and coordinate metadata.
- Herring dates, coordinates, Length, Width, Method, Region, Section,
  LocationCode, SpawnNumber, and component missingness.
- Shoreline and section geometry.
- EBD header, checklist key, taxon concept, taxonomy fields, observation date,
  and raw count-state parsing logic.
- Aggregate checklist coverage and herring-event coverage.
- Synthetic data and simulated outcomes.

### Candidate-grid freeze

Before reading any species detection or numeric count values, write and hash:

- `metadata/stage2_candidate_design_grid.csv`
- `metadata/stage2_candidate_design_grid.sha256`
- `metadata/stage2_support_rules.yml`

The grid must enumerate every candidate:

- temporal window;
- distance ring or continuous-distance range;
- event-complex definition;
- geometry definition;
- region and period;
- protocol and effort filter;
- species/guild eligibility rule;
- count-state rule;
- co-occurrence eligibility rule.

After this hash is written, it must not be changed in response to species
support patterns. Any later correction must be documented as a schema or
implementation correction, with old and new hashes retained.

### Allowed support-only outcome access after the freeze

For each registered taxon and candidate design cell, Codex may compute only:

- number of eligible checklists;
- number of detections;
- number of positive numeric counts;
- number of `X` reports;
- number of lower-bound or ambiguity-affected outcomes;
- number of represented events, event complexes, years, regions, locations,
  and observers;
- maximum share contributed by one event, location, or observer;
- count quantiles pooled across exposure cells, or by taxon/region/year, for
  likelihood-support diagnostics;
- pairwise prevalence needed to assess whether a species can enter a
  co-occurrence model.

Do **not** compute, display, or persist:

- detection rates by spawn phase, distance, exposure, or intensity;
- mean, median, quantile, or total bird counts by spawn phase, distance,
  exposure, or intensity;
- active-minus-reference differences;
- ratios, odds ratios, effect sizes, coefficients, p-values, confidence
  intervals, posterior summaries, or response plots;
- pairwise co-occurrence differences by spawn phase or distance;
- any model that contains a herring exposure term;
- any ranking of species, guilds, radii, windows, event definitions, or models
  by a biological response.

Support tables must use counts only and carry the label
`SUPPORT_ONLY_NOT_AN_EFFECT_ESTIMATE`.

Write a machine-readable audit listing every raw or derived response column read
during this stage and every prohibited statistic checked.

## Resolve the ten open decisions

### 1. Species approval and support classes

Retain all 58 registry rows. Do not delete a taxon because it is sparse.

Reconcile official eBird Taxonomy v2025 concept IDs for:

- the two legacy exclusions requiring reassessment; and
- the 11 new candidates.

Create three outcome-blind eligibility levels:

#### Named-species core eligibility

Candidate default thresholds:

- at least 200 detections in the frozen event-linked support frame;
- detections across at least 50 independent herring events or approved event
  complexes;
- detections in at least 8 years;
- detections in at least 2 stock-assessment regions or a clearly labelled
  region-specific model;
- at least 50 detections in each of two primary event periods;
- no single event, observer, or exact analysis location contributes more than
  20% of detections;
- for a positive-count component, at least 100 positive numeric reports across
  at least 40 events and at least 80% numeric availability among detections.

#### Named-species exploratory eligibility

Candidate default thresholds:

- at least 75 detections;
- at least 25 events or event complexes;
- at least 5 years;
- at least 20 detections in each of two event periods;
- no single event contributes more than 30%.

#### Guild/community-only eligibility

Candidate default thresholds:

- at least 25 detections;
- at least 10 events;
- at least 3 years;
- valid taxonomy and unambiguous guild allocation.

These are candidate defaults. Report the consequences of nearby thresholds,
but do not choose thresholds based on effect direction. A sparse named species
may remain in a guild or community model through partial pooling when the guild
is supported.

Keep Gadwall and Northern Shoveler in a separate falsification panel. Do not
use them as exchangeable controls or in a triple difference unless a separate
habitat and detectability audit later justifies that assumption.

Produce:

- a taxonomy reconciliation table;
- support-only species tables;
- a recommended status for named-species, guild, community, count, and
  co-occurrence analyses;
- explicit reasons for every recommendation.

### 2. Multi-guild membership

Use one **non-overlapping primary guild** per species for guild totals and
primary guild contrasts, preventing duplicate counting of the same bird.

Add zero or more secondary mechanism/trait flags for cross-species synthesis,
for example:

- attached-roe diver;
- surface/intertidal roe feeder;
- adult-herring piscivore;
- shoreline scavenger;
- wide-ranging raptor;
- migration-confounded;
- mixed-flock-prone;
- count-heaping-prone.

A species may inform several trait analyses, but it must not be counted twice
in a primary total-bird or guild-abundance response.

Create:

- `metadata/species_primary_guild.csv`;
- `metadata/species_mechanism_traits.csv`;
- a duplicate-counting QA test.

### 3. Event-complex definition

Preserve the immutable source-record event identity.

Construct and audit four analytical identities:

1. source record;
2. 1 km / 3 day complex;
3. 2 km / 7 day complex;
4. 5 km / 14 day complex.

Treat 2 km / 7 days as the **candidate primary complex**, not as approved by
default.

For each rule, report without bird outcomes:

- number and size distribution of complexes;
- number of source records per complex;
- spatial span and temporal span;
- crossing of Region, StatisticalArea, Section, LocationCode, or Method;
- component completeness and method composition;
- overlap with other complexes;
- sensitivity to reversed or uncertain dates;
- 100 stratified map-review cases, including the largest and most dispersed
  complexes.

Recommended acceptance logic for the candidate primary:

- never merge across stock-assessment Region;
- flag rather than silently merge across StatisticalArea;
- no accepted complex may span more than 21 calendar days without manual
  review;
- no accepted complex may have an unexplained spatial diameter greater than
  25 km;
- retain every source record and crosswalk;
- preserve all alternative complex IDs for sensitivity models.

If 2 km / 7 days fails materially, recommend source-record or 1 km / 3 day as
primary. The 5 km / 14 day definition remains a broad sensitivity unless the
metadata show clear source fragmentation.

### 4. Event geometry and quality tiers

Build and audit, without bird outcomes, these geometry families:

1. authoritative source point;
2. distance to the nearest approved marine shoreline point;
3. derived alongshore footprint using source Length where available;
4. derived alongshore-plus-Width footprint as a labelled sensitivity;
5. event-complex union of the corresponding member geometries.

Do not treat a section polygon or centroid as an event footprint.

For a derived alongshore footprint:

- transform to EPSG:3005;
- snap only to an approved marine shoreline class;
- retain source and snapped coordinates;
- report snap distance;
- construct an alongshore segment centred on the snapped point with source
  Length;
- do not silently bridge disconnected islands or coastlines;
- retain construction failures and reasons;
- do not infer Length or Width when missing.

Define geometry quality tiers using only metadata, for example:

- Tier A: valid date, coordinate, Method, shoreline snap within a prespecified
  distance, observed Length, and no major construction ambiguity;
- Tier B: valid date and point with acceptable snap but missing extent;
- Tier C: usable section/date metadata but uncertain point or method;
- excluded only for an impossible or unlocatable exposure definition.

Recommend one geometry for each estimand rather than forcing one geometry on
all models. At minimum, keep source-point and derived-footprint design families
as parallel core/sensitivity analyses.

Produce map-review HTML with no exact eBird checklist coordinates.

### 5. Regions, periods, protocols, and effort

Use all British Columbia as the coverage universe, but do not force one pooled
coastwide effect.

Audit candidate start years 2005, 2010, and 2015, with 1988–2025 retained as a
long-window sensitivity. Select the earliest primary start year that passes
prespecified, response-free coverage criteria for each intended region or
hierarchical region group.

Report by Region, year, month, protocol, and shoreline support:

- complete checklist counts;
- unique observers and localities;
- event and event-complex counts;
- overlap of event periods and distance rings;
- effort distributions;
- concentration of sampling;
- exact-location repeat support;
- same-observer cross-period support.

Candidate protocol/effort definitions:

#### Broad primary candidate

- complete Stationary and Traveling checklists;
- duration 1–360 minutes;
- Traveling distance at most 10 km;
- 1–20 observers;
- valid start time retained when available but not required solely for
  inclusion;
- effort modeled flexibly and protocol interactions permitted.

#### Standardized sensitivity

- duration 5–300 minutes;
- Traveling distance at most 5 km;
- 1–10 observers.

Evaluate any interpretable complete area protocol separately; never pool it
silently with Stationary or Traveling.

Recommend region-specific exclusion only when exposure or checklist support is
structurally absent. Sparse years or regions may remain in hierarchical or
descriptive outputs without being forced into every species model.

### 6. Count tails and likelihood family

Do not fit a herring-effect count model.

Use empirical count-state summaries pooled independently of herring exposure,
plus synthetic simulations calibrated only to overall marginal properties, to
compare candidate likelihood behaviour:

- hurdle lognormal;
- hurdle truncated negative binomial 2;
- hurdle generalized Poisson where supported;
- zero-inclusive negative binomial;
- Tweedie;
- ordinal flock-size categories;
- upper-tail exceedance or quantile model.

Predefine the selection algorithm:

- detection component always remains separate;
- choose the positive-count family using simulation recovery, leave-block-out
  predictive log score, calibration, residual tail behaviour, and numerical
  stability;
- apply a one-standard-error preference for the simpler adequate family;
- never select by the sign, significance, or magnitude of a herring term.

Primary recommendations to evaluate:

- no winsorization or deletion of high counts in the primary model;
- lognormal or truncated NB2 for positive counts;
- top-1%, top-0.5%, ordinal, and upper-tail analyses as sensitivities;
- `X` contributes to detection but not invented numeric abundance;
- lower-bound records enter an interval/bounded sensitivity;
- ambiguous taxonomy contributes only under registered guild-bound rules.

Create a synthetic simulation report and a count-family decision table.

### 7. Multispecies latent factors

Do not fit the biological JSDM/GLLVM in this stage.

Freeze the future selection procedure:

- detection-first community model;
- candidate latent-factor counts 2, 3, 4, and 5;
- species-specific herring effects;
- species-specific observation-process coefficients where support allows;
- event, observer, location, region, year, and latent community structure must
  not be constrained to the failed Version 1 rank-one form;
- select factor count by heldout predictive score, posterior geometry or
  convergence, residual association recovery in simulation, and a
  one-standard-error rule;
- use a hash-identical pilot before any full fit;
- require a no-latent-factor and no-pooling comparator;
- abundance JSDM uses a reduced species set determined only by the frozen
  support thresholds.

Create design simulations that demonstrate identifiability under the actual
crossing pattern, but do not use observed herring-response effects.

### 8. Behaviour and comment audits

Approve structured eBird behaviour codes for a privacy-safe aggregate
supporting analysis when field completeness is adequate.

Treat free-text comments as optional and restricted:

- local-only processing;
- a versioned, prespecified keyword dictionary;
- no excerpts or comments in tracked files;
- no exact checklist identifiers or coordinates;
- aggregate counts only;
- minimum released cell size 20;
- privacy scan must test rare strings and path leakage;
- supporting evidence only, never a primary response.

If these conditions cannot be guaranteed, defer the comment audit without
blocking the main analysis.

### 9. Multiplicity and evidence synthesis

Separate model roles before fitting:

#### Primary ecological families

1. Local numerical aggregation — primary candidate `M01` guild hurdle model,
   with `M02` species hurdle models as visible supporting estimates.
2. Event-time and distance response — primary candidate `M05`, supported by
   `M06`, `M17`, and `M38`.
3. Redistribution and mass balance — primary candidate `M08`, supported by
   `M07`, `M09`, and `M10`.
4. Community and conditional co-occurrence — primary candidate `M35` or `M21`
   after the latent-factor pilot, supported by `M34`, `M36`, `M37`, and `M22`.
5. Spawn dose and phenology — primary candidates `M18` and `M23`, reported as
   separate mechanisms rather than pooled into one test.

#### Diagnostics and falsification

`M26`–`M29`, `M32`, `M40`, and `M42` are diagnostics or falsification analyses
and do not compete with primary ecological models for selection.

#### Sensitivity and generalization

Geometry, event-complex, tail, region, period, and holdout models are reported
as prespecified sensitivities or validation, not as opportunities to select a
preferred sign.

Use:

- hierarchical partial pooling for guild/mechanism synthesis;
- species estimates always visible;
- Benjamini–Hochberg FDR within coherent species families;
- no single omnibus Holm correction over all 45 models;
- no averaging of incompatible estimands;
- an evidence matrix using the categories in `docs/04_DECISION_RULES.md`.

Create a machine-readable hypothesis-to-model-to-multiplicity registry.

### 10. Prospective confirmation

Freeze all 2026 and later bird outcomes and herring events from model
development.

The 2026 release is incomplete and must not be used as a confirmatory test yet.
Define a prospective protocol that requires:

- a complete or explicitly frozen eBird release;
- finalized or versioned herring records for the same period;
- unchanged model code, species list, guild definitions, geometry, event-time
  windows, distance functions, and decision thresholds;
- no refitting or model selection using the prospective outcomes before the
  primary evaluation;
- a signed/hash-recorded confirmation specification.

Also identify candidate external regions for an independently frozen
generalization test, but do not select one based on response direction.

## Co-occurrence and mixed-species requirements

The support audit must explicitly prepare for species travelling or feeding
together.

For each candidate community set, report support-only quantities:

- species prevalence and positive-count availability;
- number of checklists and events shared by each pair;
- pairwise cell counts, but not exposure-specific association contrasts;
- checklist richness distribution;
- observer/location/event concentration;
- feasibility of null permutations preserving prevalence, richness, effort,
  date, location, and observer strata.

Do not use contemporaneous “other bird count” as a routine adjustment
covariate in primary herring-effect models. It is a potential mediator and
another outcome. Joint models and prespecified community summaries are the
primary approach.

## Required artifacts

Create:

- `docs/09_STAGE2_OUTCOME_BLIND_DESIGN_LOCK.md`
- `reports/stage2_outcome_blind_design_lock.html`
- `metadata/stage2_candidate_design_grid.csv`
- `metadata/stage2_candidate_design_grid.sha256`
- `metadata/stage2_support_rules.yml`
- `metadata/species_primary_guild.csv`
- `metadata/species_mechanism_traits.csv`
- `metadata/hypothesis_model_multiplicity_registry.csv`
- `outputs/stage2_design_lock/species_taxonomy_reconciliation.csv`
- `outputs/stage2_design_lock/species_support_summary.csv`
- `outputs/stage2_design_lock/species_support_by_design_cell.csv`
- `outputs/stage2_design_lock/event_complex_audit.csv`
- `outputs/stage2_design_lock/event_geometry_audit.csv`
- `outputs/stage2_design_lock/region_period_effort_support.csv`
- `outputs/stage2_design_lock/count_family_simulation_summary.csv`
- `outputs/stage2_design_lock/cooccurrence_support_summary.csv`
- `outputs/stage2_design_lock/response_column_access_audit.csv`
- `outputs/stage2_design_lock/decision_recommendations.csv`
- `outputs/stage2_design_lock/stage_gate.json`
- fixture tests and privacy-scan extensions for every new artifact.

The HTML must include lay summaries beside technical sections and must label
all simulated figures as synthetic. It must not contain biological response
figures or effect estimates.

## QA and acceptance criteria

The stage passes only when:

- the candidate design grid was hashed before support-only outcome access;
- raw inputs and restricted identifiers remain untracked;
- all joins have tested cardinality;
- no exact checklist coordinates, observer IDs, locality IDs, comments, or
  machine-specific paths occur in tracked output;
- every candidate species has a taxonomy/support disposition;
- event-complex and geometry alternatives have complete source crosswalks;
- the primary and sensitivity roles of all candidate designs are explicit;
- count-family decisions are based on simulation and predictive adequacy, not
  herring effects;
- latent-factor selection is procedural and not outcome-effect-selected;
- multiplicity families are frozen;
- the prospective holdout protocol is hash-recorded;
- all tests and CI pass;
- no prohibited response summary or fitted herring-effect model exists.

Set the final stage gate to one of:

- `PASS_READY_FOR_HUMAN_SCIENTIFIC_APPROVAL`
- `STOP_METADATA_OR_PRIVACY_FAILURE`
- `STOP_DESIGN_IDENTIFICATION_FAILURE`

Do not set any model registry status to fitted.

## Commit, pull request, and return report

Commit the stage on `design/stage2-outcome-blind-lock`, push it, and open a pull
request into `main`. Do not merge it.

Return:

1. branch name, commit SHA, and pull-request URL;
2. candidate-grid hash and timestamp;
3. exact response columns read;
4. explicit confirmation that no detection rates, count means by exposure,
   contrasts, coefficients, p-values, intervals, or biological response plots
   were computed;
5. taxonomy and support disposition for all 58 taxa;
6. recommended primary and sensitivity event-complex/geometry definitions;
7. recommended regions, periods, protocols, and effort filters;
8. count-family simulation recommendation;
9. latent-factor selection procedure;
10. behaviour/comment privacy recommendation;
11. multiplicity and evidence-synthesis registry;
12. prospective holdout specification;
13. test, CI, and privacy-scan results;
14. unresolved questions requiring human approval;
15. final stage-gate classification.

Stop after the pull request and wait for human scientific review. Do not open
or fit any Version 2 herring–bird response model.
