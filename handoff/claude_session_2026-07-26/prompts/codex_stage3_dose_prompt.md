# Stage 3: does the response scale with recorded spawn size?

For GPT-5.6 (sol High) in VS Code. Supersedes Section 4 Stage 3 of
`codex_staged_refit_prompt.md`, which was written before Stages 1 and 2 ran.

---

## 1. What changed since that document was written

**Stage 2 is now the primary specification**, not Stage 1. Build on the Stage 2
model, which carries `minutes_from_sunrise` and two annual harmonics for day of
year. Current tallies are **20 count increases and 13 reporting increases**.

**Species negative controls are withdrawn.** American Robin and Chestnut-backed
Chickadee are not controls and are not to be reported as controls or as a
displacement estimate. Retain their historical outputs unchanged; do not fit
them again and do not include them in Stage 3 reporting.

**The negative controls are the three effort outcomes**: log duration, log
distance travelled, and number of observers. In Stage 2 only duration moved, by
1.07%, nominally significant and not surviving BH across the three.

**The Gadwall and Northern Shoveler comparators are removed from the
manuscript.** They do not appear in Stage 3.

---

## 2. The dose variable

Event-level aggregated relative spawn index.

`relative_spawn_index_t` is the **sum of `surface_index_t`,
`macrocystis_index_t` and `understory_index_t`**, with unrecorded components
treated as zero. This is confirmed by the author and it differs from the current
data dictionary line, which reads "missing is not zero" for each component.
Amend that line in the same commit to read:

> missing indicates the component was not recorded; treated as zero when summing
> to the event total, and the count of such records is reported

Aggregate to `herring_event_id` (Year + LocationCode + Section + SpawnNumber).
An event may carry several survey rows. **Sum across rows within an event.**
This is the author's instruction and it is not a choice to be revisited: do not
compute, report or offer a maximum-based alternative.

Report before fitting anything:

- Distribution of the aggregated index per event: median, IQR, min, max
- Events where no component was recorded, and therefore cannot be scored. Drop
  them, report the count, and do not treat them as zero spawn
- How many events carry more than one survey row
- Cross-tabulation of survey method against the aggregated index

Use `log(index)`. The distribution is heavily right-skewed and the biological
expectation is diminishing returns.

---

## 3. How the dose enters

Keep the twelve period-by-zone link-count terms from Stage 2. Add twelve dose
terms, so the model nests inside Stage 2 and a likelihood ratio test is
available.

For checklist *i*, period *p*, zone *z*:

```
n[i,p,z] = number of eligible links                        (unchanged)
s[i,p,z] = sum over those links of (log index - mean log index)
```

Centre the log index on its grand mean over all eligible links and report the
constant. The dose estimand is formed exactly as the existing one:

```
dose_did_active_minus_pre = contrast(s, active 0-14) - contrast(s, pre 14)
```

duration-weighted 4/15 and 11/15, exponentiated. **Report the likelihood ratio
test against Stage 2 for every species and outcome.** That single number is the
honest headline: does spawn size improve the fit at all?

---

## 4. The confound that decides this

**Site recurrence.** Large spawns recur at the same places, and if those places
are good bird habitat then a dose response is a site effect. A location random
intercept does not fix this, because it absorbs level and the dose effect is a
slope.

Decompose the dose within and between locations:

```
log_index_between = mean of log index over all events at that location
log_index_within  = log index - log_index_between
```

Enter both. **`log_index_within` is the primary result** and must be declared as
such before fitting. It is the same location in a big year against a small year,
which cannot be explained by that location being good habitat.

If within and between disagree, that is the most informative outcome available
and it leads the report.

**Survey method.** Carry `survey_method` as a covariate. Run a sensitivity
restricted to **dive-observed records**, which are 950 of the 1,120 analysis
events (84.8%) and the consistent-majority set. If the dose effect survives that
restriction, the measurement objection is answered.

*Corrected 27 July after the descriptive summaries.* An earlier version of this
document specified a surface-only restriction, on the basis that surface
dominates the all-BC source at 24,042 rows against 6,631 dive. That inverts in
the Strait of Georgia analysis set, which is 84.8% dive and only 6.1% surface,
68 events. A surface-only sensitivity is not estimable here and should be
reported as such rather than interpreted.

**Events with no recorded component.** 125 of the 1,120 analysis events had no
component recorded and appear in the descriptive output with an aggregated index
of 0.00. That zero is an absence of measurement, not an absence of spawn. Drop
those events before taking logs; do not enter them as zero and do not let them
reach `log(index)`.

**Extent against intensity.** Report the correlation between `log(index)` and
`log(length_m * width_m)`, and run a sensitivity holding `log(length_m)`
constant. If the dose effect vanishes, the finding is about how far a spawn
stretches rather than how much fish it holds, and the manuscript must say so.

---

## 5. Also run

**Dose placebo.** Repeat the Stage 2 placebo at ±90 days with the dose terms
included. Report BH-positive tallies against the real values. Stage 2 returned
zero at +90 for both outcomes; the dose model should do the same.

**Effort negative control outcomes with dose.** Refit log duration, log
distance and observer count as responses with the dose terms present. A dose
response in checklist duration would mean observers spend longer at larger
spawns, which is an observation effect rather than an ecological one, and it
would bear directly on the interpretation.

**Guild-level dose.** Regress species-level dose estimates on the seven fixed
feeding groups, weighted by precision, using the exact covariance. An earlier
version of the guild timing test set covariances to zero and gave p = 0.089
where the correct answer was 0.020. Do not repeat that.

**Tercile figure.** Glaucous-winged Gull and Bald Eagle. Split events into
within-year terciles of the aggregated index, so the strong year trend in stock
size does not drive the split, and refit the Stage 2 twelve-term model within
each tercile. Plot the three active-minus-pre estimates with intervals for both
outcomes. Monotonicity is the visual claim.

---

## 6. Falsification criteria, written before fitting

Put these in `metadata/post_stage4a_stage3_dose_spec_v1.yml` and commit it
alone, before any model runs.

- **Supported**: the within-location dose contrast is positive and survives BH
  for a meaningful number of species, the likelihood ratio test is significant,
  it holds under the surface-only restriction, and the effort outcomes show no
  dose response.
- **Not supported**: the likelihood ratio test is not significant, or the effect
  is carried entirely by the between-location term, or it disappears with
  `log(length_m)` held constant.
- **Uninterpretable**: checklist duration shows a dose response, or the effect
  reverses between the full and surface-only fits.

A null is a real answer. Section 2.2 of the manuscript currently states that the
index value does not enter the models, and that position is defensible and can
simply stand.

---

## 7. Multiplicity

Benjamini-Hochberg within the fixed 49-species family, per outcome, unchanged.
The dose contrast is a **new key**, not an addition to the existing family:
`dose_did_active_minus_pre`. Do not pool it with the Stage 2 contrast.

---

## 8. Outputs

```
outputs/post_stage4a_stage3_dose_v1/
  index_aggregation_audit.csv      section 2 diagnostics
  dose_estimates_49x2.csv          estimate, SE, CI, p, BH q, n, fit status
  dose_within_between.csv          both terms per species
  dose_lrt.csv                     likelihood ratio test against Stage 2
  dose_method_sensitivity.csv      surface-only refit
  dose_extent_sensitivity.csv      log length held constant
  dose_effort_outcomes.csv         the three negative control outcomes
  dose_placebo_tallies.csv         +/- 90 days
  dose_guild_meta.csv              exact covariance
  dose_terciles_case_species.csv
  figures/                         tercile panel, vector PDF plus 600 dpi PNG
  execution_record_v1.yml
```

Plus `STAGE3_DOSE_REPORT.md` at the repository root:

1. **Verdict in the first three sentences**, against Section 6. Do not build to it.
2. The likelihood ratio result.
3. Within against between, and what it implies.
4. Method and extent sensitivities.
5. Effort outcomes with dose present.
6. Placebo tallies.
7. Species table and the guild result.
8. Everything that failed, retained not dropped.
9. What the author should not claim.

---

## 9. Standing constraints

Authorization verified in the shell and never set by you. No 2026 to 2028
records. No record-level release. Parent and Stage 1 and 2 outputs unchanged.
The 49-species family is fixed and species that fail to converge are reported as
failures. Stage it: the two case species first, then the full 49, then the
sensitivities. Branch, commit, push, open a pull request, do not merge.
