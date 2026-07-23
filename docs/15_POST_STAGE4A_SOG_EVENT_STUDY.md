# Post-Stage 4A Strait of Georgia event-study refinement

## Decision

This is an additive, post-results refinement. It does not overwrite, relabel, or
silently replace Stage 4A. The original model outputs remain the complete record
of the registered analysis.

The refinement addresses one specific alternative explanation: birds may appear
near recorded spawning at the same time as spring migration without responding
locally to herring. The new estimand asks whether the near-versus-reference
difference changes through the event relative to its own pre-spawn baseline.

## KISS design

The analysis retains the two response components because they answer different
ecological questions:

1. Was the species reported on a greater share of complete checklists?
2. When a finite numeric count was reported, was the reported flock larger?

It adds one model structure, fitted separately by species and response. There is
no ordination, community index, spline, zero-inflation layer, machine-learning
model, or outcome-selected temporal collapse.

| Period | Days relative to recorded onset | Purpose |
|---|---:|---|
| Baseline | -28 to -15 | Pre-event spatial difference |
| Early pre-spawn | -14 to -8 | First half of the 14-day pre period |
| Immediate pre-spawn | -7 to -1 | Tighter anticipatory/staging check |
| Spawn start | 0 to 3 | Adult aggregation and recorded deposition onset |
| Early egg | 4 to 14 | Early attached-egg availability |
| Late egg | 15 to 28 | Later egg or post-deposition availability |

Near is less than 5 km from a recorded source point. Reference is 5-20 km away.
The primary active interval is 0-14 days. Its estimate is the duration-weighted
combination of the 0-3 and 4-14 day interaction contrasts.

## Why joint exposure fields are required

The historical protected cache contains separate totals for time bins and
distance rings. Those margins cannot identify which time belongs to which
distance when a checklist links to more than one herring event. Multiplying the
margins would invent pairings.

The refinement therefore returns to the already frozen, hashed source-point link
table and counts each linked event in its actual period-by-zone cell. All links
remain additive, but each checklist remains one independent model row. The
required cardinality is:

`source links (many) -> analysis checklist token (one aggregate model row)`

The builder must verify the link count against the historical
`concurrent_links` total for every selected checklist.

## Estimand

For period \(p\), the principal contrast is:

\[
\left(\text{near}_p-\text{reference}_p\right)
-
\left(\text{near}_{baseline}-\text{reference}_{baseline}\right).
\]

On the logit scale this is a ratio of detection odds ratios. On the log-count
scale it is a ratio of conditional flock-size ratios. Exponentiated values above
one mean that the near/reference contrast became more positive than it was
during the baseline period.

This controls a Strait-wide temporal change if it affects near and reference
checklists similarly, and it subtracts persistent near/reference differences
measured during baseline. It does not establish individual movement or eliminate
time-varying local habitat, event-date error, preferential visitation, or an
unmeasured factor that changes differently between zones.

## Species

All 49 frozen named species are fitted and reported. The main ecological panel
contains the six previously emphasized taxa plus Bald Eagle, Hooded Merganser,
Mallard, American Crow, and Common Raven. This promotion changes presentation,
not denominator eligibility.

Gadwall and Northern Shoveler are fitted only as detection specificity
comparators and reported in the supplement. They are not called negative
controls, because their migration and habitat use may also covary with spawning
bays.

## Execution boundary

Production requires:

- committed versioned code and specification;
- a passing fixture/test run;
- the exact environment acknowledgement
  `POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED=through_2025_post_result_refinement_v1`;
- the frozen protected link hash and historical cache cardinalities;
- zero records from 2026 onward.

Only privacy-safe aggregate estimates, support summaries, diagnostics, and
hashes may be tracked. Manuscript results must not be changed until the complete
output family has run and passed human scientific review.

## Execution commands

From the repository root in PowerShell, after committing this implementation:

```powershell
.\scripts\run_post_stage4a_sog_event_study_v1.ps1 -Mode fixture

$env:POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED =
  "through_2025_post_result_refinement_v1"
.\scripts\run_post_stage4a_sog_event_study_v1.ps1 -Mode production

python .\scripts\build_mer_v6_event_study_assets.py
```

The production command is checkpointed by species and response. A restarted run
reuses only checkpoints with the same committed code and protected-input
signature.
