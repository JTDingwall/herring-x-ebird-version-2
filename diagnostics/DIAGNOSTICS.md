# DIAGNOSTICS index — Phase 1

Read-only computations over the frozen protected inputs and existing outputs.
No refit, no change to any frozen output, no protected row-level value released;
suppression threshold 20 applied throughout. Engine for D3-D7:
`scripts/diagnostics_mer_v7_protected.R`.

| Check | Status | Headline finding | Artifact |
|---|---|---|---|
| D1 | **Not computable** | Calendar day-of-year absent from frozen frame; "same-day" claim unverifiable | `D1_D2_date_time_balance.md` |
| D2 | **Not computable** | Checklist start time absent from frozen frame; time-of-day covariate cannot be added within the frozen boundary | `D1_D2_date_time_balance.md` |
| D3 | Done | Unquantified-X rate rises with exposure, more near than reference (Iceland Gull 10%→18% near-active); count ratios for strong aggregators are likely conservative | `D3_quantification_selection.md`, `D3_nonnumeric_selection.csv` |
| D4 | Done | 5,163 checklists (5.5% of exposed) span baseline and active via different events; max VIF 1.26 (no collinearity) | `D4_cell_nonexclusivity.md`, `D4_*.csv` |
| D5 | Done | Headline species well supported (Am Herring Gull 1,957; Iceland 4,763; Long-tailed 3,070 detections) | `D5_headline_support.md`, `D5_species_support_prevalence.csv` |
| D6 | Done | ~12% of near checklists travel >2.5 km, ~3% >4 km; boundary misclassification biases toward the null | `D6_boundary_exposure.md`, `D6_travelling_boundary_exposure.csv` |
| D7 | Done | Taxonomy is eBird v2025; the three gulls sit on 2017/2021/2024 changes, but year factor + spatial contrast difference these out of the interaction | `D7_taxonomy.md`, `D7_gull_annual_detection_counts.csv` |
| D8 | Done | **Northern Shoveler survives the 49-species core BH family at q = 0.0115**; the "four of five" claim holds under one common standard | `D8_bh_family_audit.md`, `D8_bh_families.csv` |
| D9 | Done | Five support-qualified dabbling ducks; the three core dabblers carry a weak `surface_vegetation_roe` guild, so they are not mechanism-free | `D9_dabbling_duck_denominator.md` |
| D10 | Done | Intervals are exponentiated Wald z on the link scale, both outcomes | `D10_ci_method.md` |
| D11 | Done | Table 2 materialised; 27 rows reconcile with the 3.2 family totals (13/6 detection, 19/1 count) | `D11_table2_materialised.md` |
| D12 | Done | **0 mismatches** across all structural and inline numbers; 217,200 = SoG 2005-2025 subset of the 239,934-row frame | `../RECONCILIATION.md`, `D12_frame_resolution.csv` |

## Overall read

Nothing in Phase 1 contradicts a primary result. The reconciliation is clean and
the reproduction is exact. Three findings sharpen the paper rather than weaken it:
the count ratios for strong aggregators are conservative (D3), collinearity is a
non-issue and cell overlap is modest (D4), and boundary misclassification is a
dilution bias (D6). Two findings are genuine limitations the manuscript must
acknowledge rather than repair: date and time balance are unverifiable within the
frozen frame (D1, D2), and the "same-day" language overstates what the design
matches (routed to `OPEN_QUESTIONS.md`). D8 resolves the one live statistical
worry in the manuscript's favour.
