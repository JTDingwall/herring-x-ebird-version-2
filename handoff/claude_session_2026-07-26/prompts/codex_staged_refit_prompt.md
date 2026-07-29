# Staged refit: anchor, detectability, dose

For GPT-5.6 (sol High) in VS Code, working in `herring-x-ebird-version-2`.
Supersedes `codex_spawn_dose_prompt.md`, which is now Stage 3 of this document.

Read the whole file before writing code. The staging in Section 4 is the point
of the commission: three changes are pending and each one requires refitting the
same 98 models, so they run as one job, but they run **in sequence and
separately**, because a combined run cannot tell you which change moved what.

---

## 1. Why this exists

Three problems were identified against the current manuscript (v42). All three
require the same refit.

**The event anchor is wrong.** Day 0 is currently the midpoint between the first
and last dates spawn was recorded at a location. That has no biological
referent. The question the paper asks is when food first becomes reachable, so
the anchor should be the first recorded spawn date. This is not a change of mind
after seeing results: `metadata/data_dictionary_v2.csv` already declares
`start_date` the "Preferred event timing anchor" and `end_date` a "fallback
anchor". The frozen spec departed from that.

The current anchor is also not one definition. `EndDate` is missing in 7,303 of
31,167 source rows against 438 for `StartDate`, so roughly a quarter of events
are anchored on a single available date and the rest on a midpoint.

**Two standard detectability covariates are missing.** Time of day and day of
year are not in the fitted models. Both fields exist: the data dictionary
defines `start_time` as "Converted to minutes from sunrise when valid" and
`observation_date` as calendar time, and the project's own
`R/model_helpers.R::core_detection_formula` includes `minutes_from_sunrise` and
`s(calendar_day, bs = 'cc', k = 12)`. They were not carried into the frozen
spec. As it stands the paper cannot answer an eBird reviewer on detectability.

**Spawn size is unused.** Section 2.2 states the index value never enters the
models. The author wants that tested.

---

## 2. Authorization and standing constraints

**The author authorized this run on 27 July 2026.** The scientific decision is
recorded in `metadata/post_stage4a_staged_refit_authorization_v1.yml`, which
also records what is and is not permitted. Read it before Section 4; it is
broader than the previous authorization, because refitting existing species is
prohibited there and is the substance of this commission.

**The environment acknowledgement is still set by the author, in his own
shell, not by you.** Verify it and stop if it is absent:

```powershell
$env:POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED
# must return: through_2025_post_result_refinement_v1
```

Do not set it, do not write it into a script, a dotfile, a CI config or a
committed environment file, and do not work around a failed check. If it is
unset, say so and stop. The variable is an acknowledgement by a person, and its
only value is that a person typed it.

Run the fixture pass before production, as
`docs/15_POST_STAGE4A_SOG_EVENT_STUDY.md` requires.

- Do not access, analyse or summarise protected 2026 to 2028 confirmation records.
- **Do not modify or overwrite `outputs/post_stage4a_sog_event_study_v1/`.** That
  is the published run behind every number in the manuscript and it must stay
  byte-identical so the current draft remains verifiable. All new output goes to
  new directories.
- The 49-species family is fixed. Species that fail to fit are reported as
  failures, never dropped.
- Do not invent, estimate or back-calculate any number.
- No spline, quadratic or capped alternative to the per-link exposure. That
  remains out of scope and is described in the manuscript as unmodelled.

---

## 3. Pre-registration, before any model runs

Write `metadata/post_stage4a_staged_refit_spec_v1.yml` and **commit it before
fitting anything**, so the falsification criteria exist in git history before
the results do.

```yaml
analysis_status: post_result_ecologically_motivated_refinement
motivation: >-
  author review 27 July 2026; anchor correction aligns the analysis with the
  data dictionary's declared preferred anchor; detectability covariates close a
  known eBird best-practice gap; dose tests comment 105
created_after_stage4a_results_available: true
parent_run: outputs/post_stage4a_sog_event_study_v1
stages:
  s1_anchor: day0 = first recorded spawn date, else end_date where absent
  s2_detectability: s1 + minutes_from_sunrise + annual harmonics
  s3_dose: s2 + log relative spawn index, within/between decomposed
family: fixed 49 species, two outcomes, unchanged
multiplicity: benjamini_hochberg within the 49-species family, per outcome
falsification: <write the Section 8 criteria here, before fitting>
```

---

## 4. The three stages

Each stage changes **one thing** relative to the stage before it. Every stage is
compared to its immediate predecessor and to the published parent run. Do not
combine them and do not reorder them.

### Stage 1: anchor only

Day 0 becomes the **first date on which spawn was recorded at that location**.
Where `StartDate` is absent, fall back to `EndDate`; report how many records
that affects.

Nothing else changes. Same six periods and boundaries (baseline −28 to −15,
early pre-spawn −14 to −8, immediate pre-spawn −7 to −1, spawn 0 to 3, early egg
4 to 14, late egg 15 to 28), same 5 km and 5 to 20 km zones, same twelve
period-by-zone link counts, same covariates, same three random intercepts, same
`nAGQ = 0` binomial and REML Gaussian engines, same Wald intervals from the full
fixed-effect covariance matrix, same contrasts and weights (4/15 and 11/15).

**Report the mechanical consequences before reporting any result:**

- Distribution of the anchor shift, `floor(span/2)` days, over all events. Most
  should be zero: the parent audit gives 466 of 1,144 events with spawn recorded
  on a single day and a median span of one day, both of which floor to a
  zero-day shift.
- How many events shift by 0, 1, 2, 3+ days.
- How many checklist-to-event links change period, broken down by period. Spawn
  start is the narrowest window at four days and will absorb proportionally the
  most movement; that window carries the gulls-and-scavengers-at-onset result.
- Whether any event or block drops out of the analysable set.

Then report the results, species by species, directly against the published
numbers: 18 count increases and 13 reporting increases surviving correction.

### Stage 2: detectability covariates

Add to the Stage 1 model:

- **`minutes_from_sunrise`**, derived from `start_time` and the checklist
  coordinate. Report how many checklists have a valid `start_time` and state
  your missingness rule before fitting. If coverage is poor, say so and treat
  Stage 2 as conditional on the subset, with Stage 1 remaining primary.
- **Day of year as annual harmonics**, not a spline. The frozen engines are
  `lme4::glmer` and `lmer`, not `mgcv`, so `s(calendar_day, bs = 'cc')` cannot be
  ported. Use `sin(2*pi*doy/365) + cos(2*pi*doy/365)` and the second harmonic
  `sin(4*pi*doy/365) + cos(4*pi*doy/365)`. Four terms. Do not add more without
  saying why.

Optional, only if it is cheap: `log1p_prior_observer_checklists` as an observer
experience covariate. The observer random intercept already absorbs mean skill,
so this is a refinement rather than a gap. Skip it if it costs a sweep.

**The point of this stage is falsification, not improvement.** If the results
hold with time of day and season adjusted, an entire class of reviewer objection
closes. If they move, that is the single most important thing this commission
can find and it must lead the report.

### Stage 3: dose

Add the spawn index to the Stage 2 model. Keep the twelve link-count terms and
add twelve dose terms, so the model nests and a likelihood ratio test is
available.

For checklist *i*, period *p*, zone *z*:

```
n[i,p,z] = number of eligible links                          (unchanged)
s[i,p,z] = sum over those links of (log index - mean log index)
```

Centre on the grand mean over all eligible links and report the constant. The
dose estimand is formed exactly as the existing one, on the `s` terms:

```
dose_did_active_minus_pre = contrast(s, active 0-14) - contrast(s, pre 14)
```

duration-weighted and exponentiated. It reads as the multiplicative change in
the near-versus-reference active-minus-pre response per one-unit increase in log
recorded spawn index.

**Three confounds decide this stage. Handle all three.**

*Survey method.* The index is a sum of observed components and which components
exist depends on method: Surface is present in 23,279 rows, Understory 6,318,
Macrocystis 1,497. A surface-only survey and a dive survey at the same true
spawn score differently. Carry `Method` as a covariate, run a sensitivity
restricted to surface-observed records, and report the association between
method and log index directly.

*Site recurrence.* Large spawns recur at the same places, and if those places
are good bird habitat then a dose response is a site effect. A location random
intercept does not fix this because it absorbs level, not slope. Decompose:

```
log_index_between = mean of log index over all events at that location
log_index_within  = log index - log_index_between
```

Enter both. **`log_index_within` is the primary dose result** and must be
declared as such in the spec. If within and between disagree, that is the most
informative outcome available and it leads the report.

*Extent versus intensity.* Report the correlation between `log(relative_spawn_index_t)`
and `log(Length * Width)`, and run a sensitivity with `log(Length)` held
constant. If the dose effect vanishes, the finding is about how far a spawn
stretches and not how much fish it holds.

Records with no component observed cannot be scored. Drop them, report how many
links and events that removes, and do not treat them as zero.

### Negative controls, every stage

American Robin (*Turdus migratorius*) and Chestnut-backed Chickadee (*Poecile
rufescens*). Fit them at every stage. Neither has a route to a herring spawn, so
a response in either means the design is picking up observer, site or seasonal
structure. If a control responds and survives correction at any stage, say so in
the first paragraph of the report.

Known complication, so you are not surprised: American Robin is not perfectly
flat in the distance-band work. Its reporting is elevated at 0 to 2 km during
immediate pre-spawn (BH q = 0.039). Pre-spawn elevation is not a dose response.

### Also refit at every stage

The 13-band distance analysis for Bald Eagle, Glaucous-winged Gull and American
Robin uses the same anchor and must move with it.

---

## 5. Figures, clean and regenerated

`figures_ggplot2/` holds `00_theme_mer.R` and five scripts. **They have never
been executed.** They were written against the column names in
`effect_estimates_v1.csv` and `model_diagnostics_v1.csv` at commit `1186d8e`, so
treat the first run as a syntax and schema pass and expect breakage.

Regenerate every figure from the final accepted stage, not from the parent run:

| Script | Figure |
|---|---|
| `01_map_study_area.R` | Study area. Currently an author placeholder in the manuscript |
| `02_study_design.R` | Figure 1, design schematic |
| `03_family_forest.R` | Figure 2, 49 species by two outcomes |
| `04_period_profiles.R` | Figures 3 and 4, period profiles |
| `05_supp_pretrend_and_tables.R` | Figures S1 and S2 |

Plus a new panel for the manuscript's **Figure 5**, currently a grey
placeholder: event-time profiles at 2 km resolution for the three case species
across the 13 distance bands, reporting and count ratios against the same-band
baseline.

**Vector PDF is required.** This is the manuscript's one outright compliance
failure against Elsevier's raster threshold. Output PDF plus a 600 dpi PNG to
`figures_out/`. Do not upscale a raster and call it fixed.

Every figure must be reproducible from a committed script and a committed input
CSV. No hand editing.

---

## 6. Falsification criteria, written before fitting

Put these in the spec file. Adjust if you have a better argument, but write them
down first.

- **Anchor change is safe**: the 18 and 13 counts hold, no species changes
  direction, and the guild timing test keeps its sign and significance.
- **Anchor change matters**: counts move by more than two species in either
  outcome, or a headline species changes direction. Either way it is reported
  and the manuscript is rewritten around the new numbers.
- **Detectability is answered**: results hold with time of day and season in.
- **Detectability is a problem**: any headline result loses significance. This
  outranks everything else in the report.
- **Dose supported**: the within-location dose contrast is positive, survives
  BH for a meaningful number of species, holds under the surface-only
  restriction, and neither control shows a dose response.
- **Dose not supported**: the likelihood ratio test is not significant, or the
  effect is carried entirely by the between-location term, or it disappears with
  `log(Length)` held constant.

A null at any stage is a real answer. The manuscript's current position is
defensible and can stand.

---

## 7. Runtime and failure

The parent analysis was expensive: no single species fit completed within an
hour on four parallel workers under Laplace, which is why `nAGQ = 0` is used.
You are running three full sweeps of 49 species by two outcomes, plus the
distance bands, plus sensitivities.

Stage it inside each stage:

1. The three case species and the two negative controls first. If the machinery
   is wrong you find out in minutes.
2. Then the full 49.
3. Then the sensitivities.

Expect singular fits and convergence failures. The parent run had a singular fit
in Western Gull counts and 30 in the count-state exploratory set. Report every
one. Do not drop a species that fails to converge, and do not switch optimiser
or tolerance to force a fit without recording that you did.

**If something cannot be done as specified, stop and write down why.** A
previous commission in this project returned a wrong answer by computing one
item on the wrong contrast, caught only because the resulting table was
arithmetically impossible. An explicit "this cannot be done as specified, here
is what I would need" is worth more than a plausible number.

---

## 8. Outputs

New directories, parent run untouched:

```
outputs/post_stage4a_staged_refit_v1/
  s1_anchor/
    anchor_shift_audit.csv          events by shift in days
    link_period_migration.csv       links changing period, by period
    estimates_49x2.csv              estimate, SE, CI, p, BH q, n, fit status
    delta_vs_parent.csv             per species and outcome, side by side
    guild_timing.csv
    distance_bands_3species.csv
  s2_detectability/
    coverage_start_time.csv         valid start_time, and the missingness rule
    estimates_49x2.csv
    delta_vs_s1.csv
    guild_timing.csv
    distance_bands_3species.csv
  s3_dose/
    dose_estimates_49x2.csv
    dose_within_between.csv
    dose_lrt.csv
    dose_method_sensitivity.csv     surface-only refit
    dose_extent_sensitivity.csv     log(Length) held constant
    dose_terciles_case_species.csv
    dose_guild_meta.csv
  negative_controls_all_stages.csv
  execution_record_v1.yml           seeds, versions, timings, every failure
figures_out/                        vector PDF and 600 dpi PNG, all figures
```

---

## 9. Git

Work on a new branch off the current head:

```
git checkout -b codex/staged-refit-anchor-detectability-dose
```

Commit in the order the work happens, so the history shows the pre-registration
landing before the results:

1. the spec file, alone
2. Stage 1 outputs
3. Stage 2 outputs
4. Stage 3 outputs
5. figures
6. the review document

Push to `origin`
(`https://github.com/JTDingwall/herring-x-ebird-version-2.git`) and open a pull
request against the current branch. Do not merge it.

Do not force-push, do not rewrite history, and do not touch
`outputs/post_stage4a_sog_event_study_v1/`.

---

## 10. The review document

Write `STAGED_REFIT_REVIEW.md` at the repository root. It is read by Claude,
who maintains the manuscript, and its job is to make the manuscript updatable
without anyone guessing. Structure it exactly like this.

**1. Verdict, first three sentences.** For each stage: did the headline result
hold? Give the new counts against 18 and 13. Do not build to it.

**2. What must change in the manuscript, as a list.** Every sentence in v42 that
is now wrong, quoted, with its replacement number. Claude cannot see your
console. If Section 3.2 says "18 species were counted in larger numbers" and the
answer is now 17, say so explicitly with the species that dropped out.

**3. The anchor audit.** Shift distribution, links migrating between periods,
and whether the spawn-start window moved more than the others.

**4. Stage-by-stage deltas.** One table per stage: species, outcome, old
estimate, new estimate, old q, new q, changed direction yes or no.

**5. Detectability.** Coverage of `start_time`, what the harmonics did, and
whether anything moved. If nothing moved, say that plainly; it is a strong result
and belongs in Section 4.4.

**6. Dose.** Within versus between, the likelihood ratio test, both confound
sensitivities, and what the author should not claim.

**7. Negative controls at every stage.**

**8. Everything that failed.** Singular fits, non-convergence, dropped records,
any deviation from this document.

**9. Numbers for the manuscript**, as a machine-readable block: every species
and interval that appears in the v42 body text, with its new value, so the
existing interval check can be re-pointed at the new tables. The check extracts
`X.XX (Y.YY–Z.ZZ)` triples from the body and matches them against
`figures_out/tableS_primary_contrast_49x2.csv`; that file must be regenerated
with the same column names or the check will fail silently.

**10. Your own recommendation.** If you think the anchor change is wrong, or the
dose analysis should not be reported, say so and give the reason.
