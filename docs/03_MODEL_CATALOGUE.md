# Model catalogue

The authoritative implementations are in `metadata/model_registry.csv`; ecological quantities are defined separately in `metadata/estimand_registry.csv` and workflow mappings in `metadata/analysis_module_registry.csv`.

The registry contains 45 prespecified models:

- core detection, positive-count, zero-inclusive count, guild-bound, richness, timing, distance, additive-exposure, allocation, intensity, and phenology models;
- supporting matched-observer, fixed-place, mass-balance, hierarchical, ordination, lagged, co-occurrence, and regional-synthesis models;
- diagnostic visitation, count-reporting, awareness, placebo, and missingness models;
- exploratory synthetic-control, network, behaviour, and dynamic-use substudies.

Every model maps to one approved estimand and one analysis module. All are currently `registered_not_fitted`. No implementation may be chosen or dropped based on the sign of a Version 2 result, and all prespecified results will be reported.

## Co-occurrence boundary

The multispecies design uses multiple validated latent factors or another validated covariance architecture and requires a hash-identical pilot before a full fit. Residual association is not evidence of direct interaction, facilitation, or shared travel. Contemporaneous other-bird count is not an ordinary primary-model covariate.

## Current gate

This setup task stops at metadata and outcome-blind design readiness. Model fitting requires later human approval after the hard stops and warnings in `docs/04_DECISION_RULES.md` are reviewed.
