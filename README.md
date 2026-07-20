# Herring × eBird Version 2

A metadata-first, multi-model R project for testing whether Pacific herring spawning
changes the **number, occurrence, composition, and spatial allocation of coastal birds**
in British Columbia.

Repository slug: `herring-x-ebird-version-2`

## Why restart

Version 1 established a careful, reproducible foundation, but its main estimand was
narrow: checklist encounter probability during days 0–14 after a recorded spawn start
versus days −14 to −1 at the same event, within 5 km, for five species. That design did
not directly test flock size, total birds, complete event trajectories, coastwide
responses, or redistribution.

The strongest reason for Version 2 is already visible in the Version 1 diagnostics:
conditional positive reported-count models were positive for all five focal species and
remained similar after excluding the largest 1% of counts. Version 2 therefore makes
**reported count and spatial allocation co-primary with encounter probability**, while
retaining observation-process controls and transparent uncertainty.

Version 2 is a new analysis, not a rerun of the old model. It starts from the authoritative
raw EBD, SED, herring table, shoreline, and section layers. It must not import Version 1
derived outcomes, fitted models, weights, or selected coefficients.

## Main biological hypotheses

1. **Local aggregation:** herring-associated birds have higher reported counts close to
   active spawn and egg-bearing shoreline.
2. **Guild response:** roe-diving sea ducks, gulls, intertidal roe foragers, piscivores,
   and shoreline scavengers show different timing and distance responses.
3. **Distance decay:** response magnitude declines from the spawn footprint through
   1, 2, 3, 4, 5, 10, and 20 km.
4. **Redistribution:** increases close to spawn are accompanied by reduced allocation
   of the same birds to simultaneous comparison shorelines.
5. **Dose response:** larger or more extensive spawn records produce stronger bird
   responses, after accounting for survey method and component completeness.
6. **Community reorganization:** total herring-associated bird count, guild richness,
   and community composition change around spawning.
7. **Phenological tracking:** mobile taxa track the northward and seasonal progression
   of spawn events.
8. **Observation process:** birder visitation can change around spawn and must be
   estimated separately from bird response.

These hypotheses are directional, but all models report full effect sizes and uncertainty.
Null and opposite-direction results remain part of the analysis.

## Data sources

The expected source versions are recorded in `metadata/source_inventory.csv`.

- eBird Basic Dataset, British Columbia, release May 2026
- matching eBird Sampling Event Data
- DFO Pacific Herring Spawn Index Data, 2025 CSV
- BC Freshwater Atlas coastline layer
- DFO herring sections layer

Raw eBird data are restricted and are never committed. Configure local paths through
environment variables; see `.Renviron.example`.

## What is different in Version 2

- all supportable BC herring regions, with Strait of Georgia reported as a high-support
  regional subset;
- 45 legacy curated taxa plus additional candidate species and guild-level ambiguous taxa;
- reported counts, encounter probability, total guild count, richness, composition, and
  spatial allocation;
- multiple temporal periods and continuous event-time trajectories;
- concentric distance rings and continuous distance-decay kernels;
- event complexes and spawn-footprint uncertainty instead of only one source point per row;
- tiered herring-record quality rather than excluding every record with any metadata issue;
- explicit modeling of birder visitation and observer turnover;
- multiple complementary models registered before fitting, with hierarchical synthesis
  rather than declaring success from whichever model is significant.


## Comprehensive Version 2 blueprint

- [`reports/comprehensive_analysis_plan.html`](reports/comprehensive_analysis_plan.html): self-contained reader report with 18 synthetic example figures, filterable tables, technical specifications, and lay summaries.
- [`docs/07_COMPREHENSIVE_ANALYSIS_PLAN.md`](docs/07_COMPREHENSIVE_ANALYSIS_PLAN.md): concise repository index for the HTML plan.
- [`metadata/analysis_module_registry.csv`](metadata/analysis_module_registry.csv): 50 estimand-oriented modules spanning data audit, counts, timing, distance, redistribution, community, co-occurrence, herring measurement, phenology, observation process, validation, and synthesis.
- [`prompts/02_CODEX_BUILD_REPO_AND_PORT_V1_ASSETS.md`](prompts/02_CODEX_BUILD_REPO_AND_PORT_V1_ASSETS.md): clean-repository build and allowlisted Version 1 asset-port prompt.

Every figure in the HTML is explicitly labelled illustrative/synthetic and is not a Version 2 result.

## Initial repository status

Completed in the initial commit:

- source metadata and field audit;
- a source-repository evidence ledger pinned to the audited Version 1 commit;
- expanded species and guild registries;
- a 33-model analysis registry;
- data contracts and scientific hypotheses;
- executable R code for input/header auditing and registry validation;
- privacy and reproducibility rules.

No Version 2 bird-response model has been fitted in this repository yet.

## Start

```r
file.copy(".Renviron.example", ".Renviron")
# Edit .Renviron to point to the five existing raw inputs.

source("scripts/00_setup.R")
source("scripts/01_audit_inputs.R")
source("scripts/02_validate_registries.R")
targets::tar_make()
```

## Key documents

- `docs/00_METADATA_AUDIT.md`
- `docs/01_SCIENTIFIC_HYPOTHESES.md`
- `docs/02_MULTI_MODEL_ANALYSIS.md`
- `docs/03_DATA_CONTRACTS.md`
- `docs/04_DECISION_LOG.md`
- `docs/05_OLD_TO_V2_CROSSWALK.md`
- `docs/06_IMPLEMENTATION_ROADMAP.md`
- `docs/07_COMPREHENSIVE_ANALYSIS_PLAN.md`
- `reports/comprehensive_analysis_plan.html`
- `prompts/00_CODEX_MASTER_PROMPT.md`
- `prompts/02_CODEX_BUILD_REPO_AND_PORT_V1_ASSETS.md`
- `docs/07_GITHUB_PUBLISHING.md`

## Interpretation boundaries

- eBird counts are **reported counts or relative count indices**, not absolute population
  abundance.
- “No recorded active spawn nearby” is not verified absence of spawn.
- the DFO component sum is a relative spawn index, not literal measured biomass.
- event date, event geometry, survey method, observer behavior, and checklist effort are
  observation/measurement processes that must remain visible.
- Version 2 is post-result exploratory because Version 1 outcomes have already been seen.
  Prospective confirmation requires later years, a frozen external region, or structured
  shoreline surveys.
