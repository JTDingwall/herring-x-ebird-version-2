# Stage 4A core response results

Status: `PASS_PENDING_HUMAN_STAGE4A_RESULTS_REVIEW`

Scientific interpretation remains pending human review. These results describe
checklist reporting and conditional reported counts, not abundance, occupancy,
biomass, or causation.

## Scope and completion

- The factorized primary frames contain 217,200 eligible SoG events from 2005
  onward and 8,584 eligible WCVI events from 2015 onward. The descriptive frames
  contain 861 CC events and 9,007 NA events from the complete 1988-2025 window.
- The pipeline fit 49 frozen core taxa and eight registered guilds in all four
  regions, plus the two-taxon frozen specificity panel in SoG and WCVI, without
  expanding the full event-by-taxon grid.
- Eight activated registry models completed, four completed with visible component
  failures, 32 remained deferred, and M31 remained prospective-locked.
- Among 460 underlying model-region-unit checkpoints, 441 completed, three had
  failed geometry, 13 had insufficient support, and three failed numerically.
  Twenty-eight underlying fits had rank-deficiency warnings. The released M11/M12
  component geometry expands this to 916 visible rows without treating components
  as independent evidence. Of 214 zero-truncated NB2 sensitivities, 210 completed
  and converged and four CC fits had failed geometry.

## Core associations

Counts below include every completed active-near contrast; adjusted counts use
BH correction within the registered families.

| Model and component | Region | Completed | Positive | 95% CI excludes 0 | BH q < 0.05 |
|---|---:|---:|---:|---:|---:|
| M01 guild detection | SoG | 8 | 6 | 8 | 8 |
| M01 guild detection | WCVI | 8 | 5 | 3 | 3 |
| M01 guild detection | CC | 8 | 7 | 6 | 6 |
| M01 guild detection | NA | 8 | 3 | 5 | 4 |
| M01 guild positive count | SoG | 8 | 7 | 7 | 7 |
| M01 guild positive count | WCVI | 8 | 7 | 6 | 6 |
| M01 guild positive count | CC | 7 | 4 | 2 | 2 |
| M01 guild positive count | NA | 8 | 2 | 1 | 1 |
| M02 species detection | SoG | 49 | 36 | 34 | 34 |
| M02 species detection | WCVI | 49 | 42 | 35 | 32 |
| M02 species detection | CC | 45 | 39 | 21 | 17 |
| M02 species detection | NA | 49 | 29 | 26 | 24 |
| M02 species positive count | SoG | 49 | 34 | 28 | 24 |
| M02 species positive count | WCVI | 48 | 38 | 21 | 17 |
| M02 species positive count | CC | 38 | 22 | 6 | 1 |
| M02 species positive count | NA | 47 | 24 | 14 | 2 |
| M29 specificity detection | SoG | 2 | 2 | 2 | 2 |
| M29 specificity detection | WCVI | 2 | 1 | 0 | 0 |

The non-null SoG specificity panel is a prominent warning: both Gadwall and
Northern Shoveler have BH-adjusted active-near associations. It shows that the
design can capture shared seasonal, spatial, or observation-process structure
and prevents a species-specific ecological reading of the core associations.

## Validation and robustness

- All four deterministic event-blocked folds are present. Predictions use fixed
  effects only and no conditional observer or location BLUPs. Rows whose fixed
  year or protocol level was absent from training are excluded transparently;
  561 small validation cells are privacy-suppressed and the remaining 4,735 rows
  have finite metrics. CC and NA metrics are descriptive only.
- Across fold medians, SoG detection log loss ranges from 0.513 to 0.536 for M01
  guilds and 0.147 to 0.164 for M02 species. WCVI ranges from 0.612 to 0.893 for
  M01 and 0.403 to 0.484 for M02. Positive-count RMSE on the log scale ranges
  from 1.359 to 1.402 (SoG M01), 1.169 to 1.296 (SoG M02), 1.545 to 1.866
  (WCVI M01), and 1.366 to 1.504 (WCVI M02).
- All 32 WCVI observer-disjoint guild-fold metrics are finite; median fold log
  loss ranges from 0.501 to 0.643. This view is observer-composition robustness
  only and makes no new-event generalization claim. The frozen WCVI dominant-
  observer share is 35.6%, with effective observer replication of 7.4.
- All eight dominant-observer holdouts completed. Guild-effect signs agree with
  the primary WCVI analysis in six of eight holdouts. The <=2 km focused
  sensitivity also agrees in sign for six of eight guilds.
- The exact zero-truncated NB2 sensitivity agrees in sign with the hurdle-
  lognormal positive-count component for 90 of 113 primary/candidate-primary
  comparisons, 23 of 41 comparable CC fits, and 36 of 55 comparable NA fits.
  These disagreements require component-level review rather than selective
  reporting.

## Diagnostics and limits

Thirty-one of 32 registered false-date and false-location placebo diagnostics
are not nominally below 0.05; one WCVI false-location diagnostic is. The M32
count-state and M40 observer-richness diagnostics are non-null in both regions,
which confirms observation-process structure. These diagnostics are not
biological effects.

No 2026-or-later record, comment field, shoreline field, or unregistered
response field was read. Count, X, deterministic zero, lower-bound, and
ambiguity states remain distinct. The 45-model registry was not changed.

## Review gate

The complete privacy-safe tables and self-contained technical report are in
`outputs/stage4a_results/`. Human scientific review must assess the SoG
specificity warning, WCVI observer and 2 km discordance, positive-count family
sensitivity, fold stability, and the visible geometry/support warnings.

Stage 4B and the 2026-2028 prospective confirmation period remain unauthorized
and locked.
