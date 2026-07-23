# S2 — nAGQ = 1 detection sensitivity: scope and feasibility

## The concern

The primary detection models are binomial GLMMs fitted with `lme4::glmer` at
`nAGQ = 0`. That setting skips the adaptive Gauss-Hermite integration of the
random effects when optimising the fixed effects, and can bias fixed-effect
estimates in sparse binomial GLMMs. S2 asks whether refitting at `nAGQ = 1`
(Laplace) moves the panel and headline detection interactions.

## Feasibility in the frozen environment

`nAGQ = 1` (Laplace) with the primary's three crossed random intercepts
(event block, observer cluster, generalised location cluster) on all 217,200
checklists is computationally impractical here:

- A single fit did not converge within 10 minutes of wall time, **even
  warm-started** from the `nAGQ = 0` solution (theta and fixed effects passed as
  `start`). The `nAGQ = 0` fit that seeds it completes in under a minute; the
  Laplace refit is the bottleneck.
- No faster Laplace engine is available in the project library: `glmmTMB`, `TMB`,
  and `GLMMadaptive` are all absent, and installing one would change the frozen
  reproducibility environment, which is out of scope for a sensitivity.

Batching all 14 species (panel plus headline) at `nAGQ = 1` is therefore not
feasible in this environment. This is reported rather than worked around; it is
also part of why the primary uses `nAGQ = 0`.

## What was done instead

1. A single decisive probe was attempted: `scripts/sensitivity_s2_probe.R`
   refits the largest rare-gull effect, Iceland Gull (active detection 1.43), at
   `nAGQ = 1` warm-started. Outcome: the `nAGQ = 0` seed fit completed in 152 s
   and its active-detection ratio reproduced the frozen primary, but the
   warm-started `nAGQ = 1` refit did **not** complete within roughly an hour and
   was stopped. So even a single rare-gull Laplace fit is intractable in this
   environment, which is the finding. No `nAGQ = 1` estimate is available to
   report; the `nAGQ = 0` reproduction is the only completed part.

2. A mitigating fact from D5. The "rare" gulls are not actually sparse in the
   sense that most threatens `nAGQ = 0`: American Herring Gull has 1,957
   detections, Iceland Gull 4,763, Long-tailed Duck 3,070, spread across many
   random-effect levels. `nAGQ = 0` bias is most severe when the number of
   binary successes per cluster is very small; with thousands of detections the
   Laplace-versus-`nAGQ = 0` gap is expected to be modest.

## Recommendation

State in Methods that detection intervals are Wald z on the `nAGQ = 0`
covariance (D10), that the rare-species effects rest on thousands of detections
(D5), and that a full `nAGQ = 1` or `glmmTMB` Laplace refit should be run in the
revision compute environment as a confirmatory check. Do not present the single
Iceland Gull probe as a full S2; present it as one completed comparison.
