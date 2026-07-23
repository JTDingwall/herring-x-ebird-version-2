# REPO_MAP — MER v7 pre-submission hardening

Phase 0 inventory and reproduction for the post-Stage 4A Strait of Georgia
event-study refinement. Paths are as discovered in the working tree, not
assumed.

## Authoritative artifact paths

| Role | Path |
|---|---|
| Frozen event-study specification | `metadata/post_stage4a_sog_event_study_spec_v1.yml` |
| Authorization record | `metadata/post_stage4a_sog_event_study_authorization_v1.yml` |
| Species-roles registry (11-panel + 2 comparators) | `metadata/post_stage4a_sog_event_study_species_roles_v1.csv` (13 rows) |
| Canonical species registry (taxonomy, guilds, support) | `metadata/canonical_species_registry.csv` (58 rows) |
| Model-fitting code (fits, contrasts, BH, release rules) | `R/post_stage4a_sog_event_study_v1.R` |
| Production entry point | `scripts/run_post_stage4a_sog_event_study_v1.R` / `.ps1` |
| Manuscript source | `manuscript/journal_submission/marine_environmental_research/source_v7/mer_manuscript_unblinded_v7.qmd` |
| Supplement source | `.../source_v7/mer_supplement_v7.qmd` |
| Highlights source | `.../source_v7/mer_highlights_v7.qmd` |
| Asset builder (tables + figures) | `scripts/build_mer_v7_event_study_assets.py` |
| Test harness | `tests/testthat.R`, `tests/testthat/test-post-stage4a-sog-event-study-v1.R` |
| Authoritative results (per-contrast effects) | `outputs/post_stage4a_sog_event_study_v1/effect_estimates_v1.csv` |
| Model diagnostics | `.../post_stage4a_sog_event_study_v1/model_diagnostics_v1.csv` |
| Joint-cell term support | `.../model_term_support_v1.csv` |
| Global period-by-zone support | `.../joint_exposure_support_v1.csv` |
| Execution record | `.../execution_record_v1.yml` |
| Output hash manifest | `.../output_hash_manifest_v1.csv` |

## Protected inputs (gitignored, present locally, hash-gated)

These are the model inputs, read only under the authorization gate. They are
excluded from version control by `.gitignore` (`data/derived/**`). All four are
physically present in this working tree, so the read-only Phase 1 diagnostics
that need record-level fields are runnable here.

| Input | Path | Rows | Key fields |
|---|---|---|---|
| Checklist frame / event metadata | `data/derived/stage4a_protected/stage4a_event_metadata.tsv.gz` | 239,935 | `analysis_event_token`, cluster tokens, `region`, `checklist_year`, `active_reference_class`, `protocol`, `duration_minutes`, `effort_distance_km`, `observer_count`, `concurrent_links`, `time_*` (5 event-relative period margins), `distance_ring_*` (8 rings), `high_precision_2km` |
| Source-point links (the link table) | `data/derived/stage3_phase2_protected/metadata_source_point_links.tsv.gz` | 1,559,674 | `analysis_event_token`, `herring_source_token`, `region`, `checklist_year`, `event_year`, `event_day`, `distance_km` |
| Reported states (per taxon per checklist) | `data/derived/stage4a_protected/stage4a_reported_states.tsv.gz` | 1,169,613 | `analysis_event_token`, `analysis_taxon_id`, `detection`, `numeric_count`, `lower_bound_count`, `count_type`, `ambiguity_flag`, `provenance` |
| Ambiguity masks | `data/derived/stage4a_protected/stage4a_ambiguity_masks.tsv.gz` | 5,835 | `analysis_event_token`, `analysis_taxon_id`, `provenance` |
| EBD membership / date gate | `data/derived/stage3_phase2_protected/ebd_event_membership_date_gate.tsv.gz` | 2,411,590 | `analysis_checklist_id`, `has_ebd_identity`, `date_disagreement` |

**Schema fact with direct bearing on Phase 1.** The checklist frame carries
`checklist_year` but **no calendar day-of-year and no checklist start time**.
The link table carries `event_day`, which is event-relative (days from spawn
onset), not a calendar date. No file in the working tree carries wall-clock
start time or day-of-year. Raw EBD (`data/raw/`) holds only a `README.md`.
Consequence: **D1 (calendar-date balance) and D2 (start-time balance) cannot be
computed from the frozen protected frame.** See `OPEN_QUESTIONS.md`.

## Where each computation lives in `R/post_stage4a_sog_event_study_v1.R`

| Computation | Lines |
|---|---|
| Link classification into period/zone | ~31–63 |
| Joint exposure construction (12 period-by-zone counts) | ~65–175 |
| Release-count suppression (threshold 20) | `.post_stage4a_release_count_v1`, line 18 |
| Contrast definitions and weights | ~209–299 |
| Model fit (glmer `nAGQ=0` / lmer REML) | ~346–431 |
| Contrast estimate, SE, Wald z p-value, CI | ~453–502 |
| BH multiplicity | `post_stage4a_adjust_multiplicity_v1`, ~528–546 |
| Protected input paths + hash gate | ~629–645 |

Confidence-interval method (answers **D10**, no refit needed): Wald z on the
link scale, `estimate ± 1.959963984540054 · SE`, where `SE` is the delta-method
standard error of the contrast vector against the fixed-effect covariance
(`vcov(fit)`); the ratio and its limits are the exponentiated link-scale values.
p-values are two-sided Wald z (`2 · pnorm(-|estimate/SE|)`). Same machinery for
both outcomes.

BH families (answers **D8** structure): `analysis_role __ outcome __ contrast`.
Each core-species (role, outcome, contrast) triple is a 49-species family; each
comparator triple is a 2-species family. Northern Shoveler's active detection
q-value was therefore adjusted within a 2-row comparator family, not the
49-species core family.

## Reproduction status

- **Frozen model outputs:** all 7 files in `output_hash_manifest_v1.csv` match
  their recorded SHA-256. No drift.
- **Manuscript assets:** re-running `scripts/build_mer_v7_event_study_assets.py`
  regenerates `tables_v7/`, `generated_v7/`, and `figures_v7/` with zero git
  drift (byte-identical).
- **Model refit:** not performed. The 100 model fits are frozen production
  outputs behind the authorization + hash gate. Refitting is out of scope for
  Phase 0 and is treated as a Phase 2 (sensitivity) action. Phase 1 diagnostics
  read the frozen inputs and existing outputs only.
- **Test suite:** `tests/testthat.R` and the fixture path are exercised by CI
  (`.github/workflows/ci.yml`, job `fixture-validation`), which passed on the
  parent commit `5ac7210`. No code under test was modified on this branch, so
  that green state carries forward. The suite was not re-run live here because
  it requires an `renv` restore; the hash and asset-rebuild checks above are the
  binding reproduction evidence.

## Diagnostic feasibility from available data

| Check | Feasible here | Notes |
|---|---|---|
| D1 calendar-date balance | **No** | day-of-year absent from frozen frame |
| D2 start-time balance | **No** | start time absent from frozen frame |
| D3 unquantified-`X` rate | Yes | `reported_states.count_type` + frame |
| D4 multi-cell occupancy, VIF | Yes | link table + reconstructed joint counts |
| D5 per-species support/prevalence | Yes | reported_states + frame, suppressed |
| D6 travelling boundary exposure | Yes | frame `protocol`, `effort_distance_km` |
| D7 taxonomy audit | Partial | annual counts yes; version from registry |
| D8 BH family audit | Yes | pure aggregate |
| D9 dabbling-duck denominator | Yes | registries |
| D10 CI method | Yes | read from code (above) |
| D11 materialise Table 2 | Yes | pure aggregate |
| D12 reconciliation | Yes | pure aggregate |
