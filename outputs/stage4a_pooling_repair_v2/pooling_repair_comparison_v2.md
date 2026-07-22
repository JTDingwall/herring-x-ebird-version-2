# Stage 4A aggregate pooling repair v2 comparison

- Authoritative invalid v1 scope: 6,562 finite rows in 112 historical families.
- Compatible v2 families: 162.
- Estimable v2 families: 162.
- Non-estimable v2 families: 0.
- Primary-representation rows with v2 posterior estimates: 6085.
- Noncompleted model rows retained as explicit NA: 38 (`NON_ESTIMABLE_MODEL_STATUS`).
- Duplicate M11/M12 representations excluded: 439.
- Duplicate exclusion reason: `EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION`.
- All unaffected individual estimates, standard errors, intervals, p-values, n, status, multiplicity families, and BH q-values match v1 exactly as serialized fields.
- Protected inputs used: no. The repair consumed tracked aggregate inputs and frozen metadata only.
- Interpretation: pooled and individual results remain checklist-conditional associations, not causal effects, population abundance, biomass, occupancy, or movement.
