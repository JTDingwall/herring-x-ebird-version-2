# Reproducibility record: editorial-requested analyses

Status: post-result exploratory refinement requested during editorial review;
not a preregistration.

## Repository history

- Analysis branch: `analysis/editorial-required-analyses`
- Execution used an isolated worktree outside the manuscript-editing worktree;
  its machine-local path is intentionally not retained in the release record.
- Exact base commit: `c1f1970045274df353c7874b351a58fd0df06fdb`
- Frozen specification commit: `a0c4ef5`
- Primary implementation commits: `f040bac`, `6bcf1c3`, `7098d82`
- Finite-versus-`X` source-label correction: `066f4a6`
- Optimizer-warning classification correction: `e38f060`
- Absolute-prediction uniqueness correction: `ebae90e`
- Sensitivity framework: `6a91018`
- Link-count diagnostics: `f561815`
- Reporting/dictionary framework: `99f0e95`, `0c3fbd6`
- Checkpoint-backed QA: `fb9b589`, `19026dc`
- Representative `glmmTMB` validation runner: `476b8b0`

The manuscript-editing worktree and branch were not switched, reset, rebased,
stashed, merged, or modified. Historical Stage 4A specifications, locks,
checkpoints, outputs, and hashes were not modified.

## Protected-input gates

Only the four frozen through-2025 derivatives below were read. The analysis
drivers require these exact SHA-256 hashes before materializing a response:

| Input role | SHA-256 |
|---|---|
| Event metadata | `03eaccdd46b5cba779f596e7ce96dacd5a509f51f6eae4c5c79daf706879a9b2` |
| Source-point links | `f26197d0a71fd177e77774ec9e5596563c127ec8eb0f948042aff51ad805567b` |
| Reported species states | `0f02ac6bdbb561a8e4df58cc8d53340ec29f9519b85a99f4748cb8367fc33cb5` |
| Ambiguity masks | `c0e063f8a8c6ccfb97535183d8e669a9f4bb1eaea31bae144dffa3d81d57d3ff` |

Every execution record reports zero 2026+ records read. The event gate requires
exactly 239,934 through-2025 data rows before selecting the 217,200-checklist
Strait of Georgia population. Protected checkpoints are under
`data/derived/editorial_requested_analysis_v1/` and are ignored by Git.

## Execution environment

R was invoked with `--vanilla`,
`RENV_CONFIG_AUTOLOADER_ENABLED=FALSE`, and the archived project library
`renv/library/windows/R-4.5/x86_64-w64-mingw32`. The exact session and relevant
package versions are written to
`outputs/editorial_requested_analysis_v1/session_info.txt`.

The frozen specification permitted one isolated `glmmTMB` installation attempt.
`glmmTMB` 1.1.14 installed successfully. Its initial startup check found the
project library's TMB 1.9.19 rather than the binary's TMB 1.9.21 build
dependency; TMB 1.9.21 was therefore installed into the same ignored
validation library before any project fit. A no-project-data binomial smoke
test returned a positive-definite Hessian. The isolated library is:

`data/derived/editorial_requested_analysis_v1/glmmtmb_library`

## Exact analysis commands

All commands used the acknowledgement
`EDITORIAL_REQUESTED_ANALYSIS_AUTHORIZED=through_2025_editorial_post_result_v1`,
the frozen protected root, four workers where applicable, and the library
above.

```text
Rscript --vanilla scripts/run_editorial_requested_analysis_v1.R
Rscript --vanilla scripts/run_editorial_finite_x_correction_v1.R
Rscript --vanilla scripts/run_editorial_sensitivities_v1.R
Rscript --vanilla scripts/run_editorial_linearity_diagnostics_v1.R
Rscript --vanilla scripts/run_editorial_engine_validation_component_v1.R
Rscript --vanilla scripts/run_editorial_reporting_v1.R
Rscript --vanilla scripts/run_editorial_dictionary_v1.R
Rscript --vanilla scripts/run_editorial_qa_v1.R
```

Sensitivity components were selected with
`EDITORIAL_SENSITIVITY_IDS=<comma-separated frozen IDs>`. Engine-validation
components were selected with the frozen species/outcome pair in
`EDITORIAL_VALIDATION_SPECIES` and `EDITORIAL_VALIDATION_OUTCOME`. Each
representative engine fit had a 30-minute external wall-time budget.

## Corrections and resumability

The first completed core run revealed that the protected sparse table stores
unquantified reports as `count_type = "X"`, whereas an internal Stage 4A
materializer can synthesize `unquantified_X`. The initial editorial code
recognized only the latter. No primary reporting or conditional-count model
was affected. Commit `066f4a6` made the two-label semantic mapping explicit,
continued to exclude lower-bound and ambiguity-affected records, and added a
finite-`X`-only correction driver. All 49 affected checkpoints were replaced
without refitting the primary models.

During QA, `read.csv(nrows = 0)` was found to mean “no row limit,” which caused
correction refreshes to append exact copies of the already verified absolute
prediction rows. Commit `ebae90e` constructs a zero-row schema explicitly and
enforces a unique
taxon-by-outcome-by-configuration-by-quantity key. Only byte-identical
duplicates were collapsed, restoring the original 2,256 model predictions;
no estimate or interval changed.

Core, finite-`X`, sensitivity, and engine-validation fits write one ignored
checkpoint per species/outcome component. Interrupted work is therefore
resumable without re-reading a response for completed components.

## QA and privacy

The final numerical QA script checks:

- expected row counts and unique table keys;
- `ratio = exp(estimate)` and exponentiated confidence bounds;
- p- and q-value ranges;
- the full-covariance flag on every compound contrast;
- exact agreement of saved tables with protected checkpoint objects, within
  an explicit `1e-8` absolute CSV-serialization tolerance;
- exact agreement of all 2,256 absolute predictions with their checkpoints;
- zero holdout reads and no historical-output mutation;
- absence of prohibited identifier/coordinate columns.

The full repository test suite, the repository privacy scan, figure rendering,
dictionary missing-field gate, output hash manifest, and Git status checks are
recorded in the final handoff. Complete fit and failure counts are in
`completion_failure_log.csv`; requested-analysis dispositions are in
`analysis_status.csv`; per-execution YAML records retain component completion,
package versions, hashes, and holdout/privacy gates.
