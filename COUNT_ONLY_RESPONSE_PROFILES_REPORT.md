# Count-only response profiles across spawn timing

## Result

Across the 46 species with an estimable reported-number model, conditional
reported numbers were essentially flat in the early pre-spawn period, increased
through the immediate pre-spawn and spawn-start periods, peaked during early egg
availability, and remained positive but lower during late egg availability.
The equal-species geometric mean reported-number ratios relative to the days
−28 to −15 baseline were 1.00, 1.03, 1.06, 1.11, and 1.07 across the five
successive, non-overlapping periods.

This is a descriptive analysis of archived, adjusted species-level model
contrasts for **positive numeric count given detection**. It is not an analysis
of total bird abundance, raw checklist counts, community composition, or
day-to-day totals. No response model was rerun and no holdout data were read.

## Period summary

Each species has equal weight in this summary. The standard error below
describes variation in the species-level effects divided by the square root of
46; it is not a pooled model-based standard error.

| Period relative to spawn onset | Species | Mean link-scale effect | Geometric mean ratio | Median ratio | Positive |
|---|---:|---:|---:|---:|---:|
| Early pre, days −14 to −8 | 46 | −0.003 | 0.997 | 1.008 | 24/46 (52.2%) |
| Immediate pre, days −7 to −1 | 46 | 0.027 | 1.028 | 1.021 | 31/46 (67.4%) |
| Spawn start, days 0 to 3 | 46 | 0.056 | 1.057 | 1.043 | 32/46 (69.6%) |
| Early egg, days 4 to 14 | 46 | 0.107 | 1.113 | 1.090 | 39/46 (84.8%) |
| Late egg, days 15 to 28 | 46 | 0.066 | 1.068 | 1.047 | 38/46 (82.6%) |
| Active days 0 to 14 composite | 46 | 0.094 | 1.098 | 1.092 | 39/46 (84.8%) |

The active-days value is the prespecified duration-weighted combination
`(4/15) × spawn start + (11/15) × early egg`. It is shown separately in the
distribution figures and was not treated as a sixth independent period in the
heatmaps, PCA, or NMDS.

## Species profiles

The raw heatmap shows substantial heterogeneity around the overall timing
pattern. Among the largest positive disjoint-period estimates were Long-tailed
Duck in early egg (ratio 1.61), Bonaparte's Gull in immediate pre-spawn (1.55)
and early egg (1.53), Iceland Gull in early egg (1.41), Greater Scaup in late
egg (1.39), White-winged Scoter in early egg (1.39), and Short-billed Gull in
early egg (1.37). Conversely, some profiles were negative in one or more
periods, including Western Grebe and Ring-billed Gull. These contrasts describe
relative reported flock size conditional on a numeric detection; they should
not be read as changes in unconditional abundance.

The row-centred heatmap removes each species' five-period mean and therefore
emphasizes timing shape rather than overall response magnitude. The Ward.D2
ordering is only a display aid: no clusters were cut, selected, or tested.

## PCA and NMDS

The ordinations used the five disjoint period estimates after standardizing
each period across species. Guild assignments were joined only after the
ordinations were fixed and are used solely as plotting symbols.

- PCA axis 1 explains 62.8% of standardized profile variation and has similar
  positive loadings for all five periods, so it primarily represents overall
  response magnitude.
- PCA axis 2 explains 14.7% and contrasts early pre-spawn with late egg timing.
  Together, the first two axes explain 77.5%.
- The two-dimensional Euclidean NMDS has stress 0.094. The Spearman correlation
  between original standardized Euclidean distances and two-dimensional NMDS
  distances is 0.974, indicating a faithful descriptive map.

The PCA and NMDS separate several strong or unusual profiles, but they do not
support a claim that the species form discrete response types. The existing
pre-assigned guilds overlap substantially in both ordinations.

## Figures

- [Raw five-period effect heatmap](outputs/count_only_response_profiles_v1/count_effect_heatmap_raw.png)
- [Within-species timing-shape heatmap](outputs/count_only_response_profiles_v1/count_effect_heatmap_timing_shape.png)
- [Link-scale period distributions](outputs/count_only_response_profiles_v1/count_period_distribution_link.png)
- [Reported-number ratio distributions](outputs/count_only_response_profiles_v1/count_period_distribution_ratio.png)
- [PCA of standardized profiles](outputs/count_only_response_profiles_v1/count_profile_pca.png)
- [NMDS of standardized profiles](outputs/count_only_response_profiles_v1/count_profile_nmds.png)

## Scope and validation

The analysis read only the frozen aggregate effect table
`outputs/post_stage4a_sog_event_study_v1/effect_estimates_v1.csv` and the
unaltered guild assignments in `metadata/canonical_species_registry.csv`.
The declared effect-table key, `analysis_taxon_id + contrast`, was unique before
reshaping. The species-to-guild join was many-to-one and retained all 46
complete count-model species. Glaucous Gull, Rhinoceros Auklet, and Surfbird
were excluded because their reported-number models were not estimable; no
complete species was dropped. The join audit is archived with the results.

The source table contains period-versus-baseline contrasts, so a genuine
day-by-day total-count plot cannot be reconstructed from it. Producing such a
figure would require a separately authorized, de-identified daily aggregate
that preserves sampling-effort and repeated-checklist structure. No attempt was
made to approximate raw daily totals from the archived coefficients.

All calculations, tables, diagnostics, figure mappings, package availability,
session information, and an execution record are in
[`outputs/count_only_response_profiles_v1/`](outputs/count_only_response_profiles_v1/).
The reproducible entry point is
[`scripts/run_count_only_response_profiles_v1.R`](scripts/run_count_only_response_profiles_v1.R).
These results are exploratory and estimand-refining.
