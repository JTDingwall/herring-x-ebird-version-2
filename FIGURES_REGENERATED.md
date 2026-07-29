# Stage 2 figures regenerated

## Outcome

Figures 1-5, S1, and S2 were regenerated from Stage 2 aggregate results as
vector PDF and 600-dpi PNG. The unnumbered study-area map remains an explicit
author placeholder. No protected model was fitted or rerun, no record-level
derivative was opened, and no block-aware bootstrap was started.

Figure 2 passed the required hard gate:

| Outcome | Positive BH survivors | Required |
|---|---:|---:|
| Checklist reporting | 13 | 13 |
| Reported number | 20 | 20 |

The Stage 2 reporting table also contains two adjusted decreases (Bufflehead
and Common Raven, both ratio 0.929). They remain open under the prompt's
positive-survivor convention; this is stated in the figure caption rather than
silently treating them as non-significant.

## Scripts run

The final complete run was:

```powershell
$env:MER_R_LIBRARY = "<project-renv-library>"
Rscript --vanilla figures_ggplot2/99_run_all.R "<figure-branch-root>" "<source-root>"
```

`99_run_all.R` ran, in order:

1. `00_prepare_stage2_inputs.R`
2. `01_map_study_area.R`
3. `02_study_design.R`
4. `03_family_forest.R`
5. `04_period_profiles.R`
6. `05_supp_pretrend_and_tables.R`
7. `06_distance_band_profiles.R`

For a clean checkout that has the committed aggregate CSVs but not the local
protected checkpoint summaries, use:

```powershell
Rscript --vanilla figures_ggplot2/99_run_all.R "." "." "skip-prepare"
```

The period-profile input was computed by linear contrasts against the saved
Stage 2 fixed-effect vectors and covariance matrices. This was post-processing,
not refitting. Its rebuilt active-minus-pre estimates and intervals matched the
frozen Stage 2 primary table with maximum absolute difference
`5.107026e-15`. The taxon-registry join was declared and tested 1:1.

## Repairs made on first execution

The prompt stated that `figures_ggplot2/` existed at commit `1186d8e`.
It does not occur in that tree, any reachable branch, the reflog, or the
repository's unreachable blobs. `REFEREE_READS_REPORT.md` independently records
the same absence for `05_supp_pretrend_and_tables.R`.

The missing scripts were therefore reconstructed from:

- the frozen Stage 2 aggregate tables and saved coefficient/covariance summaries;
- the figure roles and captions in the handoff manuscript;
- the colour palette and `theme_mer` grammar in the tracked
  `scripts/build_mer_figures_ggplot2_v2.R`.

Execution repairs were limited to figure code:

- corrected a `data.table` logical-row selection exposed on the first pass;
- wrapped Figure 2's caption after visual QA found right-edge clipping;
- replaced Figure S2's continuous raster colour bar with stepped vector
  rectangles after the PDF binary audit found one embedded image object;
- retained the study-area map as an unmistakable author placeholder without
  locality or coordinate data.

The final run had no script, cardinality, export, or visual-layout failure.
The only console warnings were that the local `data.table` and `ggplot2`
packages were built under R 4.5.3 while the available interpreter was R 4.5.1.

## Inputs and accounting

| Committed aggregate input | Rows | Accounting |
|---|---:|---|
| `figures_out/tableS_primary_contrast_49x2_stage2.csv` | 98 | 49 species x 2 outcomes |
| `figures_out/tableS_period_profiles_49x2_stage2.csv` | 686 | 49 species x 2 outcomes x 7 contrasts |
| `figures_out/tableS_distance_bands_3species_stage2.csv` | 468 | 3 species x 2 outcomes x 13 bands x 6 periods |
| `figures_out/tableS_pretrend_summary_stage2.csv` | 4 | 2 outcomes x 2 pre-onset windows |

Source SHA-256:

- `estimates_49x2.csv`:
  `5D9A396B8FFBB2EB80F4857561C68A2740154C22BF9E913563872BECD733AB01`
- `distance_bands_3species.csv`:
  `EFEAC6C9264B646E4DC80C3A024CD242F3F1C526C7546C57423FA382E6765998`

The Stage 2 period-profile family has 49 estimable reporting models and 46
estimable count models. Figure S1 shows one Stage 2 BH pretrend survivor:
Glaucous Gull checklist reporting in days -7 to -1, ratio 0.356
(95% CI 0.201-0.630, q = 0.019). The other three outcome-window families have
zero BH survivors.

Figure 5 contains exactly 13 bands per species-outcome-period. American Robin
is labelled `comparison_species` throughout and is never described as a
negative control.

## Outputs

Each stem below exists as `.pdf` and `.png` in `figures_out/`:

- `Figure_1_study_design_stage2`
- `Figure_2_family_forest_stage2`
- `Figure_3_period_profiles_stage2`
- `Figure_4_count_period_distribution_stage2`
- `Figure_5_distance_band_profiles_stage2`
- `Figure_S1_pretrend_stage2`
- `Figure_S2_count_profiles_stage2`
- `Study_area_map_author_placeholder`

All eight PNGs are tagged 600 x 600 dpi. All eight PDFs have a valid PDF 1.7
header and EOF marker, contain four font objects, and contain zero image
objects. Thus the delivered PDF artwork is vector rather than a raster image
inside a PDF wrapper. Every final PNG was visually inspected for clipping,
overlap, legibility, and panel alignment.
