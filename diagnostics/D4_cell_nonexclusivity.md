# D4 — Multi-cell occupancy and predictor collinearity

Computed from the link table restricted to the 217,200 modeled checklists;
93,342 have at least one link inside a modeled period and zone. Artifacts:
`D4_occupancy_distribution.csv`, `D4_baseline_active_cooccupancy.csv`,
`D4_predictor_correlation.csv`, `D4_predictor_vif.csv`.

## Occupancy

Of the 93,342 checklists with modeled exposure, 55,855 (60%) occupy exactly one
of the 12 period-by-zone cells; the rest occupy 2 to 7 cells (8-cell occupancy
was under 20 and suppressed). Multi-cell occupancy via concurrent events is
common but usually shallow.

## Baseline and active are not mutually exclusive

- Checklists in at least one baseline cell: 30,542
- Checklists in at least one active cell: 33,800
- **Checklists in a baseline cell and an active cell via different events: 5,163**
  (5.5% of exposed checklists, 2.4% of the 217,200 modeled rows)

The difference-in-differences subtracts a baseline that, for these 5,163
checklists, is carried by the same row that also carries active exposure. The
overlap is modest but nonzero, and Methods 2.3 states the additive structure
without giving this number. Routed to Phase 3 item 12.

## Collinearity is negligible

Correlations among the 12 additive count predictors are low, and every variance
inflation factor is between 1.22 and 1.26 (max 1.26). The additive joint counts
are close to orthogonal, so the interaction estimates are not degraded by
collinearity among exposure terms. This is reassuring and can be stated in one
sentence.
