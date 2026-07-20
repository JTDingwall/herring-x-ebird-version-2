# Model catalogue

The machine-readable registry is `config/model_registry.yml`. Models are grouped by role rather than ranked by their likelihood of producing a positive result.

## Core triangulation set

1. **M10 species detection surface** — Bernoulli event-time × distance GAMM.
2. **M11 species phase × ring** — interpretable discrete event-study contrasts at 1-, 2-, 3-, 4-, and 5-km scales.
3. **M12 additive spawn kernel** — all concurrent events contribute to exposure.
4. **M20 species hurdle count** — encounter plus positive reported flock size.
5. **M23 aggregation exceedance** — tests rare large-flock pulses.
6. **M30 guild responses** — any detection, richness, total count, and aggregation.
7. **M31 hierarchical species/guild model** — guild means plus species deviations, without forced common sign.
8. **M40 calendar-matched difference-in-differences** — near spawn versus simultaneous no-recorded-active-spawn shorelines.
9. **M41 ring redistribution** — near-ring increase and outer-ring decrease.
10. **M50 intensity dose-response** — event time/distance modified by relative index and extent.

## Supporting models

- same-location event study;
- same-observer case-crossover;
- Tweedie and robust positive-count alternatives;
- GLLVM/JSDM and community composition;
- regional allocation shares;
- BACI-style recurrent-location comparison;
- distributed lags;
- latitudinal silver-wave phenology;
- observer visitation.

## Exploratory models

- dynamic occupancy on repeated-site subsets;
- N-mixture only after closure and identifiability simulation;
- cross-fitted heterogeneity discovery;
- geometry/date model averaging.

## Model reporting contract

Each model record must include:

- exact estimand and analysis population;
- response and units;
- exposure and comparison;
- event, observer, location, year, and calendar structure;
- row and cluster counts;
- effective sample size or posterior information;
- convergence/identifiability status;
- predictive validation;
- effect scale and uncertainty;
- compatibility with other model families;
- interpretation boundary;
- all prespecified sensitivity results.

No model is promoted because it is significant. No model is dropped because its sign is inconvenient.
