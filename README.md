# Herring x eBird Version 2

This is a clean-history, metadata-first R project for designing tests of how Pacific herring spawning relates to coastal bird occurrence, reported counts, spatial allocation, community composition, and co-occurrence in British Columbia.

The current gate is **repository construction and outcome-blind design readiness**. No Version 2 bird-response outcome may be opened or modeled at this stage. Current analyses are exploratory and estimand-refining until prospective confirmation.

## Canonical design assets

- `metadata/canonical_species_registry.csv`: 58 auditable taxon rows with explicit support and approval states.
- `metadata/canonical_guild_registry.csv`: 8 biological or falsification guilds.
- `metadata/estimand_registry.csv`: 15 approved design estimands.
- `metadata/model_registry.csv`: 45 prespecified models, all registered and not fitted.
- `metadata/cooccurrence_registry.csv`: 9 prespecified multispecies architectures.
- `metadata/analysis_module_registry.csv`: 50 descriptive, diagnostic, inferential, validation, and synthesis modules.
- `metadata/source_taxonomy_crosswalk.csv` and `metadata/ambiguous_taxon_rules.csv`: pinned eBird Taxonomy v2025 evidence.

Counts are validated by code and CI. Conflicting provisional registries from the initial scaffold have been removed.

## Protected local inputs

Raw EBD/SED files and all record-level derivatives are restricted and never committed. Configure only local environment variables using `.Renviron.example`:

- `HERRING_EBIRD_V2_EBD`
- `HERRING_EBIRD_V2_SED`
- `HERRING_EBIRD_V2_HERRING`
- `HERRING_EBIRD_V2_SHORELINE`
- `HERRING_EBIRD_V2_SECTIONS`

The tracked `metadata/input_manifest.csv` contains only provider/version metadata, sizes, and expected checksums. Local audit products are ignored because they may contain paths.

## Reproducible setup

```r
renv::restore()
source("scripts/02_validate_registries.R")
source("scripts/04_run_privacy_scan.R")
testthat::test_dir("tests/testthat")
targets::tar_make()
```

Run `scripts/01_validate_input_metadata.R` only in an authorized local session with the five protected environment variables configured. It reads source headers and metadata only; it does not inspect focal bird outcomes.

## Scientific guardrails

- Detection, numeric count, `X`, lower-bound count, ambiguity, and missingness remain distinct.
- Missing herring components are not zero; the relative spawn index is not absolute biomass.
- All concurrent event links contribute to additive exposure; duplicated event-checklist links are not independent rows.
- Every join declares and tests its cardinality.
- All prespecified models are reported regardless of sign.
- Hard stops and warnings follow `docs/04_DECISION_RULES.md`.

## Stage 2 scientific approval and Stage 3 entry

Stage 2 human scientific approval is recorded for immutable source points as the primary event geometry. EDGE_TYPE 100 alongshore geometry is limited to SoG and WCVI sensitivities; EDGE_TYPE 150 remains unavailable until local validation. The incomplete shoreline bundle remains documented and is not treated as coastwide. The original 105-option candidate grid and retained hashes remain unchanged.

- `docs/09_STAGE2_OUTCOME_BLIND_DESIGN_LOCK.md`: frozen Stage 2 design-lock report.
- `docs/10_EBIRD_CHECKLIST_METHODS_REVIEW.md`: checklist-level methods and literature addendum.
- `docs/11_STAGE3_ENTRY_PLAN.md`: phased approval, QA, validation, and response-access plan.
- `metadata/ebird_checklist_handling_gate.csv`: machine-readable aligned, verify, decision, and blocking items.
- `metadata/stage2_human_scientific_approval_v1.yml`: hashed human scientific approval record.
- `metadata/stage3_entry_plan.yml`: machine-readable approved choices, remaining implementation gates, and phase order.
- `reports/ebird_checklist_methods_audit.html`: interactive checklist-methods review.
- `reports/herring_ebird_broad_literature_survey.html` and `metadata/herring_ebird_literature_matrix.csv`: expanded 54-source evidence map.

Stage 2 approval does not authorize Stage 3 entry implementation or a response model. A separate authorization is required after the remaining checklist-construction and blocked-validation safeguards are implemented and verified. The 2026+ prospective holdout remains frozen.

## Reports and provenance

- `reports/comprehensive_analysis_plan.html` is the self-contained scientific blueprint with 18 explicitly synthetic example figures and paired lay/technical views.
- `docs/comprehensive_analysis_plan.html` is its reader copy.
- `reports/repository_setup_audit.html` records construction readiness.
- `metadata/v1_source_commit.json` pins the Version 1 source commit.
- `metadata/v1_asset_port_manifest.csv` records every considered allowlisted asset as copied, generalized, reference-only, or rejected.

Version 2 is not a branch or fork of Version 1. No Version 1 Git history, raw data, record-level derivative, fitted object, coefficient, weight, or outcome-dependent output is imported.
