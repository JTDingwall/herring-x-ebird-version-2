# Post-Stage 4A SoG event-study scientific review (v6)

**Decision: PASS WITH QUALIFICATIONS for manuscript revision.**

This decision authorizes an additive Strait of Georgia-only manuscript version.
It does not relabel the refinement as prespecified or confirmatory, and it does
not supersede or modify any frozen Stage 4A result.

## Integrity, scope, and privacy

- The production record uses committed code
  `6bfef2c5b828ca392255d5b3365a2f84b8a2f9f2`.
- All four protected-input hashes and all seven released-output hashes passed.
- The selected population contains 217,200 eligible SoG checklists from
  2005-2025; zero 2026+ records were read.
- The source-link hash and concurrent-link pairing gates passed. One checklist
  remained one model row while all linked recorded source events were counted
  in their true period-by-zone cells.
- The repository privacy scan passed across 610 text files with zero detected
  violations. It emitted the previously observed invalid-UTF-8 read warnings
  while traversing non-UTF-8 artifacts; the warnings did not create a detected
  identifier, coordinate, credential, or path violation.
- Frozen Stage 4A outputs, gates, specifications, and manuscript versions have
  no tracked changes.

## Numerical and support review

- The complete family contains 100 species-response fits and 1,400 registered
  contrast rows, with no duplicate species-outcome or
  species-outcome-contrast keys.
- Model statuses were 95 `completed`, one
  `completed_with_singular_warning`, three `failed_insufficient_support`, and
  one `failed_numerical_fit_no_fallback`.
- The nonordinary components were:
  - Surfbird conditional positive count: insufficient joint-cell support;
  - Rhinoceros Auklet conditional positive count: insufficient joint-cell
    support;
  - Glaucous Gull detection: numerical failure with no fallback;
  - Glaucous Gull conditional positive count: insufficient joint-cell support;
  - Western Gull conditional positive count: completed with a singular warning.
- The numerical reason for the Glaucous Gull detection failure was not retained
  beyond the registered generic failure code. No fallback or result-selected
  reparameterization was attempted.
- All 22 main-panel models completed without singularity, rank deficiency, or
  convergence failure. The smallest released main-panel joint-cell support was
  259 exposed model rows.
- Global joint exposure support ranged from 2,992 near-zone checklists at spawn
  start to 28,655 reference-zone checklists in the late-egg period. Near-zone
  early- and immediate-pre periods occurred in fewer than 20 checklist years,
  so their year counts were privacy-suppressed; checklist and event-block
  support remained well above the release threshold.
- Recalculated exponentiated estimates and confidence limits matched all 1,344
  finite released rows. No written numeric value was `NaN` or infinite.
- Recalculated Benjamini-Hochberg q-values matched all 42 registered
  role-outcome-contrast families (maximum absolute difference
  \(1.78\times10^{-15}\)).

## Primary ecological result

The 0-14 day duration-weighted interaction is the primary post-result
refinement. It is the change in the near/reference contrast relative to the
-28 to -15 day baseline.

- Among estimable core species, 13 of 48 detection interactions were
  BH-positive and six were BH-negative.
- Among estimable conditional-count models, 19 of 46 interactions were
  BH-positive and one was BH-negative.
- The 14-day pre-spawn interaction contained no BH-positive detection result
  and one BH-positive conditional-count result. At spawn start, 10 detection
  and 13 conditional-count interactions were BH-positive; in the early-egg
  period, 12 and 21 were BH-positive. The concentration after recorded onset,
  rather than during the pre-spawn summary, is migration-adjusted timing
  evidence for a subset of species. It is not a universal community response.

The established main taxa show a coherent response primarily in flock size:
Surf Scoter conditional count ratio 1.25 (95% CI 1.16-1.34,
BH q \(=5.37\times10^{-9}\)); White-winged Scoter 1.31 (1.17-1.46,
\(q=3.52\times10^{-6}\)); Harlequin Duck 1.22 (1.17-1.28,
\(q=3.48\times10^{-16}\)); Common Merganser detection 1.19 (1.12-1.26,
\(q=1.13\times10^{-7}\)) and count 1.11 (1.07-1.15,
\(q=4.96\times10^{-7}\)); Glaucous-winged Gull detection 1.12 (1.06-1.18,
\(q=0.00059\)) and count 1.21 (1.18-1.25,
\(q=2.01\times10^{-36}\)); and Short-billed Gull detection 1.22 (1.14-1.30,
\(q=1.13\times10^{-7}\)) and count 1.36 (1.29-1.44,
\(q=1.36\times10^{-25}\)).

## Five promoted species

- **Bald Eagle:** baseline near/reference ratios were near one. At spawn start,
  detection increased to a ratio-of-ratios of 1.21 (1.13-1.30,
  \(q=2.30\times10^{-6}\)) and conditional count to 1.18 (1.15-1.20,
  \(q=1.27\times10^{-41}\)). The primary 0-14 day ratios were 1.08
  (1.03-1.13, \(q=0.0033\)) and 1.07 (1.05-1.08,
  \(q=1.57\times10^{-13}\)).
- **Hooded Merganser:** detection was already higher near source events during
  baseline (1.11, 1.05-1.17, \(q=0.0012\)), but no post-baseline interaction
  was supported. Primary detection was 0.97 (0.90-1.04, \(q=0.581\)) and
  count was 1.01 (0.97-1.05, \(q=0.731\)).
- **Mallard:** detection was not supported in any primary period. Conditional
  count increased at spawn start (1.09, 1.04-1.14, \(q=0.00074\)), early egg
  (1.12, 1.08-1.16, \(q=1.07\times10^{-10}\)), and late egg (1.15,
  1.11-1.18, \(q=4.00\times10^{-16}\)); the primary 0-14 day count ratio was
  1.11 (1.08-1.14, \(q=3.69\times10^{-11}\)).
- **American Crow:** both response components had positive baseline
  near/reference differences, but the pre-spawn, onset, egg-period, and
  primary interactions were null after baseline adjustment. Primary detection
  was 1.01 (0.96-1.06, \(q=0.810\)) and count was 1.00 (0.98-1.03,
  \(q=0.815\)).
- **Common Raven:** the baseline detection difference was near one. Primary
  detection became negative (0.94, 0.90-0.98, \(q=0.026\)), driven by a
  negative early-egg estimate that narrowly missed BH significance on its own.
  Conditional count remained near null (1.01, 1.00-1.03, \(q=0.215\)).

These taxa should be promoted as explicitly tested ecological candidates, not
as uniformly positive responders.

## Specificity and residual confounding

- Gadwall had a negative baseline near/reference difference (0.88, 0.80-0.97,
  \(q=0.024\)) but a null 0-14 day interaction (1.03, 0.90-1.17,
  \(q=0.704\)).
- Northern Shoveler had a null baseline difference but a positive early-egg
  interaction (1.25, 1.07-1.46, \(q=0.011\)), late-egg interaction (1.27,
  1.10-1.46, \(q=0.0025\)), and primary 0-14 day interaction (1.24,
  1.08-1.43, \(q=0.0056\)).

Northern Shoveler therefore demonstrates residual structure shared with a taxon
without a strong assumed direct herring mechanism. The interaction design
removes a common seasonal shift and persistent baseline zone differences, but
it does not eliminate time-varying habitat, access, checklist submission,
preferential visitation, event-date error, or indirect ecological responses.
Gadwall does not reproduce the active interaction.

## Interpretation decision

The evidence is **supported with qualifications** for a Strait of Georgia-only
ecology manuscript. The stronger evidence is the zone-by-period interaction,
especially for conditional flock size and the concentration of positive
results after recorded onset. It is not causal evidence of individual movement,
absolute abundance, occupancy, or biomass. The manuscript must:

1. lead with the 0-14 day interaction while retaining detection and conditional
   finite positive count as distinct outcomes;
2. show null, negative, failed, and singular components;
3. call the analysis a post-result, ecologically motivated refinement;
4. place Gadwall and Northern Shoveler in supplemental specificity results and
   disclose the Northern Shoveler contradiction prominently;
5. retain historical registered Stage 4A results as immutable supplementary
   context; and
6. state that prospective confirmation is still required.
