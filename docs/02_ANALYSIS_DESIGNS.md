# Analysis designs

## Design A — Continuous event-time × distance response

**Grain:** one eligible checklist × species, or one checklist × guild.

**Exposure:** event day and distance to relevant spawn. Two alternatives are compared:

1. nearest-event exposure;
2. additive exposure across every concurrent event:

\[
E_{it}(\lambda,\tau)=\sum_j w_j\exp(-d_{ij}/\lambda)K(t-t_j;\tau),
\]

where `w_j` is 1 or a transformed relative-index/extent weight, `d_ij` is distance, `lambda` is a prespecified spatial scale, and `K` is a temporal availability kernel.

**Models:** binomial GAMM for detection, hurdle count model, guild richness/count model.

**Advantage:** avoids committing to one radius and handles overlapping events without duplicating a checklist as if independent.

**Primary risks:** calendar/event-time confounding, point-location error, preferential visitation. Address with calendar smooth/fixed effects, event/year/location structure, geometry sensitivities, and observer models.

## Design B — Discrete phase × non-overlapping distance rings

**Rings:** 0–0.5, 0.5–1, 1–2, 2–3, 3–4, 4–5, 5–10, and 10–20 km.

**Time bins:** early pre, pre, immediate pre, spawn start, early egg, late egg, post 1, post 2.

This directly answers the requested 2-, 3-, and 4-km question without comparing nested cumulative samples that contain many of the same checklists. Cumulative 1/2/3/4/5/10-km buffers remain sensitivities.

## Design C — Same-location event study

Repeated exact coordinates are generalized to privacy-safe analysis-location IDs or shoreline units. Location fixed effects absorb persistent habitat/access differences. Event-day coefficients compare each location with itself through time.

This design is especially useful at well-sampled hotspots but is not representative of unsampled shoreline. It should be paired with the wider checklist model.

## Design D — Same-observer case-crossover

Observers with both event-exposed and comparable non-exposed or pre-event checklists are compared with themselves. Observer fixed effects remove stable skill and reporting tendencies; prior experience and effort remain covariates.

This is a strong sensitivity to preferential observer composition, although observers may deliberately change behavior during spawn.

## Design E — Reported-count hurdle and aggregation models

The two-part hurdle model separates:

1. encounter/non-encounter;
2. positive reported flock size.

Candidate positive-count families are truncated negative binomial, lognormal, and Student-t on `log1p(count)`. Tweedie and zero-inflated negative-binomial models are unconditional alternatives. Model choice is based on simulation, predictive checks, and residual structure—not the sign or p-value of the herring term.

A separate exceedance model tests whether counts cross species-specific 90th, 95th, or 99th percentile thresholds estimated from prespecified baseline data. This targets the rare aggregation response documented in field studies.

`X` remains a detection with an unknown numeric count. It is excluded from the positive numeric component, with an interval-censored exploratory model only if defensible. Lower-bound mixed records remain flagged.

## Design F — Functional guild and community models

Each guild receives four transparent outcomes:

- any member detected;
- number of members detected;
- summed numeric reported count;
- maximum or any upper-tail aggregation event.

Summed counts are accompanied by a dominance diagnostic: estimates are repeated after removing the numerically dominant species. Guild models do not erase species models.

Community analyses include:

- GLLVM/JSDM with multiple latent factors;
- blocked Jaccard and Bray-Curtis ordination;
- PERMANOVA/dbRDA with permutations blocked by event/date/location;
- richness and Hill diversity mixed models.

The hierarchical species model uses species-specific event, observer, location, year, and nuisance effects. Guild membership predicts species herring slopes, but no single rank-one shared context is allowed to force pairwise species correlation to +1, which was a structural defect in the failed Version 1 multispecies model.

## Design G — Calendar-matched difference-in-differences

For each event and calendar date, compare spawn-associated shorelines with eligible shorelines having no recorded active event within the contamination radius. The key coefficient is:

\[
(\text{near active}-\text{near baseline})-
(\text{comparison active date}-\text{comparison baseline date}).
\]

This is not proof of spawn presence versus true absence because the herring dataset lacks a negative survey-effort surface. It is a recorded-event versus no-recorded-active-event estimand.

Instead of stopping whenever one year-period cell is thin, Version 2 uses partial pooling and reports event/year effective support. Hard exclusions are limited to empty support, deterministic separation, or severe extrapolation.

## Design H — Ring redistribution and regional allocation

### H1. Ring difference-in-changes

Estimate changes in prespecified near (0–5 km), intermediate (5–10 km), and outer (10–20 km) bands on the same calendar dates. Redistribution is supported when near-ring changes are positive and outer-ring changes are smaller or negative, while regional totals remain visible.

### H2. Conditional allocation

Within an event-date region, condition on total reported detections or counts and model the share allocated to each ring using multinomial or beta-binomial mixed models. Include offsets or standardization for checklist number, duration, protocol, and observer composition.

This design removes regional spring-wide changes common to all rings, but it remains conditional on observed eBird sampling.

## Design I — Same-location BACI-style comparison across years

For recurrent herring locations, compare years with a recorded local spawn against years without one, before versus during regional spawn timing. Location fixed effects absorb stable habitat. Region-year terms absorb broad herring and migration conditions.

The key limitation is that no record is not confirmed absence. Restricting to recurrently surveyed locations and years with regional survey coverage can make the comparison more credible, but the claim remains associative.

## Design J — Herring intensity, extent, and method

Potential predictors:

- log1p observed total relative index;
- Surface, Macrocystis, and Understory components on comparable subsets;
- component availability pattern;
- log length, log width, log length×width;
- relative index per extent proxy;
- survey method;
- number of concurrent events and additive exposure.

Intensity enters as a modifier of event-time/distance response. Nonlinear saturation and threshold models are allowed with low-rank smooths and observed-support prediction limits.

## Design K — Timing and geometry uncertainty

Rebuild exposure under start date, valid midpoint, and full interval. Use egg-availability kernels lasting 7, 14, 21, 28, or 42 days. Rebuild geometry under source point, shoreline-projected point, location shoreline unit, and length-informed uncertainty kernel.

Results are summarized as an uncertainty envelope rather than choosing the representation with the largest positive effect.

## Design L — Latitudinal “silver wave”

Model whether species/guild peaks track the northward progression of spawn using event latitude, calendar date, and event-relative time. This analysis is especially relevant to scoters and migration-stage species. It requires careful separation of ordinary spring migration from spawn tracking using event-year and calendar-matched controls.

## Design M — Observer visitation

Model where observers submit checklists within the observed shoreline choice set, separately from bird outcomes. Candidate designs are observer-day conditional logit and event-date multinomial allocation.

The visitation model is a bias diagnostic. It is not automatically converted into inverse-probability weights because unobserved zero-submission shoreline-days and out-of-pool alternatives are missing.

## Design N — Occupancy and N-mixture subsets

Occupancy and N-mixture models require repeat sampling and closure assumptions that the full checklist dataset does not automatically satisfy. They are restricted to site-period subsets with explicit repeat visits, stable exposure, and simulation-based identifiability checks. Negative-binomial N-mixture is not a default because it can be unstable and ecologically unrealistic.

## Design O — Placebos and prospective confirmation

Every core analysis includes:

- event dates shifted ±14, ±28, and ±56 days where valid;
- spatially shifted or permuted event locations preserving coastal structure;
- falsification taxa analyzed separately;
- leave-event, leave-year, leave-section, and spatial-block validation;
- observer-composition diagnostics;
- a future frozen test using 2026+ events/checklists or an independent region.

Because the 2015–2025 outcomes influenced Version 2's motivation, current reanalyses are exploratory/estimand-refining. A new model is not confirmatory merely because it has not been fitted before.
