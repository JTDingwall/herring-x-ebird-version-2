# Herring x eBird Version 2

This is a clean-history, metadata-first R project for designing tests of how Pacific herring spawning relates to coastal bird occurrence, reported counts, spatial allocation, community composition, and co-occurrence in British Columbia.

Stage 3 Phases 1-3 are complete and human-approved. Stage 4A was executed under its
recorded authorization on PR #2 and its aggregate results are pending human scientific
review. A post-result audit found defective hierarchical pooling columns and
nonconforming diagnostic/sensitivity paths; it did not alter or rerun Stage 4A v1.
Stage 4B is not automatically authorized. M31 and all 2026-2028 responses remain locked.
Current development analyses are exploratory and estimand-refining until prospective
confirmation.

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

## Current authority and review gate

Human scientific authorization records immutable source point as the only registered analysis geometry. EDGE_TYPE 100, EDGE_TYPE 150, derived alongshore lengths, and shoreline unions are retained as audit provenance only; no shoreline-class or alongshore sensitivity is registered. The incomplete shoreline bundle remains documented but has no analysis role. The original 105-option candidate grid and retained hashes remain unchanged.

- `docs/09_STAGE2_OUTCOME_BLIND_DESIGN_LOCK.md`: frozen Stage 2 design-lock report.
- `docs/10_EBIRD_CHECKLIST_METHODS_REVIEW.md`: checklist-level methods and literature addendum.
- `docs/11_STAGE3_ENTRY_PLAN.md`: phased approval, QA, validation, and response-access plan.
- `metadata/ebird_checklist_handling_gate.csv`: machine-readable aligned, verify, decision, and blocking items.
- `metadata/stage2_human_scientific_approval_v1.yml`: hashed Stage 2 human scientific approval record.
- `metadata/stage3_phases1_3_authorization_v1.yml`: hashed authorization for Stage 3 Phases 1–3 only.
- `metadata/stage3_entry_plan.yml`: machine-readable authorized actions, hard stops, and phase order.
- `reports/ebird_checklist_methods_audit.html`: interactive checklist-methods review.
- `reports/herring_ebird_broad_literature_survey.html` and `metadata/herring_ebird_literature_matrix.csv`: expanded 54-source evidence map.

Stage 3 Phases 1-3 are complete. Stage 4A authorization, final scope lock, execution
record, technical methods, and privacy-safe aggregate results are preserved on the Stage
4A branch. The reconciliation audit is explicitly post-result and does not backdate any
new rule.

- `docs/POST_STAGE4A_ADVERSARIAL_AUDIT.md`: code-path, conformance, numerical,
  interpretation, and defect-impact audit.
- `docs/STAGE4A_HUMAN_REVIEW_PACKET.md`: non-promotional decisions now required.
- `docs/PROJECT_CONTINUATION_AUDIT_AND_PLAN.md`: estimand/model-specific critical path.
- `metadata/post_stage4a_review_issue_crosswalk.csv`: disposition of PR #3 R1-R31.
- `metadata/prospective_confirmation_amendment_draft.yml`: unsigned post-result draft;
  it is not authoritative.

PR #3 is a sibling-branch advisory review. It does not supersede human approvals or
hashed Stage 4A records and is not merged wholesale. Future work follows the
model-specific and estimand-specific gate tables rather than a blanket “all S2 blocks
all response models” rule. Any protected 2005-2025 rerun requires new human
authorization and versioned outputs. The complete 2026-2028 holdout remains inaccessible.

## Reports and provenance

- `reports/comprehensive_analysis_plan.html` is the self-contained scientific blueprint with 18 explicitly synthetic example figures and paired lay/technical views.
- `docs/comprehensive_analysis_plan.html` is its reader copy.
- `reports/repository_setup_audit.html` records construction readiness.
- `metadata/v1_source_commit.json` pins the Version 1 source commit.
- `metadata/v1_asset_port_manifest.csv` records every considered allowlisted asset as copied, generalized, reference-only, or rejected.

Version 2 is not a branch or fork of Version 1. No Version 1 Git history, raw data, record-level derivative, fitted object, coefficient, weight, or outcome-dependent output is imported.
