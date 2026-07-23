# SENSITIVITY index — Phase 2

Each entry is a labelled sensitivity reported alongside the primary result, never
replacing it. Engine: `scripts/sensitivity_mer_v7.R` (validated to reproduce the
frozen primary to 1e-15 before any sensitivity), plus
`scripts/sensitivity_s2_probe.R`. Nothing here writes to `outputs/` or changes a
frozen file; the primary specification is untouched.

| Check | Status | Headline | Artifact |
|---|---|---|---|
| S1 calendar + diel covariates | **Not run** | Day-of-year and start time absent from the frozen frame (D1/D2); needs a frame re-derivation, outside scope | see `diagnostics/D1_D2_date_time_balance.md` |
| S2 nAGQ = 1 detection | **Not feasible here** | Laplace with 3 crossed REs on 217k rows does not converge within an hour, even warm-started; no glmmTMB available. Rare gulls nonetheless have thousands of detections (D5), blunting the sparse-GLMM concern | `S2_nAGQ1_note.md` |
| S3 count distribution | **Done** | Spike at count 1 is heavy for Bald Eagle/Raven/Am Herring Gull (~50%) but light for the strong flock-size responders (Surf Scoter 7%, Mallard 7%); the biggest effects sit on the best-behaved counts | `S3_count_distribution.md`, `S3_count_distribution.csv` |
| S3 negative-binomial | **Not feasible here** | glmer.nb with 3 crossed REs on large positive-count subsets is intractable like nAGQ = 1 | `S3_count_distribution.md` |
| S4 single-event | **Done** | Flock-size interactions robust and often stronger on single-event checklists; detection consistent where supported. Cell non-exclusivity does not drive the findings | `S4_single_event.md`, `S4_single_event.csv` |

## Overall read

The two feasible sensitivities both support the primary. S4 shows the flock-size
result, the manuscript's main finding, is robust to the single-event restriction
and tends to strengthen. S3 shows the log-Gaussian count model is well justified
for the species that drive the flock-size conclusion, and weak only for species
whose count response is already small or null (eagle, raven), which should simply
be down-weighted.

The two infeasible sensitivities (S2 nAGQ = 1, S3 negative binomial) share one
cause: lme4 Laplace/NB GLMMs with three crossed random intercepts at this data
scale do not converge in acceptable time, and no faster Laplace engine is
installed. This is reported rather than forced, and both are recommended for the
revision compute environment (via glmmTMB) as confirmatory checks. Neither
gap touches a primary result, and the D5 support figures and the S3 distribution
table bound the concern each was meant to probe.

## Nothing looked worse in a way that changes a conclusion

Per the prime directive: no completed sensitivity made a primary result look
worse. S4 strengthened the main finding. S3 refined which count results deserve
weight without overturning any. The two infeasible refits produced no estimate to
conflict with the primary. No manuscript number requires changing on sensitivity
grounds.
