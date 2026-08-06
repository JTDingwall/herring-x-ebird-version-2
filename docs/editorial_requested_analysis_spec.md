# Frozen post-result specification: editorial-requested analyses

Version: `editorial_requested_analysis_spec_v1`  
Status: frozen post-result exploratory refinement; not a preregistration  
Repository branch: `analysis/editorial-required-analyses`  
Base commit: `c1f1970045274df353c7874b351a58fd0df06fdb`  
Frozen source analysis: `post_stage4a_sog_event_study_v1`  
Prospective boundary: no 2026–2028 response record may be read

## 1. Scientific and historical status

The earlier registered Stage 4A analysis, its v1 specifications, locks,
execution record, outputs, and hashes remain immutable. The later Strait of
Georgia event-study was specified after Stage 4A results were known and is
already labelled a post-result, ecologically motivated refinement. The present
work was requested during editorial review after both result sets were known.
It is an archived and frozen post-result exploratory refinement. It is not
independently preregistered, confirmatory, or prospective.

New computations may read only the frozen, hash-gated 2005–2025 protected
derivatives used by the event-study. They must not modify those derivatives,
their historical checkpoints, or their released outputs. New protected
checkpoints live under
`data/derived/editorial_requested_analysis_v1/` and are never tracked.

## 2. Population, outcomes, and exposure

The population is the unchanged event-study population: eligible complete
Strait of Georgia checklists from 2005–2025, stationary or travelling, duration
5–300 minutes, travel distance at most 5 km, and one to ten observers.

The primary inferential family is the complete set of 49 support-qualified
named species in the frozen Stage 2 support registry. Previously named focal
species are illustrative only. Gadwall and Northern Shoveler remain exploratory
specificity comparators and do not form a separate confirmatory family.

Outcomes remain distinct:

1. **Checklist reporting:** one when a species was reported and zero when it
   was omitted from an eligible complete checklist under the frozen taxonomy
   and ambiguity rules. It is not occupancy, biological presence, or detection
   probability.
2. **Conditional positive numeric count:** the finite positive numeric count
   among quantified reports. It is not flock size or an unconditional abundance
   measure.
3. **Finite-count assignment among reports:** one for an exact finite numeric
   count and zero for an unquantified `X`, restricted to unambiguous reported
   records in those two states. Lower-bound, ambiguous, and structurally
   unknown records remain separate and are excluded from this binary model.

The six frozen periods are baseline (−28 to −15 d), early pre (−14 to −8 d),
immediate pre (−7 to −1 d), spawn start (0 to 3 d), early egg (4 to 14 d), and
late egg (15 to 28 d). Near is 0 to <5 km and reference is 5 to 20 km. Each
checklist remains one model row. All concurrent source-event links contribute
to their actual joint period-by-zone additive count. No marginal time and
distance totals are multiplied.

The primary model remains:

- checklist reporting: binomial-logit `lme4::glmer`, `nAGQ = 0`;
- conditional positive numeric count: Gaussian `lme4::lmer` on
  `log(numeric_count)`, REML;
- finite-count assignment: binomial-logit `lme4::glmer`, `nAGQ = 0`;
- fixed effects: all 12 joint period-by-zone counts, factor checklist year,
  protocol, log duration, log travel distance plus one, and observer count;
- random intercepts: event block, observer cluster, and generalized location.

No outcome-dependent fallback or species substitution is allowed.

## 3. Direct timing contrasts and multiplicity

For period \(p\),

\[
D_p=(\beta_{\mathrm{near},p}-\beta_{\mathrm{reference},p})-
(\beta_{\mathrm{near},baseline}-\beta_{\mathrm{reference},baseline}).
\]

The duration-weighted active contrast is

\[
D_{\mathrm{active}}=(4/15)D_{\mathrm{spawn\ start}}+
(11/15)D_{\mathrm{early\ egg}}.
\]

The primary pre-onset contrast is the duration-weighted 14-day summary

\[
D_{\mathrm{pre14}}=0.5D_{\mathrm{early\ pre}}+
0.5D_{\mathrm{immediate\ pre}}.
\]

The primary editorial contrast is

\[
A_{14}=D_{\mathrm{active}}-D_{\mathrm{pre14}}.
\]

A secondary comparison uses the already defined immediate-pre period:
\(A_7=D_{\mathrm{active}}-D_{\mathrm{immediate\ pre}}\). No new “immediate”
period is invented.

Each estimate and standard error uses the full fixed-effect covariance matrix,
including every covariance term in the compound contrast. Wald 95% intervals
and two-sided Wald z p-values are reported on the link scale; exponentiated
ratios and intervals are also reported. Benjamini–Hochberg adjustment is
applied across all finite estimates in the 49-species family separately by
outcome and contrast (`A14` and `A7`). The finite-versus-`X` models form a
separate exploratory 49-species family. Failed, unsupported, singular, null,
and contradictory rows remain visible.

Species share checklists, event blocks, observers, and locations. An
independence meta-analysis or independence-based p-value combination is
prohibited. A family-level test will be attempted only if an event-block
resampling procedure that preserves the checklist-by-species outcome vectors
can be completed with adequate convergence. Otherwise the family summary is
descriptive: median, interquartile range, sign counts, and BH counts.

## 4. Verified support and observed summaries

Privacy-safe inventory tables will report total eligible checklists, source
events, event blocks, observer clusters, generalized locations, supported
species, estimable components, failures, period-by-zone checklist and link
support, and additive-link distributions. Counts below 20 are suppressed.

Observed species summaries are nonexclusive because a checklist can contribute
to more than one period-by-zone cell through different links. For each species
and supported cell, the denominator is the number of eligible checklists with
at least one link in that cell; the numerator is the number reporting the
species. Reported occurrences are partitioned into exact finite numeric,
unquantified `X`, lower-bound, and other retained states. Positive exact finite
counts receive median and interquartile range. These are labelled observed and
unadjusted.

Every join must declare and test its cardinality:

- event metadata to aggregated joint-link counts: one-to-zero-or-one after a
  one-to-many link join is reduced to one checklist row;
- event metadata to one species state: one-to-zero-or-one;
- event metadata to one species ambiguity mask: one-to-zero-or-one;
- species registry to results: many result rows to one registry row.

## 5. Adjusted absolute predictions

Predictions use population-level fixed effects; all random intercepts are set
to zero. They apply to eligible 2005–2025 Strait of Georgia checklists under
the frozen adjustment set, not to a random bird or an unobserved coastline.

Two prediction configurations are fixed:

1. **Standardized one-additional-link:** compare otherwise identical rows with
   the selected period-by-zone count changed from 0 to 1. All other link counts
   are zero. Year is 2020 (the middle observed year), protocol is stationary,
   duration is 60 minutes, travel distance is 0 km, and observer count is 1.
2. **Observed-covariate standardization:** for each eligible checklist, set all
   link counts to zero and then set the selected count to 0 or 1, retain its
   observed year, protocol, duration, travel distance, and observer count, make
   population-level predictions, and average over the full eligible checklist
   distribution.

Joint fixed-effect covariance simulation with a deterministic seed and at
least 2,000 valid draws supplies 95% intervals. Checklist-reporting predictions
are probabilities. Reporting contrasts are percentage-point
baseline-adjusted near/reference differences. For the log-count model,
`exp(eta)` is explicitly the conditional median/geometric mean on the fitted
log scale; the requested arithmetic conditional mean is
`exp(eta + sigma^2/2)`. Only the latter is labelled a model expectation or
conditional mean. Count ratios cancel the common residual-variance factor.

## 6. Validation species and engines

Selection uses only the already released primary active results and is frozen
before validation:

| Outcome | Positive | Negative/contradictory | Null |
|---|---|---|---|
| Checklist reporting | Iceland Gull | Ring-billed Gull | Brandt’s Cormorant |
| Conditional positive numeric count | Glaucous-winged Gull | Ring-billed Gull | American Crow |

The positive species is the completed positive core-species estimate with the
smallest released BH q-value; the negative species is the analogous completed
negative estimate; the null species has the completed estimate closest to zero
among intervals spanning zero, with common name as a deterministic tie-break.
Species will not be replaced after validation results are seen.

For checklist reporting, a warm-started `nAGQ = 1` refit and an equivalent
`glmmTMB` binomial model will be attempted where technically available. A prior
verified Iceland Gull probe did not complete in about one hour and `glmmTMB`
is not installed in the frozen library; these are feasibility warnings, not
results. One documented package-install attempt is permitted for this new
exploratory package. If unavailable or if a representative fit exceeds the
predeclared 30-minute wall-time budget, that engine/species is recorded
infeasible without substitution.

For conditional counts, the primary log-Gaussian model is compared with a
zero-truncated negative-binomial model where a mixed-effects implementation is
available. A fixed-effect-only truncated model is not considered equivalent
and may be reported only as a diagnostic. Reporting and truncated counts may be
described jointly as a hurdle-type sensitivity, not as one likelihood.

All primary models will release convergence classification, singularity,
rank-deficiency, random-effect variances, residual variance where applicable,
and available gradient information.

## 7. Exposure and observation-process sensitivities

Thresholds and transformations are outcome-blind:

1. `binary_any_link`: each of the 12 counts becomes 0/1.
2. `nearest_event`: among links in the six-period window, retain the minimum
   distance link; break exact ties by source-event token solely inside the
   protected computation. Checklists without a window link remain all-zero.
3. `cap_8`: cap each joint count at 8. Eight is the pooled 95th percentile of
   positive checklist-by-period-by-zone counts in the frozen link inventory.
4. `single_event`: retain checklists with exactly one concurrent source link.
5. `stationary_only`: retain stationary checklists.
6. `high_precision_2km`: retain stationary checklists and travelling
   checklists at most 2 km, using the existing frozen flag.
7. `observer_four_cell`: retain observer clusters represented in near,
   reference, pre (−14 to −1), and active (0 to 14) cells.
8. `block_four_cell_20`: retain event blocks with at least 20 checklists in
   each of near, reference, pre, and active support.

For each feasible sensitivity, the outcome, adjustment set, random-effects
structure, periods, zones, and `A14` contrast remain unchanged. Complete
49-species results are preferred. If computation is limiting, the order above
controls execution and partial family coverage is explicit.

The 2-km rule is a checklist-footprint sensitivity, not an alternative
near/reference radius. No alternative event-study near/reference radius is
already frozen in the repository; none will be invented after outcomes are
known. Taxonomic checks use the existing v2025 crosswalk and annual support
audit; no outcome-dependent remapping is permitted.

Linearity is assessed with link-frequency tables, outcome support at each count,
and the binary and capped encodings. No smooth is fit where the multiple-link
tail is too sparse, and no plot extrapolates beyond observed support.

## 8. Placebo, event-block uncertainty, and influence

A shifted-onset placebo must keep locations, eligibility, zones, adjustment,
and model structure fixed. A shift is admissible only if the placebo active and
baseline windows are inside the frozen link window, do not overlap the real
active window, and can be defended against contamination by known spawning
activity from concurrent linked events. If those conditions cannot be met, the
placebo is recorded infeasible rather than forced.

Event-block support and influence potential are summarized without releasing
block tokens. For representative models, leave-one-event-block-out refits are
attempted in descending checklist-support order, retaining requested,
attempted, completed, and failed counts. A bootstrap interval is released only
if at least 999 prespecified block resamples are requested and at least 90% fit
success is achieved; otherwise convergence counts and failure reasons are
reported without a nominal interval. Cross-species family resampling must use
the same sampled blocks for every species.

## 9. Privacy, QA, and stopping rules

No tracked output may contain checklist, observer, event, block, locality, or
coordinate identifiers; protected file paths; source comments; or record-level
rows. Block and observer support is released only as totals, distributions, or
nonidentifying ranks after suppression. All tracked result tables retain nulls,
failures, and singular fits.

Hash gates must match the frozen event-study inputs, the event table must contain
exactly 239,934 through-2025 records before the SoG restriction, the SoG
population must contain 217,200 records, and no year after 2025 may be present.
Every covariance-based contrast is independently reconstructed from the saved
fixed-effect vector and covariance matrix. Repository tests and privacy scans
must pass before handoff. Hard stops and warnings follow
`docs/04_DECISION_RULES.md`.

## 10. Execution order and status semantics

Execution follows the editorial priority order: inventory; direct contrasts;
observed and adjusted magnitudes; finite-versus-`X`; representative engine
validation; exposure sensitivities; support restrictions; linearity,
influence/bootstrap, radius/taxonomy checks, and placebo.

Status values are `existing`, `completed`, `partial`, `infeasible`, `failed`,
or `blocked`. A status table records exact input/model, estimand, sample and
event support, output, QA, caveat, and potential manuscript consequence.
Incomplete work is preserved as resumable protected checkpoints and is never
silently omitted.
